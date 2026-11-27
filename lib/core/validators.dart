// Form checks used by the login, sign up, and reset screens.

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
