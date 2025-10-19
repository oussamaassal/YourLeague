/*

AUTH REPOSITORY - Outlines the possible auth operations for this app.

*/

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatRepo {
  Future<void> sendMessge(String receiverId, String message);
  Future<QuerySnapshot> getMessages(String userId, String otherUserId);
}
