// The "pure" description of a User in plain Dart.
// No Firebase, no packages — just fields that describe what a user IS.
//
// WHY PURE DART HERE?
// This lets us talk about "a user" in our business logic and UI without
// depending on Firebase at all. If we ever change databases, this file
// never changes.

class UserEntity {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final AccountType accountType;
  final bool isEmailVerified;
  final bool isSuspended;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profilePhotoUrl,
    required this.accountType,
    required this.isEmailVerified,
    this.isSuspended = false,
    required this.createdAt,
  });

  // copyWith lets us create a MODIFIED COPY without changing the original.
  // All fields are `final` (immutable), so to "change" something we make
  // a fresh object. This is safer — nothing can secretly mutate our data.
  UserEntity copyWith({
    String? fullName,
    String? phoneNumber,
    String? profilePhotoUrl,
    bool? isEmailVerified,
  }) {
    return UserEntity(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      accountType: accountType,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isSuspended: isSuspended,
      createdAt: createdAt,
    );
  }
}

// An enum is a fixed list of allowed values.
// This is much safer than storing "tenant" or "landlord" as a plain
// String, because the Dart compiler catches typos at build time.
enum AccountType { tenant, landlord, admin }
