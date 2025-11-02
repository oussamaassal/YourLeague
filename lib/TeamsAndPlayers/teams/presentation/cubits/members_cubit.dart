import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities.dart';
import '../../domain/repos/teams_repo.dart';

sealed class MembersState {}
class MembersLoading extends MembersState {}
class MembersLoaded extends MembersState { final List<Member> members; MembersLoaded(this.members); }
class MembersError extends MembersState { final String message; MembersError(this.message); }

class MembersCubit extends Cubit<MembersState> {
  final TeamsRepo repo;
  MembersCubit(this.repo) : super(MembersLoading());

  StreamSubscription<List<Member>>? _sub;

  void watch(String teamId) {
    emit(MembersLoading());
    _sub?.cancel();
    _sub = repo.watchMembers(teamId).listen(
          (m) => emit(MembersLoaded(m)),
      onError: (e) => emit(MembersError(e.toString())),
    );
  }

  Future<void> add(String teamId, String userId, MemberRole role) async {
    try { await repo.addMember(teamId: teamId, userId: userId, role: role); }
    catch (e) { emit(MembersError(e.toString())); }
  }

  Future<void> changeRole(String teamId, String memberId, MemberRole role) async {
    try { await repo.updateMemberRole(teamId: teamId, memberId: memberId, role: role); }
    catch (e) { emit(MembersError(e.toString())); }
  }

  Future<void> remove(String teamId, String memberId) async {
    try { await repo.removeMember(teamId: teamId, memberId: memberId); }
    catch (e) { emit(MembersError(e.toString())); }
  }

  @override
  Future<void> close() async { await _sub?.cancel(); return super.close(); }
}
