import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import '../data/user_repository.dart';

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

// Listens to the login state and the user's profile,
// and tells the router to check redirects again when either changes.
class SessionRefresh extends ChangeNotifier {
  SessionRefresh(AuthRepository auth, UserRepository users) {
    _authSub = auth.userChanges().listen((user) {
      _profileSub?.cancel();
      _profileSub = null;
      this.user = user;
      authReady = true;
      profileReady = user == null; // nothing to load when logged out
      hasProfile = false;
      notifyListeners();
      if (user == null) return;
      _profileSub = users.watchProfile(user.uid).listen(
        (profile) {
          hasProfile = profile != null;
          profileReady = true;
          notifyListeners();
        },
        onError: (Object e) {
          // Can't read the profile, let the setup screen show the error when saving.
          debugPrint('[router] profile read failed: $e');
          profileReady = true;
          notifyListeners();
        },
      );
    });
  }

  late final StreamSubscription<AuthUser?> _authSub;
  StreamSubscription<Object?>? _profileSub;
  AuthUser? user;
  bool authReady = false; // false until Firebase says if someone is logged in
  bool profileReady = false; // false until we know if they finished profile setup
  bool hasProfile = false;

  bool get ready => authReady && profileReady;

  @override
  void dispose() {
    _authSub.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}

// Decides where a user is allowed to be. Kept as its own function so it is easy to test.
String? authRedirect({
  required bool ready,
  required bool signedIn,
  required bool hasProfile,
  required String location,
}) {
  if (!ready) return location == '/splash' ? null : '/splash';
  if (!signedIn) return _authPages.contains(location) ? null : '/login';
  if (!hasProfile) return location == '/profile-setup' ? null : '/profile-setup';
  if (_authPages.contains(location) || location == '/splash' || location == '/profile-setup') {
    return '/browse';
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = SessionRefresh(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
  ref.onDispose(session.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (_, state) => authRedirect(
      ready: session.ready,
      signedIn: session.user != null,
      hasProfile: session.hasProfile,
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
