import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 6. Photos, info, similar homes, Save / Message / Book.
class ListingDetailsScreen extends StatelessWidget {
  const ListingDetailsScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing')),
      body: PlaceholderBody(
        text: 'Details for listing $listingId',
        links: {'Message seller': () => context.push('/chat/sample-thread')},
      ),
    );
  }
}
