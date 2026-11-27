import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_business/core/router.dart';
import 'package:house_business/core/validators.dart';
import 'package:house_business/data/auth_repository.dart';
import 'package:house_business/models/app_user.dart';

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

  group('validateName', () {
    test('1 char rejected, 2 ok (boundary)', () {
      expect(validateName('A'), isNotNull);
      expect(validateName('Al'), isNull);
    });
    test('50 ok, 51 rejected (boundary)', () {
      expect(validateName('a' * 50), isNull);
      expect(validateName('a' * 51), isNotNull);
    });
  });

  group('validatePhone', () {
    test('empty is ok because phone is optional', () => expect(validatePhone(''), isNull));
    test('dashes and spaces are ok', () => expect(validatePhone('(404) 555-1234'), isNull));
    test('9 digits rejected', () => expect(validatePhone('404555123'), isNotNull));
    test('letters rejected', () => expect(validatePhone('404555abcd'), isNotNull));
  });

  test('wrong password and unknown user give the same message', () {
    expect(friendlyAuthError('wrong-password'), friendlyAuthError('user-not-found'));
    expect(friendlyAuthError('invalid-credential'), 'Wrong email or password.');
  });

  group('AppUser.fromMap', () {
    test('reads a good document', () {
      final u = AppUser.fromMap('x', {
        'name': 'Sam',
        'role': 'seller',
        'photoUrl': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 27)),
      })!;
      expect(u.isSeller, isTrue);
      expect(u.createdAt, DateTime(2026, 11, 27));
    });
    test('missing document gives null', () => expect(AppUser.fromMap('x', null), isNull));
    test('bad role gives null instead of crashing', () {
      expect(AppUser.fromMap('x', {'name': 'Sam', 'role': 'admin'}), isNull);
    });
  });

  group('authRedirect', () {
    String? go(String loc, {bool ready = true, bool signedIn = true, bool hasProfile = true}) =>
        authRedirect(ready: ready, signedIn: signedIn, hasProfile: hasProfile, location: loc);

    test('waits on splash until Firebase answers', () {
      expect(go('/splash', ready: false), isNull);
      expect(go('/browse', ready: false), '/splash');
    });
    test('signed out user is sent to login', () {
      expect(go('/saved', signedIn: false), '/login');
      expect(go('/signup', signedIn: false), isNull);
    });
    test('signed in user with no profile must finish setup', () {
      expect(go('/browse', hasProfile: false), '/profile-setup');
      expect(go('/profile-setup', hasProfile: false), isNull);
    });
    test('signed in user with a profile skips login, splash, and setup', () {
      expect(go('/login'), '/browse');
      expect(go('/splash'), '/browse');
      expect(go('/profile-setup'), '/browse');
      expect(go('/listing/abc'), isNull);
    });
  });
}
