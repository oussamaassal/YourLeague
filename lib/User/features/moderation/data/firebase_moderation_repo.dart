import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/blocked_user.dart';
import '../domain/repos/moderation_repo.dart';

class FirebaseModerationRepo implements ModerationRepo {
  // access firebase
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // BLOCK USER
  @override
  Future<void> blockUser(String userToBlockUid, String userToBlockEmail) async {
    // get current user
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("No user logged in");

    // create unique block record ID (combine currentuid + blockeduid)
    final String blockId = '${currentUser.uid}_$userToBlockUid';

    // create blocked user entry
    final blockUser = BlockedUser(
      id: blockId,
      blockerUid: currentUser.uid,
      blockedUid: userToBlockUid,
      blockedEmail: userToBlockEmail,
    );

    // save in firebase
    await _firestore
        .collection("users")
        .doc(currentUser.uid)
        .collection("blocked_users")
        .doc(blockId)
        .set(blockUser.toJson());
  }

  // UNBLOCK USER
  @override
  Future<void> unblockUser(String userToUnblockUid) async {
    // get current user
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("No user logged in");

    // create block record ID to delete
    final String blockId = '${currentUser.uid}_$userToUnblockUid';

    // delete from firestore
    await _firestore
        .collection("users")
        .doc(currentUser.uid)
        .collection("blocked_users")
        .doc(blockId)
        .delete();
  }

  // GET BLOCKED USERS
  @override
  Future<List<BlockedUser>> getBlockedUsers() async {
    // get current user
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    // fetch blocked users
    final snapshot = await _firestore
        .collection("users")
        .doc(currentUser.uid)
        .collection("blocked_users")
        .get();

    // return as list
    final blockedUsersList =
        snapshot.docs.map((doc) => BlockedUser.fromJson(doc.data())).toList();

    return blockedUsersList;
  }

  // IS USER BLOCKED?
  @override
  Future<bool> isUserBlocked(String uid) async {
    // get current user
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    // create block record ID
    final String blockId = '${currentUser.uid}_$uid';

    // check if exists
    final doc = await _firestore
        .collection("users")
        .doc(currentUser.uid)
        .collection("blocked_users")
        .doc(blockId)
        .get();

    final bool isUserBlocked = doc.exists;

    return isUserBlocked;
  }

  // REPORTING CONTENT
  @override
  Future<void> reportContent(
      {required String contentId,
      required String authorUid,
      required String reportReason}) async {
    // get current user
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("No user logged in");

    // create unique report id
    final String reportId = '${currentUser.uid}_$contentId';

    // create report data
    final reportData = {
      'id': reportId,
      'contentId': contentId,
      'authorUId': authorUid,
      'reporterUid': currentUser.uid,
      'reason': reportReason,
      'reportedAt': FieldValue.serverTimestamp(),
    };

    // save in firebase
    await _firestore
        .collection("content_reports")
        .doc(reportId)
        .set(reportData);
  }
}
