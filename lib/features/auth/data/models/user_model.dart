import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

// UserModel IS a UserEntity (it extends it), but it also knows how to
// convert to/from Firestore format.
//
// WHY TWO SEPARATE CLASSES (UserEntity + UserModel)?
// UserEntity is "what a user is" — pure, no database knowledge.
// UserModel is "how that user is stored in Firestore" — has fromFirestore/toMap.
// The rest of the app only talks to UserEntity. Only this file and the
// datasource talk to Firestore's format. Clean separation.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.phoneNumber,
    super.profilePhotoUrl,
    required super.accountType,
    required super.isEmailVerified,
    super.isSuspended,
    required super.createdAt,
  });

  // Reads a Firestore document and builds a UserModel from it.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return UserModel(
      uid: doc.id,
      // WHY `as String? ?? ''`:
      // Firestore is flexible — a field might be missing or the wrong type
      // (especially if data was written manually in the Firebase console).
      // Instead of crashing, we provide a safe fallback value.
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      accountType: _accountTypeFromString(data['accountType'] as String?),
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      isSuspended: data['isSuspended'] as bool? ?? false,
      // Firestore stores dates as Timestamp, not DateTime. We must convert.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Converts this object into a Map that Firestore can store.
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePhotoUrl': profilePhotoUrl,
      // .name converts the enum to a string: AccountType.tenant -> "tenant"
      'accountType': accountType.name,
      'isEmailVerified': isEmailVerified,
      'isSuspended': isSuspended,
      // serverTimestamp() uses the Firebase SERVER'S clock, not the
      // device's clock. This is more reliable (devices can have wrong times).
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static AccountType _accountTypeFromString(String? value) {
    switch (value) {
      case 'landlord':
        return AccountType.landlord;
      case 'admin':
        return AccountType.admin;
      default:
        // If value is null or something unexpected, default to tenant.
        // Tenant has the LEAST permissions, so this is the safest default.
        return AccountType.tenant;
    }
  }
}
