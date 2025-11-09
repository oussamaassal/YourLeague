import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  // Renamed to 'toJson' for convention, same as 'toMap'
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
    };
  }

  // --- ADD THIS FACTORY CONSTRUCTOR ---
  // Creates a Message object from a Firestore document map
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId: json['senderId'],
      senderEmail: json['senderEmail'],
      receiverId: json['receiverId'],
      message: json['message'],
      timestamp: json['timestamp'],
    );
  }
}
