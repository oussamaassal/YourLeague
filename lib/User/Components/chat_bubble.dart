import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final Color bubbleColor;
  const ChatBubble({
    super.key,
    required this.message,
    required this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bubbleColor,
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
