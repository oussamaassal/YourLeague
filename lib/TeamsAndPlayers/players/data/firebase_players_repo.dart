import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities.dart';
import '../domain/repos/players_repo.dart';

// Email via EmailJS (client-side, free)
import '../../notifications/email_service.dart';

class FirebasePlayersRepo implements PlayersRepo {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _players =>
      _db.collection('players');
  CollectionReference<Map<String, dynamic>> _teamInvites(String teamId) =>
      _db.collection('teams').doc(teamId).collection('invites');
  CollectionReference<Map<String, dynamic>> _userInvites(String userId) =>
      _db.collection('users').doc(userId).collection('team_invites');
  CollectionReference<Map<String, dynamic>> _teamMembers(String teamId) =>
      _db.collection('teams').doc(teamId).collection('members');

  Player _toPlayer(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    final rawHandle = (m['handle'] ?? '') as String;
    final handle =
    rawHandle.isNotEmpty ? rawHandle : (m['userId'] as String).split('@').first;
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
    return _players
        .doc(userId)
        .snapshots()
        .map((d) => d.exists ? _toPlayer(d) : null);
  }

  @override
  Stream<List<Player>> searchPlayers({
    required String category,
    String? handlePrefixLower,
  }) {
    Query<Map<String, dynamic>> q = _players
        .where('available', isEqualTo: true)
        .where('categories', arrayContains: category);

    if (handlePrefixLower != null && handlePrefixLower.trim().isNotEmpty) {
      final start = handlePrefixLower.toLowerCase();
      final end = '$start\uf8ff';
      q = q
          .where('handleLower', isGreaterThanOrEqualTo: start)
          .where('handleLower', isLessThan: end);
    }

    return q
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_toPlayer).toList());
  }

  @override
  Future<void> sendInvite({
    required String teamId,
    required String playerId,
    String roleOffered = 'player',
  }) async {
    // Mirror invite on team + user sides
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

    // Optional: create an in-app notification document (free, client-side).
    // Your app can listen to /users/{uid}/notifications and show a local banner.
    await _db
        .collection('users')
        .doc(playerId)
        .collection('notifications')
        .add({
      'type': 'invite',
      'teamId': teamId,
      'title': 'Team Invitation',
      'body': 'You have been invited to join a team.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Email notification via EmailJS (free)
    final userDoc = await _db.collection('users').doc(playerId).get();
    final email = userDoc.data()?['email'];
    if (email is String && email.trim().isNotEmpty) {
      await EmailService.sendEmail(
        toEmail: email,
        subject: 'Team Invitation',
        message:
        'You have been invited to join a team in YourLeague. Open the app to review the invite.',
      );
    }
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
  Future<void> acceptInvite({
    required String teamId,
    required String userId,
  }) async {
    // Add as member (role from invite), then delete both mirrors
    await _db.runTransaction((tx) async {
      final teamInviteRef = _teamInvites(teamId).doc(userId);
      final userInviteRef = _userInvites(userId).doc(teamId);
      final inviteSnap = await tx.get(teamInviteRef);
      if (!inviteSnap.exists) return;

      final roleOffered =
      (inviteSnap.data()!['roleOffered'] ?? 'player') as String;

      tx.set(_teamMembers(teamId).doc(), {
        'userId': userId,
        'role': roleOffered,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.delete(teamInviteRef);
      tx.delete(userInviteRef);
    });

    // In-app notification for the player (appears when app is open)
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'type': 'accepted',
      'teamId': teamId,
      'title': 'Joined Team',
      'body': 'Your invitation was accepted. You are now in the team!',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Email notification
    final userDoc = await _db.collection('users').doc(userId).get();
    final email = userDoc.data()?['email'];
    if (email is String && email.trim().isNotEmpty) {
      await EmailService.sendEmail(
        toEmail: email,
        subject: 'Welcome to your new team!',
        message:
        'Your invitation has been accepted. You are now part of the team in YourLeague.',
      );
    }
  }

  @override
  Future<void> declineInvite({
    required String teamId,
    required String userId,
  }) async {
    final batch = _db.batch();
    batch.delete(_teamInvites(teamId).doc(userId));
    batch.delete(_userInvites(userId).doc(teamId));
    await batch.commit();
  }
}
