import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_repository.dart';
import '../../data/user_repository.dart';

// Screen 14. Profile and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundImage: profile?.photoUrl == null ? null : NetworkImage(profile!.photoUrl!),
              child: profile?.photoUrl == null ? const Icon(Icons.person, size: 44) : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(profile?.name ?? '', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          Text(auth.currentUser?.email ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (profile != null)
            Center(child: Chip(label: Text(profile.isSeller ? 'Seller' : 'Buyer'))),
          const SizedBox(height: 16),
          if (profile?.isSeller ?? false)
            ListTile(
              leading: const Icon(Icons.home_work_outlined),
              title: const Text('My listings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/my-listings'),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            // The router sends the user back to login when this finishes.
            onTap: () => auth.signOut(),
          ),
        ],
      ),
    );
  }
}
