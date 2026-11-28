import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

// A home for sale. The fields match validListing in firestore.rules.

enum ListingStatus { draft, published, archived, sold }

enum HomeType {
  house('House'),
  townhouse('Townhouse'),
  condo('Condo'),
  apartment('Apartment');

  const HomeType(this.label);
  final String label;
}

// Amenities a seller can tick on the form.
const amenityOptions = [
  'Garage',
  'Pool',
  'Yard',
  'Basement',
  'Fireplace',
  'Central air',
  'Laundry',
  'Pets allowed',
  'New roof',
  'Solar',
];

class ListingLocation {
  const ListingLocation({required this.lat, required this.lng, required this.geohash});

  final double lat;
  final double lng;
  final String geohash;

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng, 'geohash': geohash};

  static ListingLocation? fromMap(Object? data) {
    if (data is! Map) return null;
    final lat = data['lat'];
    final lng = data['lng'];
    final hash = data['geohash'];
    if (lat is! num || lng is! num || hash is! String) return null;
    return ListingLocation(lat: lat.toDouble(), lng: lng.toDouble(), geohash: hash);
  }
}

class Listing {
  const Listing({
    this.id,
    required this.sellerId,
    required this.status,
    required this.title,
    this.description,
    required this.price,
    required this.type,
    required this.beds,
    required this.baths,
    this.sqft,
    this.yearBuilt,
    this.lotSize,
    this.address,
    required this.city,
    required this.zip,
    this.location,
    this.amenities = const [],
    this.photos = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String? id; // null until saved
  final String sellerId;
  final ListingStatus status;
  final String title;
  final String? description;
  final int price;
  final HomeType type;
  final int beds;
  final double baths; // 2.5 baths is normal
  final int? sqft;
  final int? yearBuilt;
  final double? lotSize; // acres
  final String? address;
  final String city;
  final String zip;
  final ListingLocation? location; // null if the address couldn't be found on the map
  final List<String> amenities;
  final List<String> photos; // download URLs, first one is the cover
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublished => status == ListingStatus.published;

  // The full address for the map and the geocoder.
  String get fullAddress =>
      [if (address != null && address!.isNotEmpty) address, city, zip].join(', ');

  // Every field is written, even when null, because the rules expect all of them.
  // createdAt and updatedAt are set by the repository with the server time.
  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'status': status.name,
        'title': title,
        'description': description,
        'price': price,
        'type': type.name,
        'beds': beds,
        'baths': baths,
        'sqft': sqft,
        'yearBuilt': yearBuilt,
        'lotSize': lotSize,
        'address': address,
        'city': city,
        'zip': zip,
        'location': location?.toMap(),
        'amenities': amenities,
        'photos': photos,
      };

  // Returns null if the document is broken, so one bad listing can't crash the feed.
  static Listing? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final status = ListingStatus.values.asNameMap()[data['status']];
    final type = HomeType.values.asNameMap()[data['type']];
    final title = data['title'];
    final price = data['price'];
    final beds = data['beds'];
    final baths = data['baths'];
    final city = data['city'];
    final zip = data['zip'];
    final sellerId = data['sellerId'];
    if (status == null ||
        type == null ||
        title is! String ||
        price is! num ||
        beds is! num ||
        baths is! num ||
        city is! String ||
        zip is! String ||
        sellerId is! String) {
      return null;
    }
    return Listing(
      id: id,
      sellerId: sellerId,
      status: status,
      title: title,
      description: data['description'] as String?,
      price: price.round(),
      type: type,
      beds: beds.toInt(),
      baths: baths.toDouble(),
      sqft: (data['sqft'] as num?)?.round(),
      yearBuilt: (data['yearBuilt'] as num?)?.toInt(),
      lotSize: (data['lotSize'] as num?)?.toDouble(),
      address: data['address'] as String?,
      city: city,
      zip: zip,
      location: ListingLocation.fromMap(data['location']),
      amenities: _strings(data['amenities']),
      photos: _strings(data['photos']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Listing copyWith({
    String? id,
    ListingStatus? status,
    ListingLocation? location,
    bool clearLocation = false,
    List<String>? photos,
  }) {
    return Listing(
      id: id ?? this.id,
      sellerId: sellerId,
      status: status ?? this.status,
      title: title,
      description: description,
      price: price,
      type: type,
      beds: beds,
      baths: baths,
      sqft: sqft,
      yearBuilt: yearBuilt,
      lotSize: lotSize,
      address: address,
      city: city,
      zip: zip,
      location: clearLocation ? null : (location ?? this.location),
      amenities: amenities,
      photos: photos ?? this.photos,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

DateTime? _date(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null; // still waiting on the server time
}
