import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_body.dart';
import '../../data/auth_repository.dart';

// Screen 14. Profile and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    final email = auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: PlaceholderBody(
        text: 'Logged in as $email',
        links: {
          'My listings': () => context.push('/profile/my-listings'),
          // The router sends the user back to login when this finishes.
          'Log out': () => auth.signOut(),
        },
      ),
    );
  }
}
