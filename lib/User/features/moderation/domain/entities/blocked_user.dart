class BlockedUser {
  final String id;
  final String blockerUid;
  final String blockedUid;
  final String blockedEmail;

  BlockedUser({
    required this.id,
    required this.blockerUid,
    required this.blockedUid,
    required this.blockedEmail,
  });

  // convert to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blockerUid': blockerUid,
      'blockedUid': blockedUid,
      'blockedEmail': blockedEmail,
    };
  }

  // convert from json
  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'],
      blockerUid: json['blockerUid'],
      blockedUid: json['blockedUid'],
      blockedEmail: json['blockedEmail'],
    );
  }
}
