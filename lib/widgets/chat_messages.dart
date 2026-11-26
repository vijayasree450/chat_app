import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit message'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(context, messageId, currentText);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: currentText));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete message'),
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
                  try {
                    await FirebaseFirestore.instance
                        .collection('chat')
                        .doc(messageId)
                        .delete();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message deleted.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting message: $e')),
                      );
                    }
                  }
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
    editController.selection = TextSelection.fromPosition(
      TextPosition(offset: editController.text.length),
    );
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Message'),
            ],
          ),
          content: TextField(
            controller: editController,
            autofocus: true,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final newText = editController.text.trim();
                      if (newText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message cannot be empty.'),
                          ),
                        );
                        return;
                      }

                      if (newText == currentText) {
                        Navigator.pop(dialogCtx);
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        await FirebaseFirestore.instance
                            .collection('chat')
                            .doc(messageId)
                            .update({'text': newText, 'isEdited': true});

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Message updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (error) {
                        setDialogState(() {
                          isSaving = false;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser;

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
            final nextMessageUserId = nextChatMessage != null
                ? nextChatMessage['userId']
                : null;
            final nextUserIsSame = nextMessageUserId == currentMessageUserId;
            final isMe = authenticatedUser?.uid == currentMessageUserId;

            void showOptions() {
              _showMessageOptions(context, messageId, messageText, isMe);
            }

            if (nextUserIsSame) {
              return MessageBubble.next(
                message: messageText,
                isMe: isMe,
                isEdited: isEdited,
                onOptions: showOptions,
              );
            } else {
              return MessageBubble.first(
                userImage: chatMessage['userImage'],
                username: chatMessage['username'] ?? 'User',
                message: messageText,
                isMe: isMe,
                isEdited: isEdited,
                onOptions: showOptions,
              );
            }
          },
        );
      },
    );
  }
}
