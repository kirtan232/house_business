import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

// Thrown with a message that is ok to show on screen.
class ProfileFailure implements Exception {
  const ProfileFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class UserRepository {
  // Emits null when the user has no profile yet.
  Stream<AppUser?> watchProfile(String uid);
  Future<void> createProfile({
    required String uid,
    required String name,
    required UserRole role,
    required String? email,
    String? phone,
    Uint8List? photo,
  });
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => FirebaseUserRepository(FirebaseFirestore.instance, FirebaseStorage.instance),
);

// Profile of whoever is logged in right now. Null while logged out or before setup.
final currentProfileProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final users = ref.watch(userRepositoryProvider);
  return auth.userChanges().asyncExpand(
        (user) => user == null ? Stream.value(null) : users.watchProfile(user.uid),
      );
});

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository(this._db, this._storage);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  @override
  Stream<AppUser?> watchProfile(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots(includeMetadataChanges: true)
        // When offline with nothing cached, Firestore says "no document" even if
        // there is one on the server. Skip that so a real user isn't sent to setup again.
        .where((snap) => snap.exists || !snap.metadata.isFromCache)
        .map((snap) => AppUser.fromMap(uid, snap.data()));
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
    try {
      String? photoUrl;
      if (photo != null) {
        final ref = _storage.ref('users/$uid/profile.jpg');
        await ref.putData(photo, SettableMetadata(contentType: 'image/jpeg'));
        photoUrl = await ref.getDownloadURL();
      }

      // Public profile and private contact are written together, so you never get one without the other.
      final userDoc = _db.collection('users').doc(uid);
      final batch = _db.batch()
        ..set(userDoc, {
          'name': name,
          'role': role.name,
          'photoUrl': photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..set(userDoc.collection('private').doc('contact'), {
          'email': email,
          'phone': phone,
        });
      await batch.commit();
    } on FirebaseException catch (e) {
      debugPrint('[profile] error ${e.plugin} code=${e.code}');
      throw ProfileFailure(_friendly(e));
    }
  }

  String _friendly(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
      case 'unauthorized':
        return "You don't have permission to save this profile.";
      case 'unavailable':
      case 'retry-limit-exceeded':
        return "Can't reach the server. Check your internet connection.";
      case 'object-not-found':
      case 'bucket-not-found':
        return 'Photo storage is not set up yet. Try again without a photo.';
      default:
        return 'Could not save your profile (${e.code}). Please try again.';
    }
  }
}
