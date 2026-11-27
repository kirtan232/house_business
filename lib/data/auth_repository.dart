import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Small user object so screens and tests do not depend on the Firebase User class.
class AuthUser {
  const AuthUser({required this.uid, this.email, this.displayName});
  final String uid;
  final String? email;
  final String? displayName; // filled in by Google sign in
}

// Thrown by the repository with a message that is ok to show on screen.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AuthRepository {
  Stream<AuthUser?> userChanges();
  AuthUser? get currentUser;
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> sendPasswordReset(String email);
  // Does nothing if the user closes the Google account picker.
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  AuthUser? _toAuthUser(User? u) =>
      u == null ? null : AuthUser(uid: u.uid, email: u.email, displayName: u.displayName);

  @override
  Stream<AuthUser?> userChanges() => _auth.authStateChanges().map(_toAuthUser);

  @override
  AuthUser? get currentUser => _toAuthUser(_auth.currentUser);

  @override
  Future<void> signIn(String email, String password) => _run(
        () => _auth.signInWithEmailAndPassword(email: email, password: password),
      );

  @override
  Future<void> signUp(String email, String password) => _run(
        () => _auth.createUserWithEmailAndPassword(email: email, password: password),
      );

  @override
  Future<void> sendPasswordReset(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email));

  // On Android the Google plugin reads the web client ID from google-services.json,
  // so no ID is written in the code.
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _googleReady = false;

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (!_googleReady) {
        await _google.initialize();
        _googleReady = true;
      }
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google did not send a sign in token. Please try again.');
      }
      await _run(() => _auth.signInWithCredential(
            GoogleAuthProvider.credential(idToken: idToken),
          ));
    } on GoogleSignInException catch (e) {
      // Closing the account picker is not an error.
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      debugPrint('[auth] google error code=${e.code.name}');
      throw AuthFailure(friendlyGoogleError(e.code));
    }
  }

  @override
  Future<void> signOut() async {
    // Also sign out of Google so the account picker shows next time.
    if (_googleReady) await _google.signOut();
    await _auth.signOut();
  }

  Future<void> _run(Future<Object?> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      // Only the error code is logged, never the email or password.
      debugPrint('[auth] error code=${e.code}');
      throw AuthFailure(friendlyAuthError(e.code));
    }
  }
}

// Turns Firebase error codes into plain messages for the user.
String friendlyAuthError(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'user-not-found':
    case 'wrong-password':
      return 'Wrong email or password.';
    case 'email-already-in-use':
      return 'An account with that email already exists. Try logging in.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'user-disabled':
      return 'This account has been turned off.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a moment and try again.';
    case 'network-request-failed':
      return "Can't reach the server. Check your internet connection.";
    case 'operation-not-allowed':
      return 'This sign in method is not turned on in Firebase.';
    case 'account-exists-with-different-credential':
      return 'This email already has an account. Log in with your password.';
    default:
      return 'Something went wrong ($code). Please try again.';
  }
}

String friendlyGoogleError(GoogleSignInExceptionCode code) {
  switch (code) {
    case GoogleSignInExceptionCode.clientConfigurationError:
    case GoogleSignInExceptionCode.providerConfigurationError:
      return 'Google sign in is not set up right for this app yet.';
    case GoogleSignInExceptionCode.uiUnavailable:
      return 'Google sign in could not open. Make sure a Google account is on this phone.';
    case GoogleSignInExceptionCode.interrupted:
      return 'Google sign in was interrupted. Please try again.';
    default:
      return 'Google sign in failed. Please try again.';
  }
}
