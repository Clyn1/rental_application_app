class PropertyEntity {
  final String id;
  final String landlordId;
  final String landlordName;
  final String? landlordPhotoUrl;

  final String title;
  final String description;
  final double price;
  final String currency;

  final PropertyLocation location;

  final PropertyType propertyType;
  final int bedrooms;
  final int bathrooms;
  final double squareFootage;

  final List<String> amenities;
  final List<String> images;

  final AvailabilityStatus availabilityStatus;
  final ListingStatus listingStatus;

  final double averageRating;
  final int totalRatings;
  final int viewsCount;
  final int favoritesCount;

  final DateTime createdAt;

  const PropertyEntity({
    required this.id,
    required this.landlordId,
    required this.landlordName,
    this.landlordPhotoUrl,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'KES',
    required this.location,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFootage,
    this.amenities = const [],
    this.images = const [],
    this.availabilityStatus = AvailabilityStatus.available,
    this.listingStatus = ListingStatus.pending,
    this.averageRating = 0,
    this.totalRatings = 0,
    this.viewsCount = 0,
    this.favoritesCount = 0,
    required this.createdAt,
  });

  PropertyEntity copyWith({
    String? title,
    String? description,
    double? price,
    PropertyLocation? location,
    PropertyType? propertyType,
    int? bedrooms,
    int? bathrooms,
    double? squareFootage,
    List<String>? amenities,
    List<String>? images,
    AvailabilityStatus? availabilityStatus,
    ListingStatus? listingStatus,
  }) {
    return PropertyEntity(
      id: id,
      landlordId: landlordId,
      landlordName: landlordName,
      landlordPhotoUrl: landlordPhotoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency,
      location: location ?? this.location,
      propertyType: propertyType ?? this.propertyType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      squareFootage: squareFootage ?? this.squareFootage,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      listingStatus: listingStatus ?? this.listingStatus,
      averageRating: averageRating,
      totalRatings: totalRatings,
      viewsCount: viewsCount,
      favoritesCount: favoritesCount,
      createdAt: createdAt,
    );
  }
}

// Groups the 4 location-related fields into one reusable object.
class PropertyLocation {
  final String address;
  final String city;
  final double latitude;
  final double longitude;

  const PropertyLocation({
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
  });
}

enum PropertyType { apartment, house, studio, bedsitter, villa }

enum AvailabilityStatus { available, rented, unavailable }

enum ListingStatus { pending, approved, rejected }
