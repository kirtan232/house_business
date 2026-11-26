import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Small user object so screens and tests do not depend on the Firebase User class.
class AuthUser {
  const AuthUser({required this.uid, this.email});
  final String uid;
  final String? email;
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
  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  AuthUser? _toAuthUser(User? u) =>
      u == null ? null : AuthUser(uid: u.uid, email: u.email);

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

  @override
  Future<void> signOut() => _auth.signOut();

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
    default:
      return 'Something went wrong ($code). Please try again.';
  }
}
