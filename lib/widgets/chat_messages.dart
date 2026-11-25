import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/widgets/message_bubble.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  void _showMessageOptions(
    BuildContext context,
    String messageId,
    String currentText,
    bool isMe,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (isMe)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit message'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(context, messageId, currentText);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(isMe ? 'Delete message' : 'Delete for everyone'),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Delete Message'),
                    content: const Text(
                      'Are you sure you want to delete this message?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await FirebaseFirestore.instance
                      .collection('chat')
                      .doc(messageId)
                      .delete();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String messageId,
    String currentText,
  ) {
    final editController = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != currentText) {
                await FirebaseFirestore.instance
                    .collection('chat')
                    .doc(messageId)
                    .update({
                  'text': newText,
                  'isEdited': true,
                });
              }
              if (context.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return const Center(child: Text('No messages found.'));
        }

        if (chatSnapshots.hasError) {
          return const Center(child: Text('Something went wrong...'));
        }

        final loadedMessages = chatSnapshots.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 40, left: 13, right: 13),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (ctx, index) {
            final messageDoc = loadedMessages[index];
            final messageId = messageDoc.id;
            final chatMessage = messageDoc.data();
            final messageText = chatMessage['text'] ?? '';
            final isEdited = chatMessage['isEdited'] == true;

            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data()
                : null;

            final currentMessageUserId = chatMessage['userId'];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage['userId'] : null;
            final nextUserIsSame = nextMessageUserId == currentMessageUserId;
            final isMe = authenticatedUser.uid == currentMessageUserId;

            Widget bubble;
            if (nextUserIsSame) {
              bubble = MessageBubble.next(
                message: messageText,
                isMe: isMe,
                isEdited: isEdited,
              );
            } else {
              bubble = MessageBubble.first(
                userImage: chatMessage['userImage'],
                username: chatMessage['username'] ?? 'User',
                message: messageText,
                isMe: isMe,
                isEdited: isEdited,
              );
            }

            return InkWell(
              onLongPress: () => _showMessageOptions(
                context,
                messageId,
                messageText,
                isMe,
              ),
              child: bubble,
            );
          },
        );
      },
    );
  }
}
