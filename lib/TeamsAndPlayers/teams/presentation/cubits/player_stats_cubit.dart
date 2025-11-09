// lib/User/features/teams/presentation/cubits/player_stats_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repos/teams_repo.dart';
import '../../domain/entities.dart';

sealed class PlayerStatsState {}
class PlayerStatsLoading extends PlayerStatsState {}
class PlayerStatsLoaded extends PlayerStatsState { final PlayerStats? stats; PlayerStatsLoaded(this.stats); }
class PlayerStatsError extends PlayerStatsState { final String message; PlayerStatsError(this.message); }

class PlayerStatsCubit extends Cubit<PlayerStatsState> {
  final TeamsRepo repo;
  PlayerStatsCubit(this.repo) : super(PlayerStatsLoading());

  void watch(String teamId, String memberId) {
    emit(PlayerStatsLoading());
    repo.watchPlayerStats(teamId: teamId, memberId: memberId).listen(
          (s) => emit(PlayerStatsLoaded(s)),
      onError: (e) => emit(PlayerStatsError(e.toString())),
    );
  }

  Future<void> upsert({
    required String teamId,
    required String memberId,
    double? winRate,
    double? loseRate,
    int? stars,
    int? recommendations,
  }) async {
    try {
      await repo.upsertPlayerStats(
        teamId: teamId,
        memberId: memberId,
        winRate: winRate,
        loseRate: loseRate,
        stars: stars,
        recommendations: recommendations,
      );
    } catch (e) {
      emit(PlayerStatsError(e.toString()));
    }
  }
}

