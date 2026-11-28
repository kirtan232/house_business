import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_business/core/geohash.dart';
import 'package:house_business/core/validators.dart';
import 'package:house_business/models/listing.dart';

const sample = Listing(
  id: 'l1',
  sellerId: 's1',
  status: ListingStatus.published,
  title: 'Nice house',
  price: 250000,
  type: HomeType.townhouse,
  beds: 3,
  baths: 2.5,
  city: 'Atlanta',
  zip: '30303',
);

void main() {
  group('listing validators', () {
    test('price takes commas and a dollar sign', () {
      expect(parsePrice('\$350,000'), 350000);
      expect(validatePrice('350,000'), isNull);
    });
    test('price must be over 0 and under 100 million (boundary)', () {
      expect(validatePrice('0'), isNotNull);
      expect(validatePrice('1'), isNull);
      expect(validatePrice('99999999'), isNull);
      expect(validatePrice('100000000'), isNotNull);
    });
    test('price must be whole dollars', () => expect(validatePrice('12.50'), isNotNull));
    test('title is 3 to 100 characters (boundary)', () {
      expect(validateTitle('ab'), isNotNull);
      expect(validateTitle('abc'), isNull);
      expect(validateTitle('a' * 100), isNull);
      expect(validateTitle('a' * 101), isNotNull);
    });
    test('beds 0 to 20 (boundary)', () {
      expect(validateBeds('0'), isNull);
      expect(validateBeds('20'), isNull);
      expect(validateBeds('21'), isNotNull);
      expect(validateBeds(''), isNotNull);
    });
    test('baths can be half, not a quarter', () {
      expect(validateBaths('2.5'), isNull);
      expect(validateBaths('2.25'), isNotNull);
    });
    test('sqft, year, and lot size are optional', () {
      expect(validateSqft(''), isNull);
      expect(validateYearBuilt(''), isNull);
      expect(validateLotSize(''), isNull);
    });
    test('year built can be next year but not later', () {
      final now = DateTime(2026, 11, 27);
      expect(validateYearBuilt('2027', now: now), isNull);
      expect(validateYearBuilt('2028', now: now), isNotNull);
      expect(validateYearBuilt('1799', now: now), isNotNull);
    });
    test('ZIP must be exactly 5 digits', () {
      expect(validateZip('30303'), isNull);
      expect(validateZip('3030'), isNotNull);
      expect(validateZip('303031'), isNotNull);
    });
  });

  group('geohash', () {
    // Known value from the geohash spec examples.
    test('matches a known spot', () => expect(geohash(57.64911, 10.40744), 'u4pruydqq'));
    test('nearby homes share the start', () {
      final a = geohash(33.7490, -84.3880);
      final b = geohash(33.7495, -84.3885);
      expect(a.substring(0, 5), b.substring(0, 5));
    });
  });

  group('Listing', () {
    test('toMap writes every field the rules expect, even when empty', () {
      final keys = sample.toMap().keys.toSet()..addAll(['createdAt', 'updatedAt']);
      expect(keys, {
        'sellerId', 'status', 'title', 'description', 'price', 'type', 'beds', 'baths',
        'sqft', 'yearBuilt', 'lotSize', 'address', 'city', 'zip', 'location', 'amenities',
        'photos', 'createdAt', 'updatedAt',
      });
      expect(sample.toMap()['sqft'], isNull);
      expect(sample.toMap()['location'], isNull);
    });

    test('fromMap reads back what toMap wrote', () {
      final data = sample
          .copyWith(location: const ListingLocation(lat: 1, lng: 2, geohash: 's00'))
          .toMap()
        ..['createdAt'] = Timestamp.fromDate(DateTime(2026, 11, 1));
      final l = Listing.fromMap('l1', data)!;
      expect(l.type, HomeType.townhouse);
      expect(l.baths, 2.5);
      expect(l.location!.geohash, 's00');
      expect(l.createdAt, DateTime(2026, 11, 1));
      expect(l.updatedAt, isNull); // server time not back yet
    });

    test('a broken document gives null instead of crashing', () {
      expect(Listing.fromMap('x', {'title': 'No price'}), isNull);
      expect(Listing.fromMap('x', {...sample.toMap(), 'type': 'castle'}), isNull);
    });

    test('full address skips a missing street', () {
      expect(sample.fullAddress, 'Atlanta, 30303');
    });
  });
}
