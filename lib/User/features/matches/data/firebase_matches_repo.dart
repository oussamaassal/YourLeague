import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:yourleague/User/features/matches/domain/entities/match.dart';
import 'package:yourleague/User/features/matches/domain/entities/match_event.dart';
import 'package:yourleague/User/features/matches/domain/entities/leaderboard.dart';
import 'package:yourleague/User/features/matches/domain/repos/matches_repo.dart';

class FirebaseMatchesRepo implements MatchesRepo {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;

  // ==================== MATCH CRUD ====================

  @override
  Future<void> createMatch(Match match) async {
    try {
      await _firestore.collection('matches').doc(match.id).set(match.toJson());
      // Also add reference to the tournament's matches array
      final matchRef = _firestore.collection('matches').doc(match.id);
      await _firestore
          .collection('tournaments')
          .doc(match.tournamentId)
          .update({
        'matches': fs.FieldValue.arrayUnion([matchRef])
      });
    } catch (e) {
      throw Exception('Failed to create match: $e');
    }
  }

  @override
  Future<Match?> getMatch(String matchId) async {
    try {
      final doc = await _firestore.collection('matches').doc(matchId).get();
      if (doc.exists) {
        return Match.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get match: $e');
    }
  }

  @override
  Future<List<Match>> getMatchesByTournament(String tournamentId) async {
    try {
      final snapshot = await _firestore
          .collection('matches')
          .where('tournamentId', isEqualTo: tournamentId)
          .orderBy('matchDate', descending: false)
          .get();
      return snapshot.docs.map((doc) => Match.fromJson(doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get matches: $e');
    }
  }

  @override
  Future<List<Match>> getAllMatches() async {
    try {
      final snapshot = await _firestore
          .collection('matches')
          .orderBy('matchDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Match.fromJson(doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get matches: $e');
    }
  }

  @override
  Future<void> updateMatch(Match match) async {
    try {
      await _firestore.collection('matches').doc(match.id).update(match.toJson());
    } catch (e) {
      throw Exception('Failed to update match: $e');
    }
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    try {
      await _firestore.collection('matches').doc(matchId).delete();
    } catch (e) {
      throw Exception('Failed to delete match: $e');
    }
  }

  // ==================== MATCH EVENT CRUD ====================

  @override
  Future<void> createMatchEvent(MatchEvent event) async {
    try {
      await _firestore.collection('match_events').doc(event.id).set(event.toJson());
    } catch (e) {
      throw Exception('Failed to create match event: $e');
    }
  }

  @override
  Future<MatchEvent?> getMatchEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('match_events').doc(eventId).get();
      if (doc.exists) {
        return MatchEvent.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get match event: $e');
    }
  }

  @override
  Future<List<MatchEvent>> getMatchEventsByMatch(String matchId) async {
    try {
      final snapshot = await _firestore
          .collection('match_events')
          .where('matchId', isEqualTo: matchId)
          .get();
      
      // Trier les résultats en mémoire au lieu de Firestore
      final events = snapshot.docs
          .map((doc) => MatchEvent.fromJson(doc.data()!))
          .toList();
      
      // Trier par minute
      events.sort((a, b) => a.minute.compareTo(b.minute));
      
      return events;
    } catch (e) {
      throw Exception('Failed to get match events: $e');
    }
  }

  @override
  Future<void> updateMatchEvent(MatchEvent event) async {
    try {
      await _firestore.collection('match_events').doc(event.id).update(event.toJson());
    } catch (e) {
      throw Exception('Failed to update match event: $e');
    }
  }

  @override
  Future<void> deleteMatchEvent(String eventId) async {
    try {
      await _firestore.collection('match_events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete match event: $e');
    }
  }

  // ==================== LEADERBOARD CRUD ====================

  @override
  Future<void> createLeaderboard(Leaderboard leaderboard) async {
    try {
      await _firestore
          .collection('leaderboards')
          .doc(leaderboard.id)
          .set(leaderboard.toJson());
    } catch (e) {
      throw Exception('Failed to create leaderboard: $e');
    }
  }

  @override
  Future<Leaderboard?> getLeaderboard(String leaderboardId) async {
    try {
      final doc = await _firestore.collection('leaderboards').doc(leaderboardId).get();
      if (doc.exists) {
        return Leaderboard.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  @override
  Future<List<Leaderboard>> getLeaderboardsByTournament(String tournamentId) async {
    try {
      final snapshot = await _firestore
          .collection('leaderboards')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();
      
      // Trier les résultats en mémoire
      final leaderboards = snapshot.docs
          .map((doc) => Leaderboard.fromJson(doc.data()!))
          .toList();
      
      // Trier par points, puis par goal difference
      leaderboards.sort((a, b) {
        final pointsComparison = b.points.compareTo(a.points);
        if (pointsComparison != 0) return pointsComparison;
        return b.goalDifference.compareTo(a.goalDifference);
      });
      
      return leaderboards;
    } catch (e) {
      throw Exception('Failed to get leaderboards: $e');
    }
  }

  @override
  Future<void> updateLeaderboard(Leaderboard leaderboard) async {
    try {
      await _firestore
          .collection('leaderboards')
          .doc(leaderboard.id)
          .update(leaderboard.toJson());
    } catch (e) {
      throw Exception('Failed to update leaderboard: $e');
    }
  }

  @override
  Future<void> deleteLeaderboard(String leaderboardId) async {
    try {
      await _firestore.collection('leaderboards').doc(leaderboardId).delete();
    } catch (e) {
      throw Exception('Failed to delete leaderboard: $e');
    }
  }
}
