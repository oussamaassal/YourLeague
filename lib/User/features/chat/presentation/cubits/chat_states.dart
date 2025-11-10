// lib/features/chat/presentation/cubits/chat_states.dart

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatState {}

// Initial state, before any chat operations have been performed.
class ChatInitial extends ChatState {}

// Indicates that chat messages are being loaded.
class ChatLoading extends ChatState {}

// State when messages are successfully loaded. It holds a stream of messages.
class MessagesLoaded extends ChatState {
  final Stream<QuerySnapshot> messages;

  MessagesLoaded(this.messages);
}

// State when a message has been successfully sent.
class MessageSent extends ChatState {}

// Represents an error state, for example, if messages fail to load or send.
class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}
