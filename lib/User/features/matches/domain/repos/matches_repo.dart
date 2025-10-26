import '../entities/match.dart';
import '../entities/match_event.dart';
import '../entities/leaderboard.dart';

abstract class MatchesRepo {
  // ==================== MATCH CRUD ====================
  Future<void> createMatch(Match match);
  Future<Match?> getMatch(String matchId);
  Future<List<Match>> getMatchesByTournament(String tournamentId);
  Future<List<Match>> getAllMatches();
  Future<void> updateMatch(Match match);
  Future<void> deleteMatch(String matchId);

  // ==================== MATCH EVENT CRUD ====================
  Future<void> createMatchEvent(MatchEvent event);
  Future<MatchEvent?> getMatchEvent(String eventId);
  Future<List<MatchEvent>> getMatchEventsByMatch(String matchId);
  Future<void> updateMatchEvent(MatchEvent event);
  Future<void> deleteMatchEvent(String eventId);

  // ==================== LEADERBOARD CRUD ====================
  Future<void> createLeaderboard(Leaderboard leaderboard);
  Future<Leaderboard?> getLeaderboard(String leaderboardId);
  Future<List<Leaderboard>> getLeaderboardsByTournament(String tournamentId);
  Future<void> updateLeaderboard(Leaderboard leaderboard);
  Future<void> deleteLeaderboard(String leaderboardId);
}

