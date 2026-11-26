import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:house_business/data/auth_repository.dart';
import 'package:house_business/main.dart';

import 'fakes/fake_auth_repository.dart';

Future<FakeAuthRepository> startApp(WidgetTester tester, {AuthUser? user}) async {
  final fake = FakeAuthRepository(startUser: user);
  await tester.pumpWidget(ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
    child: const HouseBusinessApp(),
  ));
  await tester.pumpAndSettle();
  return fake;
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('signed out user lands on login', (tester) async {
    await startApp(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('already logged in user goes straight to Browse', (tester) async {
    await startApp(tester, user: const AuthUser(uid: 'u1', email: 'buyer@test.com'));
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Listings feed goes here'), findsOneWidget);
  });

  testWidgets('empty login form shows field errors', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('wrong password shows a friendly error and stays on login', (tester) async {
    await startApp(tester);
    await tester.enterText(field('Email'), 'buyer@test.com');
    await tester.enterText(field('Password'), 'nope');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('no internet shows a connection message', (tester) async {
    final fake = await startApp(tester);
    fake.offline = true;
    await tester.enterText(field('Email'), 'buyer@test.com');
    await tester.enterText(field('Password'), 'secret1');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Can't reach the server"), findsOneWidget);
  });

  testWidgets('good login opens the app, log out goes back', (tester) async {
    await startApp(tester);
    await tester.enterText(field('Email'), 'buyer@test.com');
    await tester.enterText(field('Password'), 'secret1');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Listings feed goes here'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('sign up checks passwords match, then creates the account', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Email'), 'new@test.com');
    await tester.enterText(field('Password'), 'abcdef');
    await tester.enterText(field('Confirm password'), 'abcdeg');
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text("Passwords don't match."), findsOneWidget);

    await tester.enterText(field('Confirm password'), 'abcdef');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Listings feed goes here'), findsOneWidget);
  });

  testWidgets('sign up with a used email shows an error', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Email'), 'buyer@test.com');
    await tester.enterText(field('Password'), 'abcdef');
    await tester.enterText(field('Confirm password'), 'abcdef');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('already exists'), findsOneWidget);
  });

  testWidgets('Continue with Google logs in', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Listings feed goes here'), findsOneWidget);
  });

  testWidgets('closing the Google picker stays on login with no error', (tester) async {
    final fake = await startApp(tester);
    fake.googleResult = 'cancel';
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.textContaining('failed'), findsNothing);
  });

  testWidgets('Google error shows a message', (tester) async {
    final fake = await startApp(tester);
    fake.googleResult = 'error';
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Google sign in failed. Please try again.'), findsOneWidget);
  });

  testWidgets('forgot password sends the email and shows a neutral message', (tester) async {
    final fake = await startApp(tester);
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Email'), 'someone@test.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(fake.resetEmails, ['someone@test.com']);
    expect(find.textContaining('If that email has an account'), findsOneWidget);
  });
}
