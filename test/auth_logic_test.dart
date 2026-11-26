import 'package:flutter_test/flutter_test.dart';
import 'package:house_business/core/router.dart';
import 'package:house_business/core/validators.dart';
import 'package:house_business/data/auth_repository.dart';

void main() {
  group('validateEmail', () {
    test('empty is rejected', () => expect(validateEmail('  '), 'Enter your email.'));
    test('missing dot is rejected', () => expect(validateEmail('a@b'), isNotNull));
    test('spaces are trimmed', () => expect(validateEmail('  kim@test.com '), isNull));
  });

  group('validatePassword', () {
    test('empty is rejected', () => expect(validatePassword(''), isNotNull));
    test('short is ok on login', () => expect(validatePassword('abc'), isNull));
    test('5 chars rejected on sign up', () => expect(validatePassword('abcde', isNew: true), isNotNull));
    test('6 chars ok on sign up (boundary)', () => expect(validatePassword('abcdef', isNew: true), isNull));
  });

  test('confirm password must match', () {
    expect(validateConfirmPassword('abc123', 'abc124'), "Passwords don't match.");
    expect(validateConfirmPassword('abc123', 'abc123'), isNull);
  });

  test('wrong password and unknown user give the same message', () {
    expect(friendlyAuthError('wrong-password'), friendlyAuthError('user-not-found'));
    expect(friendlyAuthError('invalid-credential'), 'Wrong email or password.');
  });

  group('authRedirect', () {
    test('waits on splash until Firebase answers', () {
      expect(authRedirect(ready: false, signedIn: false, location: '/splash'), isNull);
      expect(authRedirect(ready: false, signedIn: false, location: '/browse'), '/splash');
    });
    test('signed out user is sent to login', () {
      expect(authRedirect(ready: true, signedIn: false, location: '/saved'), '/login');
      expect(authRedirect(ready: true, signedIn: false, location: '/signup'), isNull);
    });
    test('signed in user skips login and splash', () {
      expect(authRedirect(ready: true, signedIn: true, location: '/login'), '/browse');
      expect(authRedirect(ready: true, signedIn: true, location: '/splash'), '/browse');
      expect(authRedirect(ready: true, signedIn: true, location: '/listing/abc'), isNull);
    });
  });
}
