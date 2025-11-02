import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities.dart';
import '../../domain/repos/players_repo.dart';

sealed class PlayersSearchState {}
class PlayersSearchLoading extends PlayersSearchState {}
class PlayersSearchLoaded extends PlayersSearchState {
  final List<Player> players;
  PlayersSearchLoaded(this.players);
}
class PlayersSearchError extends PlayersSearchState {
  final String message;
  PlayersSearchError(this.message);
}

class PlayersSearchCubit extends Cubit<PlayersSearchState> {
  final PlayersRepo repo;
  PlayersSearchCubit(this.repo) : super(PlayersSearchLoading());

  Stream<List<Player>>? _sub;

  void search({required String category, String? handlePrefixLower}) {
    emit(PlayersSearchLoading());
    _sub?.drain();
    _sub = repo.searchPlayers(category: category, handlePrefixLower: handlePrefixLower);
    _sub!.listen(
          (list) => emit(PlayersSearchLoaded(list)),
      onError: (e) => emit(PlayersSearchError(e.toString())),
    );
  }
}
