import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'listing_repository.dart';

// A photo picked from the gallery that hasn't been uploaded yet.
class PickedPhoto {
  const PickedPhoto(this.bytes, this.contentType);
  final Uint8List bytes;
  final String contentType;
}

const maxListingPhotos = 12;
const maxPhotoBytes = 5 * 1024 * 1024; // same limit as storage.rules

// Opens the gallery. Kept separate so widget tests can fake it.
abstract class PhotoPicker {
  Future<List<PickedPhoto>> pickMany({required int limit});
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => GalleryPhotoPicker());

class GalleryPhotoPicker implements PhotoPicker {
  @override
  Future<List<PickedPhoto>> pickMany({required int limit}) async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 1600, // big enough for a phone screen, small enough to upload fast
      imageQuality: 80,
      limit: limit >= 2 ? limit : null, // the picker needs at least 2 here
    );
    return [
      for (final f in files.take(limit)) PickedPhoto(await f.readAsBytes(), _typeOf(f.name)),
    ];
  }

  String _typeOf(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

abstract class PhotoRepository {
  // Returns the download URL.
  Future<String> uploadListingPhoto({
    required String sellerId,
    required String listingId,
    required PickedPhoto photo,
  });

  // Best effort. A leftover file is not worth an error on screen.
  Future<void> delete(String url);
}

final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => FirebasePhotoRepository(FirebaseStorage.instance),
);

class FirebasePhotoRepository implements PhotoRepository {
  FirebasePhotoRepository(this._storage) {
    // The default is 10 minutes of retrying, which looks frozen with no internet.
    _storage.setMaxUploadRetryTime(const Duration(seconds: 30));
  }
  final FirebaseStorage _storage;

  @override
  Future<String> uploadListingPhoto({
    required String sellerId,
    required String listingId,
    required PickedPhoto photo,
  }) async {
    // The seller's ID is in the path so storage.rules can check who uploads.
    final name = '${DateTime.now().microsecondsSinceEpoch}.${photo.contentType.split('/').last}';
    final ref = _storage.ref('listing_photos/$sellerId/$listingId/$name');
    try {
      await ref.putData(photo.bytes, SettableMetadata(contentType: photo.contentType));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('[photos] upload failed: ${e.code}');
      throw ListingFailure(switch (e.code) {
        'unauthorized' => "You can't add photos to this listing.",
        'retry-limit-exceeded' || 'unavailable' => "Can't upload photos right now. Check your internet connection.",
        _ => 'Could not upload a photo (${e.code}). Please try again.',
      });
    }
  }

  @override
  Future<void> delete(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      debugPrint('[photos] could not delete $url: $e');
    }
  }
}
