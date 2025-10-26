// lib/User/features/teams/data/firebase_teams_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities.dart';
import '../domain/repos/teams_repo.dart';
class FirebaseTeamsRepo implements TeamsRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _teams => _db.collection('teams');

  // Add this helper near the top of the class:
  String _displayNameFromId(String userId) {
    return userId.contains('@') ? userId.split('@').first : userId;
    // If in the future userId is a UID (no @), we just show it as-is or you can map UID->email.
  }
  Team _toTeam(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Team(
      id: d.id,
      name: (m['name'] ?? '') as String,
      ownerUid: (m['ownerUid'] ?? '') as String,
      category: teamCategoryFromString((m['category'] ?? 'other') as String),
      isPublic: (m['isPublic'] ?? true) as bool,
      createdAt: (m['createdAt'] as Timestamp).toDate(),
    );
  }

  // ───────────────── Teams for current user (owner OR member) ─────────────────
  // We assume when creating a team we also add the owner to /members with role "owner".
  // That lets a single collectionGroup('members') query cover both owner & member cases.
  @override
  Stream<List<Team>> watchTeamsForUser(String uid) {
    return _db
        .collectionGroup('members')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .asyncMap((memberSnaps) async {
      final seen = <String>{};
      final teams = <Team>[];
      for (final m in memberSnaps.docs) {
        final parentTeamRef = m.reference.parent.parent; // /teams/{teamId}
        if (parentTeamRef == null) continue;
        if (!seen.add(parentTeamRef.id)) continue; // de-dupe
        final tSnap = await (parentTeamRef as DocumentReference<Map<String, dynamic>>).get();
        if (tSnap.exists && tSnap.data() != null) {
          teams.add(_toTeam(tSnap));
        }
      }
      teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return teams;
    });
  }

  // ───────────────── Browse by category (public teams) ─────────────────
  @override
  Stream<List<Team>> browseTeamsByCategory(TeamCategory cat) {
    return _teams
        .where('isPublic', isEqualTo: true)
        .where('category', isEqualTo: teamCategoryToString(cat))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_toTeam).toList());
  }

  @override
  Future<Team> createTeam({
    required String ownerUid,
    required String name,
    required TeamCategory category,
    bool isPublic = true,
  }) async {
    final now = DateTime.now();
    final ref = await _teams.add({
      'name': name,
      'ownerUid': ownerUid,
      'category': teamCategoryToString(category),
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(now),
    });

    // Add owner as member
    await ref.collection('members').add({
      'userId': ownerUid,
      'role': 'owner',
      'createdAt': Timestamp.fromDate(now),
    });

    return Team(
      id: ref.id,
      name: name,
      ownerUid: ownerUid,
      category: category,
      isPublic: isPublic,
      createdAt: now,
    );
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    final teamRef = _teams.doc(teamId);

    final members = await teamRef.collection('members').get();
    for (final d in members.docs) {
      await d.reference.delete();
    }

    final stats = await teamRef.collection('player_stats').get();
    for (final d in stats.docs) {
      await d.reference.delete();
    }

    final requests = await teamRef.collection('join_requests').get();
    for (final d in requests.docs) {
      await d.reference.delete();
    }

    await teamRef.delete();
  }

  // ───────────────── Members ─────────────────
  @override
  Stream<List<Member>> watchMembers(String teamId) {
    return _teams
        .doc(teamId)
        .collection('members')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) {
      final m = d.data();
      final rawId = (m['userId'] ?? '') as String;
      final display = _displayNameFromId(rawId);

      return Member(
        id: d.id,
        userId: display, // <-- show only the part before '@'
        role: memberRoleFromString((m['role'] ?? 'player') as String),
        createdAt: (m['createdAt'] as Timestamp).toDate(),
      );
    }).toList());
  }

  @override
  Future<Member> addMember({
    required String teamId,
    required String userId,
    required MemberRole role,
  }) async {
    final now = DateTime.now();
    final doc = await _teams.doc(teamId).collection('members').add({
      'userId': userId,
      'role': memberRoleToString(role),
      'createdAt': Timestamp.fromDate(now),
    });
    return Member(id: doc.id, userId: userId, role: role, createdAt: now);
  }

  @override
  Future<void> updateMemberRole({
    required String teamId,
    required String memberId,
    required MemberRole role,
  }) {
    return _teams
        .doc(teamId)
        .collection('members')
        .doc(memberId)
        .update({'role': memberRoleToString(role)});
  }

  @override
  Future<void> removeMember({
    required String teamId,
    required String memberId,
  }) async {
    final teamRef = _teams.doc(teamId);
    await teamRef.collection('members').doc(memberId).delete();
    final statDoc = teamRef.collection('player_stats').doc(memberId);
    final statSnap = await statDoc.get();
    if (statSnap.exists) await statDoc.delete();
  }

  // ───────────────── Player stats ─────────────────
  @override
  Stream<PlayerStats?> watchPlayerStats({
    required String teamId,
    required String memberId,
  }) {
    final ref = _teams.doc(teamId).collection('player_stats').doc(memberId);
    return ref.snapshots().map((d) {
      if (!d.exists) return null;
      final m = d.data()!;
      return PlayerStats(
        memberId: memberId,
        winRate: (m['winRate'] ?? 0.0).toDouble(),
        loseRate: (m['loseRate'] ?? 0.0).toDouble(),
        stars: (m['stars'] ?? 0) as int,
        recommendations: (m['recommendations'] ?? 0) as int,
        updatedAt: (m['updatedAt'] as Timestamp).toDate(),
      );
    });
  }

  @override
  Future<void> upsertPlayerStats({
    required String teamId,
    required String memberId,
    double? winRate,
    double? loseRate,
    int? stars,
    int? recommendations,
  }) {
    final ref = _teams.doc(teamId).collection('player_stats').doc(memberId);
    return ref.set({
      if (winRate != null) 'winRate': winRate,
      if (loseRate != null) 'loseRate': loseRate,
      if (stars != null) 'stars': stars,
      if (recommendations != null) 'recommendations': recommendations,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ───────────────── Join requests ─────────────────
  @override
  Future<void> requestJoin({
    required String teamId,
    required String userId,
    String? message,
  }) {
    final ref = _teams.doc(teamId).collection('join_requests').doc(userId);
    return ref.set({
      'userId': userId,
      'message': message ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<String>> watchPendingRequestsUserIds(String teamId) {
    return _teams
        .doc(teamId)
        .collection('join_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => (d.data()['userId'] ?? '') as String).toList());
  }

  @override
  Stream<List<Team>> watchPublicTeams({TeamCategory? category}) {
    Query<Map<String, dynamic>> q = _teams.where('isPublic', isEqualTo: true);
    if (category != null) {
      q = q.where('category', isEqualTo: teamCategoryToString(category));
    }
    return q
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_toTeam).toList());
  }

// 3.b) OWNER: accept/decline request atomically (replace your existing method with this)
  @override
  Future<void> respondToJoinRequest({
    required String teamId,
    required String userId,
    required bool accept,
    MemberRole roleIfAccept = MemberRole.player,
  }) async {
    final teamRef = _teams.doc(teamId);
    final reqRef = teamRef.collection('join_requests').doc(userId);
    final membersRef = teamRef.collection('members');

    await _db.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) return; // already handled

      if (accept) {
        tx.set(membersRef.doc(), {
          'userId': userId,
          'role': memberRoleToString(roleIfAccept),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Always remove the request (your UX: accepted -> in "My Teams"; declined -> can apply again)
      tx.delete(reqRef);
    });
  }

}
