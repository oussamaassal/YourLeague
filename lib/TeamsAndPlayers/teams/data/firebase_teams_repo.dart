import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities.dart';
import '../domain/repos/teams_repo.dart';

class FirebaseTeamsRepo implements TeamsRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _teams => _db.collection('teams');

  // Helper to display usernames nicely
  String _displayNameFromId(String userId) {
    return userId.contains('@') ? userId.split('@').first : userId;
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

  // Toggle team visibility (owner only)
  Future<void> setTeamVisibility({
    required String teamId,
    required bool isPublic,
  }) {
    return _teams.doc(teamId).update({'isPublic': isPublic});
  }

  // Join via QR or quick join
  Future<void> joinViaQuickPath({
    required String teamId,
    required String userId,
  }) async {
    final teamSnap = await _teams.doc(teamId).get();
    if (!teamSnap.exists) return;

    final isPublic = (teamSnap.data()?['isPublic'] ?? true) as bool;
    final teamName = teamSnap.data()?['name'] ?? 'a team';

    if (isPublic) {
      // If team is public, directly add as member
      final mems = await _teams
          .doc(teamId)
          .collection('members')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (mems.docs.isEmpty) {
        await _teams.doc(teamId).collection('members').add({
          'userId': userId,
          'role': 'player',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // In-app notification for player
        await _db.collection('users').doc(userId).collection('notifications').add({
          'type': 'joined_team',
          'title': 'Joined Team',
          'body': 'You joined $teamName successfully!',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      // If team is private, create join request
      await _teams.doc(teamId).collection('join_requests').doc(userId).set({
        'userId': userId,
        'message': '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify the owner
      final ownerId = teamSnap.data()?['ownerUid'];
      if (ownerId != null && ownerId.isNotEmpty) {
        await _db.collection('users').doc(ownerId).collection('notifications').add({
          'type': 'join_request',
          'title': 'New Join Request',
          'body': 'A player requested to join $teamName.',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Watch all teams for a specific user (owner or member)
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
        if (!seen.add(parentTeamRef.id)) continue;

        final tSnap =
        await (parentTeamRef as DocumentReference<Map<String, dynamic>>).get();
        if (tSnap.exists && tSnap.data() != null) {
          teams.add(_toTeam(tSnap));
        }
      }

      teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return teams;
    });
  }

  // Browse all public teams (by category)
  @override
  Stream<List<Team>> browseTeamsByCategory(TeamCategory cat) {
    return _teams
        .where('isPublic', isEqualTo: true)
        .where('category', isEqualTo: teamCategoryToString(cat))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_toTeam).toList());
  }

  // Create a new team
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

  // Delete a team and all its data
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

  // Watch team members
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
        userId: display,
        role: memberRoleFromString((m['role'] ?? 'player') as String),
        createdAt: (m['createdAt'] as Timestamp).toDate(),
      );
    }).toList());
  }

  // Add a new member manually
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

  // Update member role
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

  // Remove a member
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

  // Watch player stats
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

  // Update or insert player stats
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

  // Create a join request (player side)
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

  // Watch all pending join requests (owner view)
  @override
  Stream<List<String>> watchPendingRequestsUserIds(String teamId) {
    return _teams
        .doc(teamId)
        .collection('join_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => (d.data()['userId'] ?? '') as String).toList());
  }

  // Watch all public teams (optionally filtered by category)
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

  // Respond to join request (owner action)
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
    final teamSnap = await teamRef.get();
    final teamName = teamSnap.data()?['name'] ?? 'a team';

    await _db.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) return;

      if (accept) {
        tx.set(membersRef.doc(), {
          'userId': userId,
          'role': memberRoleToString(roleIfAccept),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      tx.delete(reqRef);
    });

    await _db.collection('users').doc(userId).collection('notifications').add({
      'type': accept ? 'accepted' : 'declined',
      'title': accept ? 'Request Accepted' : 'Request Declined',
      'body': accept
          ? 'You have been accepted to join $teamName!'
          : 'Your join request for $teamName was declined.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
