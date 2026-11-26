import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 3. Pick buyer or seller, add name and photo.
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: const PlaceholderBody(text: 'Buyer or seller, name, and photo go here'),
    );
  }
}
