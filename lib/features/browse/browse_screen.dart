import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 4. Feed of published listings.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        actions: [
          IconButton(
            tooltip: 'Search and filters',
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/browse/search'),
          ),
        ],
      ),
      body: PlaceholderBody(
        text: 'Listings feed goes here',
        links: {'Open a sample listing': () => context.push('/listing/sample')},
      ),
    );
  }
}
