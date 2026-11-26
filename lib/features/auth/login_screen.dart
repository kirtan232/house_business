import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 2a. Real form comes in Step 5.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: PlaceholderBody(
        text: 'Login form goes here',
        links: {
          'Skip to app (temporary)': () => context.go('/browse'),
          'Sign up': () => context.push('/signup'),
          'Forgot password': () => context.push('/forgot-password'),
          'Profile setup': () => context.push('/profile-setup'),
        },
      ),
    );
  }
}
