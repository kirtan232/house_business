import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 8. Up to 3 saved homes side by side.
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: const PlaceholderBody(text: 'Compare table goes here'),
    );
  }
}
