import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:house_business/data/auth_repository.dart';
import 'package:house_business/data/user_repository.dart';
import 'package:house_business/main.dart';
import 'package:house_business/models/app_user.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_user_repository.dart';

late FakeAuthRepository auth;
late FakeUserRepository users;

// buyer@test.com already has a buyer profile. New accounts have none.
Future<void> startApp(WidgetTester tester, {AuthUser? user}) async {
  auth = FakeAuthRepository(startUser: user);
  users = FakeUserRepository()
    ..addProfile('uid-buyer@test.com', 'Bob Buyer', UserRole.buyer)
    ..addProfile('u1', 'Bob Buyer', UserRole.buyer)
    ..addProfile('s1', 'Sam Seller', UserRole.seller);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      userRepositoryProvider.overrideWithValue(users),
    ],
    child: const HouseBusinessApp(),
  ));
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> logIn(WidgetTester tester) async {
  await tester.enterText(field('Email'), 'buyer@test.com');
  await tester.enterText(field('Password'), 'secret1');
  await tapText(tester, 'Log in');
}

const browseText = 'Listings feed goes here';
const setupTitle = 'Set up your profile';

void main() {
  group('login', () {
    testWidgets('signed out user lands on login', (tester) async {
      await startApp(tester);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('already logged in user goes straight to Browse', (tester) async {
      await startApp(tester, user: const AuthUser(uid: 'u1', email: 'buyer@test.com'));
      expect(find.text(browseText), findsOneWidget);
    });

    testWidgets('empty login form shows field errors', (tester) async {
      await startApp(tester);
      await tapText(tester, 'Log in');
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('wrong password shows a friendly error and stays on login', (tester) async {
      await startApp(tester);
      await tester.enterText(field('Email'), 'buyer@test.com');
      await tester.enterText(field('Password'), 'nope');
      await tapText(tester, 'Log in');
      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('no internet shows a connection message', (tester) async {
      await startApp(tester);
      auth.offline = true;
      await logIn(tester);
      expect(find.textContaining("Can't reach the server"), findsOneWidget);
    });

    testWidgets('good login opens the app, log out goes back', (tester) async {
      await startApp(tester);
      await logIn(tester);
      expect(find.text(browseText), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tapText(tester, 'Log out');
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('forgot password sends the email and shows a neutral message', (tester) async {
      await startApp(tester);
      await tapText(tester, 'Forgot password?');
      await tester.enterText(field('Email'), 'someone@test.com');
      await tapText(tester, 'Send reset link');
      expect(auth.resetEmails, ['someone@test.com']);
      expect(find.textContaining('If that email has an account'), findsOneWidget);
    });
  });

  group('sign up', () {
    testWidgets('checks passwords match, then goes to profile setup', (tester) async {
      await startApp(tester);
      await tapText(tester, 'New here? Create an account');

      await tester.enterText(field('Email'), 'new@test.com');
      await tester.enterText(field('Password'), 'abcdef');
      await tester.enterText(field('Confirm password'), 'abcdeg');
      await tapText(tester, 'Create account');
      expect(find.text("Passwords don't match."), findsOneWidget);

      await tester.enterText(field('Confirm password'), 'abcdef');
      await tapText(tester, 'Create account');
      expect(find.text(setupTitle), findsOneWidget);
    });

    testWidgets('used email shows an error', (tester) async {
      await startApp(tester);
      await tapText(tester, 'New here? Create an account');
      await tester.enterText(field('Email'), 'buyer@test.com');
      await tester.enterText(field('Password'), 'abcdef');
      await tester.enterText(field('Confirm password'), 'abcdef');
      await tapText(tester, 'Create account');
      expect(find.textContaining('already exists'), findsOneWidget);
    });
  });

  group('google', () {
    testWidgets('new Google user goes to setup with name filled in', (tester) async {
      await startApp(tester);
      await tapText(tester, 'Continue with Google');
      expect(find.text(setupTitle), findsOneWidget);
      expect(find.text('Gina Google'), findsOneWidget);
    });

    testWidgets('closing the Google picker stays on login with no error', (tester) async {
      await startApp(tester);
      auth.googleResult = 'cancel';
      await tapText(tester, 'Continue with Google');
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.textContaining('failed'), findsNothing);
    });

    testWidgets('Google error shows a message', (tester) async {
      await startApp(tester);
      auth.googleResult = 'error';
      await tapText(tester, 'Continue with Google');
      expect(find.text('Google sign in failed. Please try again.'), findsOneWidget);
    });
  });

  group('profile setup', () {
    Future<void> openSetup(WidgetTester tester) async {
      await startApp(tester, user: const AuthUser(uid: 'new1', email: 'new@test.com'));
      expect(find.text(setupTitle), findsOneWidget);
    }

    testWidgets('logged in user with no profile cannot skip setup', (tester) async {
      await openSetup(tester);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('must pick a role and enter a name', (tester) async {
      await openSetup(tester);
      await tapText(tester, 'Save and continue');
      expect(find.text('Pick buyer or seller.'), findsOneWidget);
      expect(find.text('Enter your name.'), findsOneWidget);
      expect(users.profiles.containsKey('new1'), isFalse);
    });

    testWidgets('bad phone number is rejected', (tester) async {
      await openSetup(tester);
      await tapText(tester, 'Buy a home');
      await tester.enterText(field('Your name'), 'Nia');
      await tester.enterText(field('Phone (optional)'), '12345');
      await tapText(tester, 'Save and continue');
      expect(find.text('Enter a 10 digit phone number.'), findsOneWidget);
    });

    testWidgets('seller saves profile, opens app, and sees My listings', (tester) async {
      await openSetup(tester);
      await tapText(tester, 'Sell a home');
      await tester.enterText(field('Your name'), 'Nia Seller');
      await tester.enterText(field('Phone (optional)'), '404-555-1234');
      await tapText(tester, 'Save and continue');

      expect(find.text(browseText), findsOneWidget);
      expect(users.profiles['new1']!.role, UserRole.seller);
      expect(users.contacts['new1'], {'email': 'new@test.com', 'phone': '404-555-1234'});

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Nia Seller'), findsOneWidget);
      expect(find.text('My listings'), findsOneWidget);
    });

    testWidgets('buyer does not see My listings', (tester) async {
      await startApp(tester, user: const AuthUser(uid: 'u1', email: 'buyer@test.com'));
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Buyer'), findsOneWidget);
      expect(find.text('My listings'), findsNothing);
    });

    testWidgets('save failure shows a message and stays on setup', (tester) async {
      await openSetup(tester);
      users.failSave = true;
      await tapText(tester, 'Buy a home');
      await tester.enterText(field('Your name'), 'Nia');
      await tapText(tester, 'Save and continue');
      expect(find.textContaining("Can't reach the server"), findsOneWidget);
      expect(find.text(setupTitle), findsOneWidget);
    });
  });
}
