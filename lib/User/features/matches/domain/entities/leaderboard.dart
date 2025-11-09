import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class Leaderboard {
  final String id;
  final String tournamentId;
  final String teamId;
  final String teamName;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points; // wins * 3 + draws
  final int goalDifference;
  final fs.Timestamp updatedAt;

  Leaderboard({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
    this.goalDifference = 0,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'teamId': teamId,
      'teamName': teamName,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'points': points,
      'goalDifference': goalDifference,
      'updatedAt': updatedAt,
    };
  }

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      id: json['id'],
      tournamentId: json['tournamentId'],
      teamId: json['teamId'],
      teamName: json['teamName'],
      matchesPlayed: json['matchesPlayed'] ?? 0,
      wins: json['wins'] ?? 0,
      draws: json['draws'] ?? 0,
      losses: json['losses'] ?? 0,
      goalsFor: json['goalsFor'] ?? 0,
      goalsAgainst: json['goalsAgainst'] ?? 0,
      points: json['points'] ?? 0,
      goalDifference: json['goalDifference'] ?? 0,
      updatedAt: json['updatedAt'],
    );
  }
}

