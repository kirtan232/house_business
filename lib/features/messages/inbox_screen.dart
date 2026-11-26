import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 9.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: PlaceholderBody(
        text: 'Your chats go here',
        links: {'Open a sample chat': () => context.push('/chat/sample-thread')},
      ),
    );
  }
}
