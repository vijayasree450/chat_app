import 'package:chatapp/widgets/chat_messages.dart';
import 'package:chatapp/widgets/new_messages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  void setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;

    // 1. Request notification permissions from the user
    await fcm.requestPermission();

    // 2. Allow foreground notifications
    await fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Subscribe this device to the 'chat' topic
    await fcm.subscribeToTopic('chat');

    // 4. Retrieve FCM token silently for notifications
    // ignore: deprecated_member_use
    final token = await fcm.getToken();
    debugPrint('FCM Token: $token');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving FCM token to Firestore: $e');
      }
    }

    // 5. Handle notifications received while app is OPEN (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      final notification = message.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${notification.title ?? 'New Message'}: ${notification.body ?? ''}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _confirmClearChat(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to delete all messages in this chat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final chatDocs =
          await FirebaseFirestore.instance.collection('chat').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in chatDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat cleared successfully.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    setupPushNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterChat'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_chat') {
                _confirmClearChat(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear_chat',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear all chat'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: const Column(
        children: [
          Expanded(child: ChatMessages()),
          NewMessages(),
        ],
      ),
    );
  }
}
