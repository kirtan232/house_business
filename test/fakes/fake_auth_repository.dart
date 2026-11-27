import 'dart:async';

import 'package:house_business/data/auth_repository.dart';

// In-memory login used by widget tests so they don't need Firebase.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? startUser}) : _user = startUser;

  final _controller = StreamController<AuthUser?>.broadcast();
  final Map<String, String> accounts = {'buyer@test.com': 'secret1'};
  AuthUser? _user;
  final List<String> resetEmails = [];
  bool offline = false;

  @override
  Stream<AuthUser?> userChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _user;

  void _set(AuthUser? u) {
    _user = u;
    _controller.add(u);
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (offline) throw AuthFailure(friendlyAuthError('network-request-failed'));
    if (accounts[email] != password) {
      throw AuthFailure(friendlyAuthError('invalid-credential'));
    }
    _set(AuthUser(uid: 'uid-$email', email: email));
  }

  @override
  Future<void> signUp(String email, String password) async {
    if (accounts.containsKey(email)) {
      throw AuthFailure(friendlyAuthError('email-already-in-use'));
    }
    accounts[email] = password;
    _set(AuthUser(uid: 'uid-$email', email: email));
  }

  @override
  Future<void> sendPasswordReset(String email) async => resetEmails.add(email);

  // What the fake Google picker does: 'ok', 'cancel', or 'error'.
  String googleResult = 'ok';

  @override
  Future<void> signInWithGoogle() async {
    if (googleResult == 'cancel') return;
    if (googleResult == 'error') {
      throw const AuthFailure('Google sign in failed. Please try again.');
    }
    _set(const AuthUser(uid: 'uid-google', email: 'google@test.com', displayName: 'Gina Google'));
  }

  @override
  Future<void> signOut() async => _set(null);
}
