import 'package:cloud_firestore/cloud_firestore.dart';
import '../../teams/domain/entities.dart' show MemberRole, memberRoleToString;
import '../domain/entities.dart';
import '../domain/repos/players_repo.dart';

class FirebasePlayersRepo implements PlayersRepo {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _players => _db.collection('players');
  CollectionReference<Map<String, dynamic>> _teamInvites(String teamId) =>
      _db.collection('teams').doc(teamId).collection('invites');
  CollectionReference<Map<String, dynamic>> _userInvites(String userId) =>
      _db.collection('users').doc(userId).collection('team_invites');
  CollectionReference<Map<String, dynamic>> _teamMembers(String teamId) =>
      _db.collection('teams').doc(teamId).collection('members');

  Player _toPlayer(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    final rawHandle = (m['handle'] ?? '') as String;
    final handle = rawHandle.isNotEmpty
        ? rawHandle
        : (m['userId'] as String).split('@').first;
    return Player(
      userId: (m['userId'] ?? d.id) as String,
      handle: handle,
      available: (m['available'] ?? false) as bool,
      categories: (m['categories'] as List?)?.cast<String>() ?? const [],
      recommendations: (m['recommendations'] ?? 0) as int,
      skill: (m['skill'] ?? 0) as int,
    );
  }

  TeamInvite _toInvite(String teamId, DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return TeamInvite(
      teamId: teamId,
      playerId: (m['playerId'] ?? '') as String,
      roleOffered: (m['roleOffered'] ?? 'player') as String,
      status: (m['status'] ?? 'pending') as String,
    );
  }

  @override
  Future<void> upsertMyPlayerProfile({
    required String userId,
    required String handle,
    required bool available,
    required List<String> categories,
  }) async {
    await _players.doc(userId).set({
      'userId': userId,
      'handle': handle,
      'handleLower': handle.toLowerCase(),
      'available': available,
      'categories': categories,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<Player?> watchPlayer(String userId) {
    return _players.doc(userId).snapshots().map((d) => d.exists ? _toPlayer(d) : null);
  }

  @override
  Stream<List<Player>> searchPlayers({
    required String category,
    String? handlePrefixLower,
  }) {
    // Base: available + category contains
    Query<Map<String, dynamic>> q = _players
        .where('available', isEqualTo: true)
        .where('categories', arrayContains: category);

    // Optional handle prefix (range query)
    if (handlePrefixLower != null && handlePrefixLower.trim().isNotEmpty) {
      final start = handlePrefixLower.toLowerCase();
      final end = '$start\uf8ff';
      q = q.where('handleLower', isGreaterThanOrEqualTo: start)
          .where('handleLower', isLessThan: end);
    }

    return q.orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_toPlayer).toList());
  }

  @override
  Future<void> sendInvite({
    required String teamId,
    required String playerId,
    String roleOffered = 'player',
  }) async {
    final batch = _db.batch();
    final teamSide = _teamInvites(teamId).doc(playerId);
    final userSide = _userInvites(playerId).doc(teamId);
    final payload = {
      'playerId': playerId,
      'teamId': teamId,
      'roleOffered': roleOffered,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    batch.set(teamSide, payload);
    batch.set(userSide, payload);
    await batch.commit();
  }

  @override
  Stream<List<TeamInvite>> watchTeamInvites(String teamId) {
    return _teamInvites(teamId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => _toInvite(teamId, d)).toList());
  }

  @override
  Stream<List<TeamInvite>> watchUserInvites(String userId) {
    return _userInvites(userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) {
      final m = d.data();
      return TeamInvite(
        teamId: (m['teamId'] ?? d.id) as String,
        playerId: (m['playerId'] ?? '') as String,
        roleOffered: (m['roleOffered'] ?? 'player') as String,
        status: (m['status'] ?? 'pending') as String,
      );
    }).toList());
  }

  @override
  Future<void> acceptInvite({required String teamId, required String userId}) async {
    // Add as member (role from invite), then delete both invite docs
    await _db.runTransaction((tx) async {
      final teamInviteRef = _teamInvites(teamId).doc(userId);
      final userInviteRef = _userInvites(userId).doc(teamId);
      final inviteSnap = await tx.get(teamInviteRef);
      if (!inviteSnap.exists) return;

      final roleOffered = (inviteSnap.data()!['roleOffered'] ?? 'player') as String;

      // add to members
      tx.set(_teamMembers(teamId).doc(), {
        'userId': userId,
        'role': roleOffered,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // delete or mark accepted
      tx.delete(teamInviteRef);
      tx.delete(userInviteRef);
    });
  }

  @override
  Future<void> declineInvite({required String teamId, required String userId}) async {
    final batch = _db.batch();
    batch.delete(_teamInvites(teamId).doc(userId));
    batch.delete(_userInvites(userId).doc(teamId));
    await batch.commit();
  }
}
