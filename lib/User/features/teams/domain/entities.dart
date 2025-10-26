// lib/User/features/teams/domain/entities.dart

enum MemberRole { player, organizer, owner }
MemberRole memberRoleFromString(String s) {
  switch (s) { case 'organizer': return MemberRole.organizer; case 'owner': return MemberRole.owner; default: return MemberRole.player; }
}
String memberRoleToString(MemberRole r) {
  switch (r) { case MemberRole.organizer: return 'organizer'; case MemberRole.owner: return 'owner'; case MemberRole.player: default: return 'player'; }
}

enum TeamCategory { football, basketball, volleyball, esports, other }
TeamCategory teamCategoryFromString(String s) {
  switch (s) { case 'football': return TeamCategory.football; case 'basketball': return TeamCategory.basketball; case 'volleyball': return TeamCategory.volleyball; case 'esports': return TeamCategory.esports; default: return TeamCategory.other; }
}
String teamCategoryToString(TeamCategory c) {
  switch (c) { case TeamCategory.football: return 'football'; case TeamCategory.basketball: return 'basketball'; case TeamCategory.volleyball: return 'volleyball'; case TeamCategory.esports: return 'esports'; case TeamCategory.other: default: return 'other'; }
}

class Team {
  final String id;
  final String name;
  final String ownerUid;
  final TeamCategory category;
  final bool isPublic;
  final DateTime createdAt;

  const Team({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.category,
    required this.isPublic,
    required this.createdAt,
  });
}

class Member {
  final String id;        // /teams/{teamId}/members/{id}
  final String userId;    // Auth UID
  final MemberRole role;
  final DateTime createdAt;

  const Member({required this.id, required this.userId, required this.role, required this.createdAt});
}

class PlayerStats {
  final String memberId;
  final double winRate;
  final double loseRate;
  final int stars;
  final int recommendations;
  final DateTime updatedAt;

  const PlayerStats({
    required this.memberId,
    required this.winRate,
    required this.loseRate,
    required this.stars,
    required this.recommendations,
    required this.updatedAt,
  });
}
