import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:go_router/go_router.dart';
import 'package:house_business/data/auth_repository.dart';
import 'package:house_business/data/geocoder.dart';
import 'package:house_business/data/listing_repository.dart';
import 'package:house_business/data/user_repository.dart';
import 'package:house_business/main.dart';
import 'package:house_business/models/app_user.dart';
import 'package:house_business/models/listing.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_listing_repository.dart';
import 'fakes/fake_user_repository.dart';

late FakeAuthRepository auth;
late FakeUserRepository users;
late FakeListingRepository listings;
late FakeGeocoder geocoder;

// buyer@test.com already has a buyer profile. New accounts have none.
Future<void> startApp(WidgetTester tester, {AuthUser? user, void Function()? seed}) async {
  auth = FakeAuthRepository(startUser: user);
  users = FakeUserRepository()
    ..addProfile('uid-buyer@test.com', 'Bob Buyer', UserRole.buyer)
    ..addProfile('u1', 'Bob Buyer', UserRole.buyer)
    ..addProfile('s1', 'Sam Seller', UserRole.seller)
    ..addProfile('s2', 'Sue Seller', UserRole.seller);
  listings = FakeListingRepository();
  geocoder = FakeGeocoder();
  seed?.call();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      userRepositoryProvider.overrideWithValue(users),
      listingRepositoryProvider.overrideWithValue(listings),
      geocoderProvider.overrideWithValue(geocoder),
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

  group('listing form', () {
    const seller = AuthUser(uid: 's1', email: 's1@test.com');

    // A tall screen so the whole form is built and every field can be found.
    void tallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Listing saved(String id, String sellerId) => Listing(
          id: id,
          sellerId: sellerId,
          status: ListingStatus.published,
          title: 'Old title',
          price: 300000,
          type: HomeType.house,
          beds: 3,
          baths: 2,
          address: '1 Oak St',
          city: 'Atlanta',
          zip: '30303',
          location: const ListingLocation(lat: 33.7, lng: -84.4, geohash: 'dn5bnzzzz'),
        );

    Future<void> openNewListing(WidgetTester tester) async {
      tallScreen(tester);
      await startApp(tester, user: seller);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tapText(tester, 'My listings');
      await tapText(tester, 'New listing');
      expect(find.text('Price'), findsOneWidget);
    }

    Future<void> openPath(WidgetTester tester, AuthUser user, String path, {void Function()? seed}) async {
      tallScreen(tester);
      await startApp(tester, user: user, seed: seed);
      GoRouter.of(tester.element(find.byType(NavigationBar))).push(path);
      await tester.pumpAndSettle();
    }

    Future<void> fillRequired(WidgetTester tester) async {
      await tester.enterText(field('Title'), 'Sunny 3 bed near the park');
      await tester.enterText(field('Price'), '350,000');
      await tester.enterText(field('Beds'), '3');
      await tester.enterText(field('Baths'), '2.5');
      await tester.enterText(field('Street address (optional)'), '12 Main St');
      await tester.enterText(field('City'), 'Atlanta');
      await tester.enterText(field('ZIP'), '30303');
    }

    testWidgets('empty form shows errors and saves nothing', (tester) async {
      await openNewListing(tester);
      await tapText(tester, 'Publish');
      expect(find.text('Enter a title.'), findsOneWidget);
      expect(find.text('Enter a price.'), findsOneWidget);
      expect(find.text('Enter the ZIP.'), findsOneWidget);
      expect(find.text('Fix the fields in red.'), findsOneWidget);
      expect(listings.listings, isEmpty);
    });

    testWidgets('seller publishes a listing', (tester) async {
      await openNewListing(tester);
      await fillRequired(tester);
      await tester.enterText(field('Sq ft'), '1600');
      await tapText(tester, 'Condo');
      await tapText(tester, 'Garage');
      await tapText(tester, 'Publish');

      final l = listings.listings.values.single;
      expect(l.sellerId, 's1');
      expect(l.status, ListingStatus.published);
      expect(l.price, 350000);
      expect(l.baths, 2.5);
      expect(l.type, HomeType.condo);
      expect(l.sqft, 1600);
      expect(l.yearBuilt, isNull);
      expect(l.amenities, ['Garage']);
      expect(l.location, isNotNull);
      expect(geocoder.lookups, ['12 Main St, Atlanta, 30303']);

      // Back on My listings with a message.
      expect(find.text('Price'), findsNothing);
      expect(find.textContaining('Listing published.'), findsOneWidget);
    });

    testWidgets('address not found on the map still saves the draft', (tester) async {
      await openNewListing(tester);
      geocoder.found = false;
      await fillRequired(tester);
      await tapText(tester, 'Save as draft');

      final l = listings.listings.values.single;
      expect(l.status, ListingStatus.draft);
      expect(l.location, isNull);
      expect(find.textContaining("couldn't find that address"), findsOneWidget);
    });

    testWidgets('offline save says it will upload later', (tester) async {
      await openNewListing(tester);
      listings.offline = true;
      await fillRequired(tester);
      await tapText(tester, 'Publish');
      expect(find.textContaining('No internet right now'), findsOneWidget);
    });

    testWidgets('server error shows a message and keeps the form', (tester) async {
      await openNewListing(tester);
      listings.failSave = true;
      await fillRequired(tester);
      await tapText(tester, 'Publish');
      expect(find.textContaining("Can't reach the server"), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
    });

    testWidgets('edit fills the form and skips the map lookup when the address is the same', (tester) async {
      await openPath(tester, seller, '/listing-form/l1',
          seed: () => listings.listings['l1'] = saved('l1', 's1'));
      expect(find.text('Edit listing'), findsOneWidget);
      expect(find.text('Old title'), findsOneWidget);
      expect(find.text('Unpublish'), findsOneWidget);

      await tester.enterText(field('Price'), '289000');
      await tapText(tester, 'Save changes');
      expect(listings.listings['l1']!.price, 289000);
      expect(listings.listings['l1']!.status, ListingStatus.published);
      expect(listings.listings['l1']!.location, isNotNull);
      expect(geocoder.lookups, isEmpty);
    });

    testWidgets("a seller can't edit someone else's listing", (tester) async {
      await openPath(tester, seller, '/listing-form/l2',
          seed: () => listings.listings['l2'] = saved('l2', 's2'));
      expect(find.text('You can only edit your own listings.'), findsOneWidget);
      expect(find.text('Save changes'), findsNothing);
    });

    testWidgets("a buyer can't open the form", (tester) async {
      await openPath(tester, const AuthUser(uid: 'u1', email: 'buyer@test.com'), '/listing-form');
      expect(find.text('Only sellers can make listings.'), findsOneWidget);
    });

    testWidgets('leaving with changes asks first', (tester) async {
      await openNewListing(tester);
      await tester.enterText(field('Title'), 'Half done');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapText(tester, 'Keep editing');
      expect(find.text('Half done'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapText(tester, 'Discard');
      expect(find.text('Price'), findsNothing);
      expect(listings.listings, isEmpty);
    });
  });
}
