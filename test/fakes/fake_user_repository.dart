import 'dart:async';
import 'dart:typed_data';

import 'package:house_business/data/user_repository.dart';
import 'package:house_business/models/app_user.dart';

// In-memory profiles used by widget tests so they don't need Firestore.
class FakeUserRepository implements UserRepository {
  final Map<String, AppUser> profiles = {};
  final Map<String, Map<String, String?>> contacts = {};
  final _changes = StreamController<String>.broadcast();
  bool failSave = false;

  void addProfile(String uid, String name, UserRole role) =>
      profiles[uid] = AppUser(uid: uid, name: name, role: role);

  @override
  Stream<AppUser?> watchProfile(String uid) async* {
    yield profiles[uid];
    yield* _changes.stream.where((u) => u == uid).map((_) => profiles[uid]);
  }

  @override
  Future<void> createProfile({
    required String uid,
    required String name,
    required UserRole role,
    required String? email,
    String? phone,
    Uint8List? photo,
  }) async {
    if (failSave) {
      throw const ProfileFailure("Can't reach the server. Check your internet connection.");
    }
    profiles[uid] = AppUser(uid: uid, name: name, role: role);
    contacts[uid] = {'email': email, 'phone': phone};
    _changes.add(uid);
  }
}
