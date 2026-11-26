import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';

import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/browse/browse_screen.dart';
import '../features/browse/search_screen.dart';
import '../features/listing/listing_details_screen.dart';
import '../features/messages/chat_screen.dart';
import '../features/messages/inbox_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/profile_setup_screen.dart';
import '../features/saved/compare_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/seller/listing_form_screen.dart';
import '../features/seller/my_listings_screen.dart';
import '../features/viewings/viewings_screen.dart';
import 'home_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

// Pages you can open without logging in.
const _authPages = {'/login', '/signup', '/forgot-password'};

// Listens to the login state and tells the router to check redirects again.
class AuthRefresh extends ChangeNotifier {
  AuthRefresh(Stream<AuthUser?> userChanges) {
    _sub = userChanges.listen((user) {
      this.user = user;
      ready = true;
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthUser?> _sub;
  AuthUser? user;
  bool ready = false; // false until Firebase says if someone is logged in

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// Decides where a user is allowed to be. Kept as its own function so it is easy to test.
String? authRedirect({required bool ready, required bool signedIn, required String location}) {
  if (!ready) return location == '/splash' ? null : '/splash';
  if (!signedIn) return _authPages.contains(location) ? null : '/login';
  if (_authPages.contains(location) || location == '/splash') return '/browse';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = AuthRefresh(ref.watch(authRepositoryProvider).userChanges());
  ref.onDispose(auth.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (_, state) => authRedirect(
      ready: auth.ready,
      signedIn: auth.user != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/profile-setup', builder: (_, _) => const ProfileSetupScreen()),

      // Full screen pages that open on top of the bottom bar.
      // Notifications will deep link straight to /listing/:id and /chat/:threadId.
      GoRoute(
        path: '/listing/:id',
        builder: (_, state) => ListingDetailsScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat/:threadId',
        builder: (_, state) => ChatScreen(threadId: state.pathParameters['threadId']!),
      ),
      GoRoute(path: '/compare', builder: (_, _) => const CompareScreen()),
      GoRoute(path: '/listing-form', builder: (_, _) => const ListingFormScreen()),
      GoRoute(
        path: '/listing-form/:id',
        builder: (_, state) => ListingFormScreen(listingId: state.pathParameters['id']),
      ),

      // The 5 bottom tabs.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/browse',
              builder: (_, _) => const BrowseScreen(),
              routes: [
                GoRoute(path: 'search', builder: (_, _) => const SearchScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/messages', builder: (_, _) => const InboxScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/viewings', builder: (_, _) => const ViewingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'my-listings', builder: (_, _) => const MyListingsScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
