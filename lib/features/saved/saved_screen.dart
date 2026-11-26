import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 7.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved homes')),
      body: PlaceholderBody(
        text: 'Saved homes go here',
        links: {'Compare': () => context.push('/compare')},
      ),
    );
  }
}
