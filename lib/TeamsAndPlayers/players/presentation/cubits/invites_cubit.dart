import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities.dart';
import '../../domain/repos/players_repo.dart';

sealed class TeamInvitesState {}
class TeamInvitesLoading extends TeamInvitesState {}
class TeamInvitesLoaded extends TeamInvitesState {
  final List<TeamInvite> invites;
  TeamInvitesLoaded(this.invites);
}
class TeamInvitesError extends TeamInvitesState {
  final String message;
  TeamInvitesError(this.message);
}

sealed class UserInvitesState {}
class UserInvitesLoading extends UserInvitesState {}
class UserInvitesLoaded extends UserInvitesState {
  final List<TeamInvite> invites;
  UserInvitesLoaded(this.invites);
}
class UserInvitesError extends UserInvitesState {
  final String message;
  UserInvitesError(this.message);
}

class TeamInvitesCubit extends Cubit<TeamInvitesState> {
  final PlayersRepo repo;
  TeamInvitesCubit(this.repo) : super(TeamInvitesLoading());
  Stream<List<TeamInvite>>? _sub;

  void watch(String teamId) {
    emit(TeamInvitesLoading());
    _sub?.drain();
    _sub = repo.watchTeamInvites(teamId);
    _sub!.listen(
          (list) => emit(TeamInvitesLoaded(list)),
      onError: (e) => emit(TeamInvitesError(e.toString())),
    );
  }

  Future<void> send(String teamId, String playerId, {String roleOffered = 'player'}) =>
      repo.sendInvite(teamId: teamId, playerId: playerId, roleOffered: roleOffered);
}

class UserInvitesCubit extends Cubit<UserInvitesState> {
  final PlayersRepo repo;
  UserInvitesCubit(this.repo) : super(UserInvitesLoading());
  Stream<List<TeamInvite>>? _sub;

  void watch(String userId) {
    emit(UserInvitesLoading());
    _sub?.drain();
    _sub = repo.watchUserInvites(userId);
    _sub!.listen(
          (list) => emit(UserInvitesLoaded(list)),
      onError: (e) => emit(UserInvitesError(e.toString())),
    );
  }

  Future<void> accept(String teamId, String userId) =>
      repo.acceptInvite(teamId: teamId, userId: userId);

  Future<void> decline(String teamId, String userId) =>
      repo.declineInvite(teamId: teamId, userId: userId);
}
