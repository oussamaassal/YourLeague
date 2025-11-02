import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities.dart';
import '../../domain/repos/teams_repo.dart';

sealed class RequestsState {}
class RequestsLoading extends RequestsState {}
class RequestsLoaded extends RequestsState { final List<String> userIds; RequestsLoaded(this.userIds); }
class RequestsError extends RequestsState { final String message; RequestsError(this.message); }

class RequestsCubit extends Cubit<RequestsState> {
  final TeamsRepo repo;
  RequestsCubit(this.repo) : super(RequestsLoading());

  StreamSubscription<List<String>>? _sub;

  void watch(String teamId) {
    emit(RequestsLoading());
    _sub?.cancel();
    _sub = repo.watchPendingRequestsUserIds(teamId).listen(
          (u) => emit(RequestsLoaded(u)),
      onError: (e) => emit(RequestsError(e.toString())),
    );
  }

  Future<void> respond(String teamId, String userId, bool accept, {MemberRole roleIfAccept = MemberRole.player}) async {
    try { await repo.respondToJoinRequest(teamId: teamId, userId: userId, accept: accept, roleIfAccept: roleIfAccept); }
    catch (e) { emit(RequestsError(e.toString())); }
  }

  @override
  Future<void> close() async { await _sub?.cancel(); return super.close(); }
}
