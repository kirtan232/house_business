import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing.dart';

// Thrown with a message that is ok to show on screen.
class ListingFailure implements Exception {
  const ListingFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class ListingRepository {
  // A new ID before saving, so photos can be uploaded to the right folder first.
  String newListingId();

  Future<Listing?> getListing(String id);

  // Both return true when the server saved it, false when there is no internet and
  // Firestore kept it on the phone to send later.
  Future<bool> createListing(Listing listing);
  Future<bool> updateListing(Listing listing);
}

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => FirebaseListingRepository(FirebaseFirestore.instance),
);

class FirebaseListingRepository implements ListingRepository {
  FirebaseListingRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _listings => _db.collection('listings');

  // How long to wait for the server before saying it will upload later.
  static const _serverWait = Duration(seconds: 10);

  @override
  String newListingId() => _listings.doc().id;

  @override
  Future<Listing?> getListing(String id) async {
    try {
      final snap = await _listings.doc(id).get();
      return Listing.fromMap(snap.id, snap.data());
    } on FirebaseException catch (e) {
      debugPrint('[listings] read $id failed: ${e.code}');
      // The rules hide drafts from everyone but the owner, and a missing listing looks the same.
      if (e.code == 'permission-denied') return null;
      throw ListingFailure(_friendly(e));
    }
  }

  @override
  Future<bool> createListing(Listing listing) {
    final id = listing.id ?? newListingId();
    return _write(_listings.doc(id).set({
      ...listing.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }));
  }

  @override
  Future<bool> updateListing(Listing listing) {
    // createdAt is left alone. The rules check it doesn't change.
    return _write(_listings.doc(listing.id).update({
      ...listing.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }));
  }

  Future<bool> _write(Future<void> write) async {
    try {
      await write.timeout(_serverWait);
      return true;
    } on TimeoutException {
      return false; // still queued, Firestore sends it when the internet is back
    } on FirebaseException catch (e) {
      debugPrint('[listings] write failed: ${e.code} ${e.message}');
      throw ListingFailure(_friendly(e));
    }
  }

  String _friendly(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return "You can't save this listing. Only the seller who made it can change it.";
      case 'unavailable':
        return "Can't reach the server. Check your internet connection.";
      default:
        return 'Could not save the listing (${e.code}). Please try again.';
    }
  }
}
