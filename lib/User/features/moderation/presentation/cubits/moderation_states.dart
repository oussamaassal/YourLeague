import '../../domain/entities/blocked_user.dart';

abstract class ModerationState {}

class ModerationInitial extends ModerationState {}

class ModerationLoading extends ModerationState {}

class BlockedUsersLoaded extends ModerationState {
  final List<BlockedUser> blockedUsers;
  final List<String> blockedUserIds;

  BlockedUsersLoaded(this.blockedUsers)
      : blockedUserIds = blockedUsers.map((user) => user.blockedUid).toList();
}

class UserBlocked extends ModerationState {}

class UserUnblocked extends ModerationState {}

class ContentReported extends ModerationState {}

class ModerationError extends ModerationState {
  final String message;

  ModerationError(this.message);
}
