import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 2b.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: const PlaceholderBody(text: 'Sign up form goes here'),
    );
  }
}
