import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 2c.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: const PlaceholderBody(text: 'Enter your email to get a reset link'),
    );
  }
}
