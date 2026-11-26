import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 14. Profile and settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: PlaceholderBody(
        text: 'Profile and settings go here',
        links: {
          'My listings': () => context.push('/profile/my-listings'),
          'Log out (temporary)': () => context.go('/login'),
        },
      ),
    );
  }
}
