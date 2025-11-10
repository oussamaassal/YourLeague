import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/auth/presentation/components/my_textfield.dart';
import 'package:yourleague/User/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:yourleague/User/features/chat/presentation/components/chat_bubble.dart';
import 'package:yourleague/User/features/chat/presentation/cubits/chat_cubits.dart';
import 'package:yourleague/User/features/chat/presentation/cubits/chat_states.dart';


class ChatPage extends StatefulWidget {
  // --- MODIFICATION: Add receiverUserName ---
  final String receiverUserName;
  final String receiverUserEmail;
  final String receiverUserID;

  const ChatPage({
    super.key,
    // --- MODIFICATION: Require receiverUserName ---
    required this.receiverUserName,
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  // --- FIX 1: Create a ScrollController ---
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch initial messages when the widget is first created
    _fetchMessages();
  }

  void _fetchMessages() {
    // A helper function to call getMessages
    final authCubit = context.read<AuthCubit>();
    context.read<ChatCubit>().getMessages(
      userId: authCubit.currentUser!.uid,
      otherUserId: widget.receiverUserID,
    );
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final messageText = _messageController.text;
      _messageController.clear();

      // Await the sendMessage method to ensure it completes
      await context.read<ChatCubit>().sendMessage(
        receiverUserID: widget.receiverUserID,
        message: messageText,
      );

      // After sending, refetch the messages to get the updated list
      _fetchMessages();
    }
  }

  // --- FIX 2: Create a function to scroll to the bottom ---
  void _scrollToBottom() {
    // Use addPostFrameCallback to ensure the scroll happens after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverUserName),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is! MessagesLoaded) {
          if (state is ChatError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<QuerySnapshot>(
          future: state.messages,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('Say hi!'));
            }

            // --- FIX 3: Call scrollToBottom after the list is built ---
            _scrollToBottom();

            return ListView(
              // --- FIX 4: Attach the scroll controller ---
              controller: _scrollController,
              children: docs.map((document) => _buildMessageItem(document)).toList(),
            );
          },
        );
      },
    );
  }

  // build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    final authCubit = context.read<AuthCubit>();
    final isCurrentUser = (data['senderId'] == authCubit.currentUser!.uid);

    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(data['senderEmail']),
            const SizedBox(height: 5),
            ChatBubble(
              message: data['message'],
              bubbleColor: isCurrentUser ? Colors.blue : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // build message input
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        children: [
          Expanded(
            child: MyTextfield(
              controller: _messageController,
              hintText: 'Enter message',
              obscureText: false,
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(
              Icons.send,
              color: Colors.blue,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose(); // Don't forget to dispose the controller
    super.dispose();
  }
}
