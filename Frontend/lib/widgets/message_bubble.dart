import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.username,
    required this.message,
    required this.isMe,
  });

  final String username;
  final String message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            IntrinsicWidth(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.3,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color.fromARGB(255, 77, 80, 90)
                      : const Color.fromARGB(255, 54, 54, 54),
                  borderRadius: BorderRadius.only(
                    topLeft: isMe ? const Radius.circular(12) : Radius.zero,
                    topRight: isMe ? Radius.zero : const Radius.circular(12),
                    bottomLeft: const Radius.circular(12),
                    bottomRight: const Radius.circular(12),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                child: textMessage(context, message),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget textMessage(BuildContext context, String text) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          username,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          textAlign: isMe ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
              fontSize: 13, color: Color.fromARGB(255, 220, 220, 220)),
          softWrap: true,
        ),
      ],
    );
  }
}
