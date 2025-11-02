// Player + Invite domain entities

enum MemberRole { owner, organizer, player }

String memberRoleToString(MemberRole r) =>
    r.name; // "owner" | "organizer" | "player"
MemberRole memberRoleFromString(String s) =>
    MemberRole.values.firstWhere((e) => e.name == s, orElse: () => MemberRole.player);

class Player {
  final String userId;
  final String handle;
  final bool available;
  final List<String> categories;
  final int recommendations;
  final int skill;

  Player({
    required this.userId,
    required this.handle,
    required this.available,
    required this.categories,
    required this.recommendations,
    required this.skill,
  });
}

class TeamInvite {
  final String teamId;
  final String playerId; // uid
  final String roleOffered; // "player" or "organizer"
  final String status; // "pending" | "accepted" | "declined"
  TeamInvite({
    required this.teamId,
    required this.playerId,
    required this.roleOffered,
    required this.status,
  });
}
