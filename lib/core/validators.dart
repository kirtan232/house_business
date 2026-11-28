// Form checks used by the login, sign up, profile, and listing screens.

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your email.';
  if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address.';
  return null;
}

// isNew is true on sign up, where the 6 character minimum is checked.
String? validatePassword(String? value, {bool isNew = false}) {
  final v = value ?? '';
  if (v.isEmpty) return 'Enter your password.';
  if (isNew && v.length < 6) return 'Password must be at least 6 characters.';
  return null;
}

String? validateName(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your name.';
  if (v.length < 2) return 'Name must be at least 2 characters.';
  if (v.length > 50) return 'Name must be 50 characters or less.';
  return null;
}

// Phone is optional. If given it must be 10 digits (US), dashes and spaces are ok.
String? validatePhone(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  final digits = v.replaceAll(RegExp(r'[\s\-().]'), '');
  if (!RegExp(r'^\d{10}$').hasMatch(digits)) return 'Enter a 10 digit phone number.';
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  final v = value ?? '';
  if (v.isEmpty) return 'Enter your password again.';
  if (v != password) return "Passwords don't match.";
  return null;
}

// ---------- listing form ----------
// The limits match validListing in firestore.rules.

// "$350,000" and "350000" both work.
int? parsePrice(String? value) =>
    int.tryParse((value ?? '').replaceAll(RegExp(r'[\s$,]'), ''));

String? validateTitle(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter a title.';
  if (v.length < 3) return 'Title must be at least 3 characters.';
  if (v.length > 100) return 'Title must be 100 characters or less.';
  return null;
}

String? validatePrice(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Enter a price.';
  final price = parsePrice(value);
  if (price == null) return 'Enter the price in whole dollars.';
  if (price <= 0) return 'Price must be more than \$0.';
  if (price >= 100000000) return 'Price must be under \$100,000,000.';
  return null;
}

String? validateBeds(String? value) {
  final beds = int.tryParse(value?.trim() ?? '');
  if (beds == null) return 'Enter beds.';
  if (beds < 0 || beds > 20) return '0 to 20.';
  return null;
}

String? validateBaths(String? value) {
  final baths = double.tryParse(value?.trim() ?? '');
  if (baths == null) return 'Enter baths.';
  if (baths < 0 || baths > 20) return '0 to 20.';
  if ((baths * 2) % 1 != 0) return 'Use whole or half baths.';
  return null;
}

// Optional. Similar Homes still works without it.
String? validateSqft(String? value) {
  final v = value?.replaceAll(',', '').trim() ?? '';
  if (v.isEmpty) return null;
  final sqft = int.tryParse(v);
  if (sqft == null || sqft < 100 || sqft > 100000) return '100 to 100,000.';
  return null;
}

String? validateYearBuilt(String? value, {DateTime? now}) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  final year = int.tryParse(v);
  final maxYear = (now ?? DateTime.now()).year + 1; // new builds can be listed early
  if (year == null || year < 1800 || year > maxYear) return '1800 to $maxYear.';
  return null;
}

String? validateLotSize(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  final acres = double.tryParse(v);
  if (acres == null || acres <= 0 || acres > 1000) return 'Acres, like 0.25.';
  return null;
}

String? validateCity(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter the city.';
  if (v.length > 60) return 'City must be 60 characters or less.';
  return null;
}

String? validateZip(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter the ZIP.';
  if (!RegExp(r'^\d{5}$').hasMatch(v)) return 'ZIP must be 5 digits.';
  return null;
}
