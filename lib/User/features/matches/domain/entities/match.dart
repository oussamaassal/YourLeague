import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class Match {
  final String id;
  final String tournamentId;
  final String team1Id;
  final String team1Name;
  final String team2Id;
  final String team2Name;
  final int score1;
  final int score2;
  final String status; // 'scheduled', 'ongoing', 'completed', 'cancelled'
  final fs.Timestamp matchDate;
  final fs.Timestamp createdAt;
  final String? refereeId;
  final String? location;
  final String? notes;

  Match({
    required this.id,
    required this.tournamentId,
    required this.team1Id,
    required this.team1Name,
    required this.team2Id,
    required this.team2Name,
    this.score1 = 0,
    this.score2 = 0,
    this.status = 'scheduled',
    required this.matchDate,
    required this.createdAt,
    this.refereeId,
    this.location,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'team1Id': team1Id,
      'team1Name': team1Name,
      'team2Id': team2Id,
      'team2Name': team2Name,
      'score1': score1,
      'score2': score2,
      'status': status,
      'matchDate': matchDate,
      'createdAt': createdAt,
      'refereeId': refereeId,
      'location': location,
      'notes': notes,
    };
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      tournamentId: json['tournamentId'],
      team1Id: json['team1Id'],
      team1Name: json['team1Name'],
      team2Id: json['team2Id'],
      team2Name: json['team2Name'],
      score1: json['score1'] ?? 0,
      score2: json['score2'] ?? 0,
      status: json['status'] ?? 'scheduled',
      matchDate: json['matchDate'],
      createdAt: json['createdAt'],
      refereeId: json['refereeId'],
      location: json['location'],
      notes: json['notes'],
    );
  }
}

