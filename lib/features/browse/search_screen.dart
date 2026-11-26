import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 5. City or ZIP, price, type, beds, amenities.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search and filters')),
      body: const PlaceholderBody(text: 'Filters go here'),
    );
  }
}
