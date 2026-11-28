import 'package:house_business/data/geocoder.dart';
import 'package:house_business/data/listing_repository.dart';
import 'package:house_business/models/listing.dart';

// In-memory listings used by widget tests so they don't need Firestore.
class FakeListingRepository implements ListingRepository {
  final Map<String, Listing> listings = {};
  var _nextId = 1;
  bool offline = false; // pretend the write got queued on the phone
  bool failSave = false;

  @override
  String newListingId() => 'new${_nextId++}';

  @override
  Future<Listing?> getListing(String id) async => listings[id];

  @override
  Future<bool> createListing(Listing listing) async {
    if (failSave) throw const ListingFailure("Can't reach the server. Check your internet connection.");
    listings[listing.id!] = listing;
    return !offline;
  }

  @override
  Future<bool> updateListing(Listing listing) async {
    if (failSave) throw const ListingFailure("Can't reach the server. Check your internet connection.");
    listings[listing.id!] = listing;
    return !offline;
  }
}

// Finds every address unless found is false. Counts lookups so tests can check they're skipped.
class FakeGeocoder implements Geocoder {
  bool found = true;
  final List<String> lookups = [];

  @override
  Future<ListingLocation?> locate(String address) async {
    lookups.add(address);
    return found ? const ListingLocation(lat: 33.75, lng: -84.39, geohash: 'dn5bp0000') : null;
  }
}
