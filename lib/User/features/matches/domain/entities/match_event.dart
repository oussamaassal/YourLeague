import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class MatchEvent {
  final String id;
  final String matchId;
  final String type; // 'goal', 'yellow_card', 'red_card', 'substitution', 'other'
  final String? teamId;
  final String? playerId;
  final String? playerName;
  final String? description;
  final int minute;
  final fs.Timestamp createdAt;

  MatchEvent({
    required this.id,
    required this.matchId,
    required this.type,
    this.teamId,
    this.playerId,
    this.playerName,
    this.description,
    this.minute = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'type': type,
      'teamId': teamId,
      'playerId': playerId,
      'playerName': playerName,
      'description': description,
      'minute': minute,
      'createdAt': createdAt,
    };
  }

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['id'],
      matchId: json['matchId'],
      type: json['type'],
      teamId: json['teamId'],
      playerId: json['playerId'],
      playerName: json['playerName'],
      description: json['description'],
      minute: json['minute'] ?? 0,
      createdAt: json['createdAt'],
    );
  }
}

