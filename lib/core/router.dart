import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

// The router is a provider so in Step 5 it can watch the login state
// and send signed out users to /login.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
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
