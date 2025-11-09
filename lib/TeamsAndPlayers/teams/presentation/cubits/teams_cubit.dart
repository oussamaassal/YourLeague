import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities.dart';
import '../../domain/repos/teams_repo.dart';

sealed class TeamsState {}
class TeamsLoading extends TeamsState {}
class TeamsLoaded extends TeamsState { final List<Team> teams; TeamsLoaded(this.teams); }
class TeamsError extends TeamsState { final String message; TeamsError(this.message); }

class TeamsCubit extends Cubit<TeamsState> {
  final TeamsRepo repo;
  TeamsCubit(this.repo) : super(TeamsLoading());

  StreamSubscription<List<Team>>? _sub;

  void watchForUser(String uid) {
    emit(TeamsLoading());
    _sub?.cancel();
    _sub = repo.watchTeamsForUser(uid).listen(
          (t) => emit(TeamsLoaded(t)),
      onError: (e) => emit(TeamsError(e.toString())),
    );
  }

  Future<void> create(String ownerUid, String name, TeamCategory cat, {bool isPublic = true}) async {
    try { await repo.createTeam(ownerUid: ownerUid, name: name, category: cat, isPublic: isPublic); }
    catch (e) { emit(TeamsError(e.toString())); }
  }

  Future<void> deleteTeam(String id) async {
    try { await repo.deleteTeam(id); }
    catch (e) { emit(TeamsError(e.toString())); }
  }

  @override
  Future<void> close() async { await _sub?.cancel(); return super.close(); }
}
