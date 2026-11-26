import 'package:flutter/material.dart';

// Temporary body for screens that are not built yet.
// Each link is a button so the navigation can be tested before the real screens exist.
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({
    super.key,
    required this.text,
    this.links = const {},
  });

  final String text;
  final Map<String, VoidCallback> links;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            for (final link in links.entries)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(
                  onPressed: link.value,
                  child: Text(link.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
