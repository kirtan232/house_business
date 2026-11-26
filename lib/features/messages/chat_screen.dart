import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 10.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.threadId});

  final String threadId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: PlaceholderBody(text: 'Messages for thread $threadId'),
    );
  }
}
