// lib/features/chat/presentation/cubits/chat_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repos/chat_repo.dart';
import 'chat_states.dart';

/*

THIS CUBIT HANDLES THE STATE MANAGEMENT FOR THE CHAT FEATURE!

*/

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo chatRepo;

  ChatCubit({required this.chatRepo}) : super(ChatInitial());

  // Send a message
  Future<void> sendMessage({
    required String receiverUserID,
    required String message,
  }) async {
    try {
      if (message.trim().isEmpty) {
        return; // Don't send empty messages
      }
      await chatRepo.sendMessge(receiverUserID, message);
      emit(MessageSent());
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // Get messages for a chat
  void getMessages({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      emit(ChatLoading());
      final messagesStream = chatRepo.getMessages(userId, otherUserId);
      emit(MessagesLoaded(messagesStream));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }
}
