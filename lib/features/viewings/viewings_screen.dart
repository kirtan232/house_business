import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 11. Buyers see requests, sellers confirm or decline.
class ViewingsScreen extends StatelessWidget {
  const ViewingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viewings')),
      body: const PlaceholderBody(text: 'Viewing requests go here'),
    );
  }
}
