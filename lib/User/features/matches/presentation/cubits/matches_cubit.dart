import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/matches/domain/entities/match.dart';
import 'package:yourleague/User/features/matches/domain/entities/match_event.dart';
import 'package:yourleague/User/features/matches/domain/entities/leaderboard.dart';
import 'package:yourleague/User/features/matches/domain/repos/matches_repo.dart';
import 'matches_states.dart';

class MatchesCubit extends Cubit<MatchesState> {
  final MatchesRepo matchesRepo;

  MatchesCubit({required this.matchesRepo}) : super(MatchesInitial());

  // ==================== MATCH CRUD ====================

  Future<void> createMatch({
    required String tournamentId,
    required String team1Id,
    required String team1Name,
    required String team2Id,
    required String team2Name,
    String? refereeId,
    String? location,
    String? notes,
    required DateTime matchDate,
  }) async {
    try {
      emit(MatchesLoading());

      final match = Match(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tournamentId: tournamentId,
        team1Id: team1Id,
        team1Name: team1Name,
        team2Id: team2Id,
        team2Name: team2Name,
        refereeId: refereeId,
        location: location,
        notes: notes,
        matchDate: fs.Timestamp.fromDate(matchDate),
        createdAt: fs.Timestamp.now(),
      );

      await matchesRepo.createMatch(match);
      emit(OperationSuccess('Match created successfully'));
    } catch (e) {
      emit(MatchesError('Failed to create match: $e'));
    }
  }

  Future<void> getMatch(String matchId) async {
    try {
      emit(MatchesLoading());
      final match = await matchesRepo.getMatch(matchId);
      if (match != null) {
        emit(MatchLoaded(match));
      } else {
        emit(MatchesError('Match not found'));
      }
    } catch (e) {
      emit(MatchesError('Failed to get match: $e'));
    }
  }

  Future<void> getMatchesByTournament(String tournamentId) async {
    try {
      emit(MatchesLoading());
      final matches = await matchesRepo.getMatchesByTournament(tournamentId);
      emit(MatchesLoaded(matches));
    } catch (e) {
      emit(MatchesError('Failed to get matches: $e'));
    }
  }

  Future<void> getAllMatches() async {
    try {
      emit(MatchesLoading());
      final matches = await matchesRepo.getAllMatches();
      emit(MatchesLoaded(matches));
    } catch (e) {
      emit(MatchesError('Failed to get matches: $e'));
    }
  }

  Future<void> updateMatch(Match match) async {
    try {
      emit(MatchesLoading());
      await matchesRepo.updateMatch(match);
      emit(OperationSuccess('Match updated successfully'));
    } catch (e) {
      emit(MatchesError('Failed to update match: $e'));
    }
  }

  Future<void> deleteMatch(String matchId) async {
    try {
      emit(MatchesLoading());
      await matchesRepo.deleteMatch(matchId);
      emit(OperationSuccess('Match deleted successfully'));
    } catch (e) {
      emit(MatchesError('Failed to delete match: $e'));
    }
  }

  // ==================== MATCH EVENT CRUD ====================

  Future<void> createMatchEvent({
    required String matchId,
    required String type,
    String? teamId,
    String? playerId,
    String? playerName,
    String? description,
    int minute = 0,
  }) async {
    try {
      emit(MatchesLoading());

      final event = MatchEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        matchId: matchId,
        type: type,
        teamId: teamId,
        playerId: playerId,
        playerName: playerName,
        description: description,
        minute: minute,
        createdAt: fs.Timestamp.now(),
      );

      await matchesRepo.createMatchEvent(event);
      emit(OperationSuccess('Match event created successfully'));
      // Recharger les événements après création
      await getMatchEventsByMatch(matchId);
    } catch (e) {
      emit(MatchesError('Failed to create match event: $e'));
    }
  }

  Future<void> getMatchEventsByMatch(String matchId) async {
    try {
      emit(MatchesLoading());
      final events = await matchesRepo.getMatchEventsByMatch(matchId);
      emit(MatchEventsLoaded(events));
    } catch (e) {
      emit(MatchesError('Failed to get match events: $e'));
    }
  }

  Future<void> deleteMatchEvent(String eventId, String matchId) async {
    try {
      emit(MatchesLoading());
      await matchesRepo.deleteMatchEvent(eventId);
      emit(OperationSuccess('Match event deleted successfully'));
      // Recharger les événements après suppression
      await getMatchEventsByMatch(matchId);
    } catch (e) {
      emit(MatchesError('Failed to delete match event: $e'));
    }
  }

  // ==================== LEADERBOARD CRUD ====================

  Future<void> createLeaderboard({
    required String tournamentId,
    required String teamId,
    required String teamName,
  }) async {
    try {
      emit(MatchesLoading());

      final leaderboard = Leaderboard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tournamentId: tournamentId,
        teamId: teamId,
        teamName: teamName,
        updatedAt: fs.Timestamp.now(),
      );

      await matchesRepo.createLeaderboard(leaderboard);
      emit(OperationSuccess('Leaderboard entry created successfully'));
      // Recharger les leaderboards après création
      await getLeaderboardsByTournament(tournamentId);
    } catch (e) {
      emit(MatchesError('Failed to create leaderboard entry: $e'));
    }
  }

  Future<void> getLeaderboardsByTournament(String tournamentId) async {
    try {
      emit(MatchesLoading());
      final leaderboards = await matchesRepo.getLeaderboardsByTournament(tournamentId);
      emit(LeaderboardsLoaded(leaderboards));
    } catch (e) {
      emit(MatchesError('Failed to get leaderboards: $e'));
    }
  }

  Future<void> updateLeaderboard(Leaderboard leaderboard) async {
    try {
      emit(MatchesLoading());
      await matchesRepo.updateLeaderboard(leaderboard);
      emit(OperationSuccess('Leaderboard updated successfully'));
    } catch (e) {
      emit(MatchesError('Failed to update leaderboard: $e'));
    }
  }

  Future<void> deleteLeaderboard(String leaderboardId, String tournamentId) async {
    try {
      emit(MatchesLoading());
      await matchesRepo.deleteLeaderboard(leaderboardId);
      emit(OperationSuccess('Leaderboard entry deleted successfully'));
      // Recharger les leaderboards après suppression
      await getLeaderboardsByTournament(tournamentId);
    } catch (e) {
      emit(MatchesError('Failed to delete leaderboard entry: $e'));
    }
  }
}

