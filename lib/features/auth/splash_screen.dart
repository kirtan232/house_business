import 'package:flutter/material.dart';

// Screen 1. Shows while Firebase checks if the user is already logged in.
// The router moves away from here as soon as it knows.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.house_rounded, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('HouseBusiness', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
