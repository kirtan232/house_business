import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../core/geohash.dart';
import '../models/listing.dart';

// Finds the map spot for an address. Returns null when it can't,
// so the listing still saves with just the city and ZIP.
abstract class Geocoder {
  Future<ListingLocation?> locate(String address);
}

final geocoderProvider = Provider<Geocoder>((ref) => DeviceGeocoder());

// Uses the phone's built in geocoder (Google on Android). No API key needed.
class DeviceGeocoder implements Geocoder {
  @override
  Future<ListingLocation?> locate(String address) async {
    try {
      final results = await geo.Geocoding()
          .locationFromAddress(address)
          .timeout(const Duration(seconds: 8));
      if (results.isEmpty) return null;
      final spot = results.first;
      return ListingLocation(
        lat: spot.latitude,
        lng: spot.longitude,
        geohash: geohash(spot.latitude, spot.longitude),
      );
    } catch (e) {
      // No internet, timed out, or the address was not found.
      debugPrint('[geocoder] could not find "$address": $e');
      return null;
    }
  }
}
