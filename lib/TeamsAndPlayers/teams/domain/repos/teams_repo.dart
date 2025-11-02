// lib/User/features/teams/domain/repos/teams_repo.dart
import '../entities.dart';

abstract class TeamsRepo {
  // Teams
  Stream<List<Team>> watchTeamsForUser(String uid);                // teams user belongs to (owner OR member)
  Stream<List<Team>> browseTeamsByCategory(TeamCategory cat);      // for discovery
  Future<Team> createTeam({required String ownerUid, required String name, required TeamCategory category, bool isPublic = true});
  Future<void> deleteTeam(String teamId);
  // Members
  Stream<List<Member>> watchMembers(String teamId);
  Future<Member> addMember({required String teamId, required String userId, required MemberRole role});
  Future<void> updateMemberRole({required String teamId, required String memberId, required MemberRole role});
  Future<void> removeMember({required String teamId, required String memberId});

  // Player stats
  Stream<PlayerStats?> watchPlayerStats({required String teamId, required String memberId});
  Future<void> upsertPlayerStats({required String teamId, required String memberId, double? winRate, double? loseRate, int? stars, int? recommendations});

  // Join requests
  Future<void> requestJoin({required String teamId, required String userId, String? message});
  Stream<List<String>> watchPendingRequestsUserIds(String teamId); // owner view
  Future<void> respondToJoinRequest({required String teamId, required String userId, required bool accept, MemberRole roleIfAccept = MemberRole.player});
  /// Stream of all public teams. Filter by category if provided.
  Stream<List<Team>> watchPublicTeams({TeamCategory? category});

}
