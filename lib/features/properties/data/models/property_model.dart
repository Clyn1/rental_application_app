import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/property_entity.dart';

class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.id,
    required super.landlordId,
    required super.landlordName,
    super.landlordPhotoUrl,
    required super.title,
    required super.description,
    required super.price,
    super.currency,
    required super.location,
    required super.propertyType,
    required super.bedrooms,
    required super.bathrooms,
    required super.squareFootage,
    super.amenities,
    super.images,
    super.availabilityStatus,
    super.listingStatus,
    super.averageRating,
    super.totalRatings,
    super.viewsCount,
    super.favoritesCount,
    required super.createdAt,
  });

  factory PropertyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final locationMap = data['location'] as Map<String, dynamic>? ?? {};

    return PropertyModel(
      id: doc.id,
      landlordId: data['landlordId'] as String? ?? '',
      landlordName: data['landlordName'] as String? ?? '',
      landlordPhotoUrl: data['landlordPhotoUrl'] as String?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'KES',
      location: PropertyLocation(
        address: locationMap['address'] as String? ?? '',
        city: locationMap['city'] as String? ?? '',
        latitude: (locationMap['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (locationMap['longitude'] as num?)?.toDouble() ?? 0,
      ),
      propertyType: _typeFromString(data['propertyType'] as String?),
      bedrooms: (data['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (data['bathrooms'] as num?)?.toInt() ?? 0,
      squareFootage: (data['squareFootage'] as num?)?.toDouble() ?? 0,
      amenities: List<String>.from(data['amenities'] as List? ?? []),
      images: List<String>.from(data['images'] as List? ?? []),
      availabilityStatus: _availabilityFromString(data['availabilityStatus'] as String?),
      listingStatus: _listingStatusFromString(data['listingStatus'] as String?),
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 0,
      viewsCount: (data['viewsCount'] as num?)?.toInt() ?? 0,
      favoritesCount: (data['favoritesCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({List<String>? imageUrls}) {
    return {
      'landlordId': landlordId,
      'landlordName': landlordName,
      'landlordPhotoUrl': landlordPhotoUrl,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'location': {
        'address': location.address,
        'city': location.city,
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'propertyType': propertyType.name,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFootage': squareFootage,
      'amenities': amenities,
      'images': imageUrls ?? images,
      'availabilityStatus': availabilityStatus.name,
      'listingStatus': listingStatus.name,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'viewsCount': viewsCount,
      'favoritesCount': favoritesCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'location': {
        'address': location.address,
        'city': location.city,
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'propertyType': propertyType.name,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFootage': squareFootage,
      'amenities': amenities,
      'images': images,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static PropertyType _typeFromString(String? value) {
    return PropertyType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PropertyType.apartment,
    );
  }

  static AvailabilityStatus _availabilityFromString(String? value) {
    return AvailabilityStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AvailabilityStatus.available,
    );
  }

  static ListingStatus _listingStatusFromString(String? value) {
    return ListingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ListingStatus.pending,
    );
  }
}
