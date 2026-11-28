import 'dart:typed_data';

import 'package:house_business/data/listing_repository.dart';
import 'package:house_business/data/photo_repository.dart';

PickedPhoto fakePhoto({int bytes = 10}) => PickedPhoto(Uint8List(bytes), 'image/jpeg');

// Returns whatever the test put in next, like the user picking those photos.
class FakePhotoPicker implements PhotoPicker {
  List<PickedPhoto> next = [];
  int? lastLimit;

  @override
  Future<List<PickedPhoto>> pickMany({required int limit}) async {
    lastLimit = limit;
    final picked = next;
    next = [];
    return picked;
  }
}

// Keeps uploads in a list instead of Firebase Storage.
class FakePhotoRepository implements PhotoRepository {
  final List<String> uploadedPaths = [];
  final List<String> deleted = [];
  int? failOnUpload; // fail once when this many uploads have already worked

  @override
  Future<String> uploadListingPhoto({
    required String sellerId,
    required String listingId,
    required PickedPhoto photo,
  }) async {
    if (failOnUpload == uploadedPaths.length) {
      failOnUpload = null;
      throw const ListingFailure("Can't upload photos right now. Check your internet connection.");
    }
    // The byte count is in the name so tests can tell which photo went where.
    final path = 'listing_photos/$sellerId/$listingId/${uploadedPaths.length + 1}-${photo.bytes.length}b.jpg';
    uploadedPaths.add(path);
    return 'https://fake.storage/$path';
  }

  @override
  Future<void> delete(String url) async => deleted.add(url);
}
