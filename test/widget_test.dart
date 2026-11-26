import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:house_business/main.dart';

void main() {
  testWidgets('Splash goes to login, then skip opens the 5 tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HouseBusinessApp()));
    expect(find.text('HouseBusiness'), findsOneWidget);

    // Splash waits 800 ms then goes to login.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsOneWidget);

    await tester.tap(find.text('Skip to app (temporary)'));
    await tester.pumpAndSettle();
    for (final tab in ['Browse', 'Saved', 'Messages', 'Viewings', 'Profile']) {
      expect(find.text(tab), findsWidgets);
    }

    // Switch to the Saved tab.
    await tester.tap(find.byIcon(Icons.favorite_outline));
    await tester.pumpAndSettle();
    expect(find.text('Saved homes'), findsOneWidget);
  });
}
