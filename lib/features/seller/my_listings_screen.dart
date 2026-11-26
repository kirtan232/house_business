import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 12. Drafts, published, archived.
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listing-form'),
        icon: const Icon(Icons.add),
        label: const Text('New listing'),
      ),
      body: const PlaceholderBody(text: 'Your listings go here'),
    );
  }
}
