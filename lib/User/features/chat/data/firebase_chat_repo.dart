import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yourleague/User/features/chat/domain/entities/message.dart';
import 'package:yourleague/User/features/chat/domain/repos/chat_repo.dart';


class FirebaseChatRepo implements ChatRepo {
  // get instance of auth and firestore
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //SEND MESSAGE
  @override
  Future<void> sendMessge(String receiverId, String message) async {
    // get the current user info
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    // 2. Fetch the receiver's user document from the 'users' collection
    DocumentSnapshot receiverDoc =
    await _firestore.collection('users').doc(receiverId).get();

    // Check if the document exists to avoid errors
    if (!receiverDoc.exists) {
      throw Exception("Receiver user not found in the database.");
    }
    // Extract the email from the document data
    final String receiverEmail = receiverDoc.get('email');

    // create a new message using the Message entity
    final Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      receiverEmail: receiverEmail,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room id from current user id and receiver id (sorted to ensure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); // sort the ids to ensure the chat room id is always the same for any pair
    String chatRoomId = ids.join("_");

    // add new message to database using the toJson() method
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toJson()); // <-- Use .toJson() here
  }

  // GET THE MESSAGES
  @override
  Future<QuerySnapshot> getMessages(String userId, String otherUserId) async {
    // construct chat room id from user ids (sorted to ensure it matches the id used when sending)
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // Use .get() to fetch the documents once as a Future
    return await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();
  }

  // NOUVELLE METHODE: Stream temps réel des messages
  @override
  Stream<QuerySnapshot> getMessagesStream(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

}
