import '../entities/blocked_user.dart';

abstract class ModerationRepo {
  // blocking functionality
  Future<void> blockUser(String userToBlockUid, String userToBlockEmail);
  Future<void> unblockUser(String userToUnblockUid);
  Future<List<BlockedUser>> getBlockedUsers();
  Future<bool> isUserBlocked(String uid);

  // content moderation functionality
  Future<void> reportContent({
    required String contentId,
    required String authorUid,
    required String reportReason,
  });
}
