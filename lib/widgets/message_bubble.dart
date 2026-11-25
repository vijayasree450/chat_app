import 'package:flutter/material.dart';

// A MessageBubble for showing a single chat message on the ChatScreen.
class MessageBubble extends StatelessWidget {
  // Create a message bubble which means that additional user details should be queried
  const MessageBubble.first({
    super.key,
    required this.userImage,
    required this.username,
    required this.message,
    required this.isMe,
    this.isEdited = false,
    this.onOptions,
  }) : isFirstInSequence = true;

  // Create a message bubble that continues the sequence.
  const MessageBubble.next({
    super.key,
    required this.message,
    required this.isMe,
    this.isEdited = false,
    this.onOptions,
  })  : isFirstInSequence = false,
        userImage = null,
        username = null;

  // Whether or not this message bubble is the first in a sequence of messages
  // from the same user.
  // Modifies the appearance.
  final bool isFirstInSequence;

  // Image of the user.
  final String? userImage;

  // Username of the user.
  // Not shown if shouldContinue is true.
  final String? username;
  final String message;

  // Controls how the MessageBubble will be aligned.
  final bool isMe;

  // Shows whether the message has been edited.
  final bool isEdited;

  // Action callback when user taps edit / options
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actionButton = onOptions != null
        ? IconButton(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.black45),
            onPressed: onOptions,
            tooltip: 'Options',
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(),
          )
        : const SizedBox.shrink();

    return Stack(
      children: [
        if (userImage != null && userImage!.isNotEmpty)
          Positioned(
            top: 15,
            // Align user image to the right, if the message is from us.
            right: isMe ? 0 : null,
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                userImage!,
              ),
              backgroundColor: theme.colorScheme.primary.withAlpha(180),
              radius: 23,
            ),
          ),
        Container(
          // Add some margin to the edges of the screen, to make room for the user's avatar.
          margin: const EdgeInsets.symmetric(horizontal: 46),
          child: Row(
            // The side of the chat screen the message should show at.
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isMe) actionButton,
              Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // First message in the sequence. Add a little space between it and the previous message.
                  if (isFirstInSequence) const SizedBox(height: 18),
                  if (username != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 13,
                        right: 13,
                      ),
                      child: Text(
                        username!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                  // The "bubble" surrounding the message.
                  GestureDetector(
                    onTap: onOptions,
                    onLongPress: onOptions,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.grey[300]
                            : theme.colorScheme.secondary.withAlpha(200),
                        // Only show the message bubble's "tail" if the message is the first in a sequence.
                        borderRadius: BorderRadius.only(
                          topLeft: !isMe && isFirstInSequence
                              ? Radius.zero
                              : const Radius.circular(12),
                          topRight: isMe && isFirstInSequence
                              ? Radius.zero
                              : const Radius.circular(12),
                          bottomLeft: const Radius.circular(12),
                          bottomRight: const Radius.circular(12),
                        ),
                      ),
                      constraints: const BoxConstraints(maxWidth: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: TextStyle(
                              height: 1.3,
                              color: isMe
                                  ? Colors.black87
                                  : theme.colorScheme.onSecondary,
                            ),
                            softWrap: true,
                          ),
                          if (isEdited)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '(edited)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: isMe
                                      ? Colors.black54
                                      : theme.colorScheme.onSecondary
                                          .withAlpha(180),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isMe) actionButton,
            ],
          ),
        ),
      ],
    );
  }
}