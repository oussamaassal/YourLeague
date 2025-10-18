import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/blocked_user.dart';
import '../../domain/repos/moderation_repo.dart';
import 'moderation_states.dart';

/*

CUBITS ARE RESPONSIBLE FOR STATE MANAGEMENT!!!

*/

class ModerationCubit extends Cubit<ModerationState> {
  final ModerationRepo moderationRepo;

  ModerationCubit({required this.moderationRepo}) : super(ModerationInitial());

  // cache blocked users
  List<BlockedUser> _blockedUsers = [];
  List<String> _blockedUserIds = [];

  // getters
  List<BlockedUser> get blockedUsers => _blockedUsers;
  List<String> get blockedUserIds => _blockedUserIds;

  // load all blocked users
  Future<void> loadBlockedUsers() async {
    try {
      emit(ModerationLoading());
      _blockedUsers = await moderationRepo.getBlockedUsers();
      _blockedUserIds = _blockedUsers.map((user) => user.blockedUid).toList();
      emit(BlockedUsersLoaded(_blockedUsers));
    } catch (e) {
      emit(ModerationError(e.toString()));
    }
  }

  // block a user
  Future<void> blockUser(String userToBlockUid, String userToBlockEmail) async {
    try {
      emit(ModerationLoading());
      await moderationRepo.blockUser(userToBlockUid, userToBlockEmail);
      emit(UserBlocked());
      await loadBlockedUsers(); // refresh the list
    } catch (e) {
      emit(ModerationError(e.toString()));
    }
  }

  // unblock a user
  Future<void> unblockUser(String userToUnblockUid) async {
    try {
      emit(ModerationLoading());
      await moderationRepo.unblockUser(userToUnblockUid);
      emit(UserUnblocked());
      await loadBlockedUsers();
    } catch (e) {
      emit(ModerationError(e.toString()));
    }
  }

  // check if user is blocked
  bool isUserBlocked(String uid) {
    return _blockedUserIds.contains(uid);
  }

  // report content
  Future<void> reportContent({
    required String contentId,
    required String authorUid,
    required String reportReason,
  }) async {
    try {
      emit(ModerationLoading());
      await moderationRepo.reportContent(
        contentId: contentId,
        authorUid: authorUid,
        reportReason: reportReason,
      );
      emit(ContentReported());
    } catch (e) {
      emit(ModerationError(e.toString()));
    }
  }
}
