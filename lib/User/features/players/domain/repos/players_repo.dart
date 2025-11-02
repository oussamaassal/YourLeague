import '../entities.dart';

abstract class PlayersRepo {
  Future<void> upsertMyPlayerProfile({
    required String userId,
    required String handle,
    required bool available,
    required List<String> categories,
  });

  Stream<Player?> watchPlayer(String userId);

  /// Search available players by category (and optional handle prefix).
  Stream<List<Player>> searchPlayers({
    required String category,
    String? handlePrefixLower, // nullable
  });

  // Invites
  Future<void> sendInvite({
    required String teamId,
    required String playerId,
    String roleOffered = 'player',
  });

  Stream<List<TeamInvite>> watchTeamInvites(String teamId);
  Stream<List<TeamInvite>> watchUserInvites(String userId);

  Future<void> acceptInvite({required String teamId, required String userId});
  Future<void> declineInvite({required String teamId, required String userId});
}
