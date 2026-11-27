import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { buyer, seller }

// Public profile stored at users/{uid}. Email and phone are NOT here,
// they live in users/{uid}/private/contact where only the owner can read them.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.role,
    this.photoUrl,
    this.createdAt,
  });

  final String uid;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final DateTime? createdAt;

  bool get isSeller => role == UserRole.seller;

  // Returns null if the document is missing a field or has a bad role,
  // so one broken document can't crash the app.
  static AppUser? fromMap(String uid, Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['name'];
    final role = UserRole.values.asNameMap()[data['role']];
    if (name is! String || role == null) return null;
    final created = data['createdAt'];
    return AppUser(
      uid: uid,
      name: name,
      role: role,
      photoUrl: data['photoUrl'] as String?,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
