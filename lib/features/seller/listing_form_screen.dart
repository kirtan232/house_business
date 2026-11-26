import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_body.dart';

// Screen 13. Create a new listing, or edit one when listingId is given.
class ListingFormScreen extends StatelessWidget {
  const ListingFormScreen({super.key, this.listingId});

  final String? listingId;

  @override
  Widget build(BuildContext context) {
    final editing = listingId != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit listing' : 'New listing')),
      body: const PlaceholderBody(text: 'Listing form, photos, and time slots go here'),
    );
  }
}
