import 'package:yourleague/User/features/matches/domain/entities/match.dart';
import 'package:yourleague/User/features/matches/domain/entities/match_event.dart';
import 'package:yourleague/User/features/matches/domain/entities/leaderboard.dart';

abstract class MatchesState {}

class MatchesInitial extends MatchesState {}

class MatchesLoading extends MatchesState {}

// Match States
class MatchLoaded extends MatchesState {
  final Match match;
  MatchLoaded(this.match);
}

class MatchesLoaded extends MatchesState {
  final List<Match> matches;
  MatchesLoaded(this.matches);
}

// Match Event States
class MatchEventLoaded extends MatchesState {
  final MatchEvent event;
  MatchEventLoaded(this.event);
}

class MatchEventsLoaded extends MatchesState {
  final List<MatchEvent> events;
  MatchEventsLoaded(this.events);
}

// Leaderboard States
class LeaderboardLoaded extends MatchesState {
  final Leaderboard leaderboard;
  LeaderboardLoaded(this.leaderboard);
}

class LeaderboardsLoaded extends MatchesState {
  final List<Leaderboard> leaderboards;
  LeaderboardsLoaded(this.leaderboards);
}

// Bracket data state (leaderboards + matches for a tournament)
class BracketDataLoaded extends MatchesState {
  final String tournamentId;
  final List<Leaderboard> leaderboards;
  final List<Match> matches;
  BracketDataLoaded(
      {required this.tournamentId,
      required this.leaderboards,
      required this.matches});
}

// Success/Error States
class OperationSuccess extends MatchesState {
  final String message;
  OperationSuccess(this.message);
}

class MatchesError extends MatchesState {
  final String message;
  MatchesError(this.message);
}
