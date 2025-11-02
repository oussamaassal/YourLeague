import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities.dart';
import '../../domain/repos/players_repo.dart';

sealed class PlayerProfileState {}
class PlayerProfileLoading extends PlayerProfileState {}
class PlayerProfileLoaded extends PlayerProfileState {
  final Player? me;
  PlayerProfileLoaded(this.me);
}
class PlayerProfileError extends PlayerProfileState {
  final String message;
  PlayerProfileError(this.message);
}

class PlayerProfileCubit extends Cubit<PlayerProfileState> {
  final PlayersRepo repo;
  PlayerProfileCubit(this.repo) : super(PlayerProfileLoading());

  Stream<Player?>? _sub;

  void watch(String userId) {
    emit(PlayerProfileLoading());
    _sub?.drain();
    _sub = repo.watchPlayer(userId);
    _sub!.listen(
          (p) => emit(PlayerProfileLoaded(p)),
      onError: (e) => emit(PlayerProfileError(e.toString())),
    );
  }

  Future<void> save({
    required String userId,
    required String handle,
    required bool available,
    required List<String> categories,
  }) async {
    await repo.upsertMyPlayerProfile(
      userId: userId,
      handle: handle,
      available: available,
      categories: categories,
    );
  }
}

