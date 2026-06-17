import '../../../../core/errors/failures.dart';
import '../entities/property_entity.dart';
import '../repositories/property_repository.dart';

// Business rules for "add a new property listing."
// Catching bad data HERE means it never reaches Firestore at all,
// and the error shows up instantly with no network delay.
class AddPropertyUsecase {
  final PropertyRepository _repository;

  AddPropertyUsecase(this._repository);

  Future<String> call({
    required PropertyEntity property,
    required List<String> localImagePaths,
  }) async {
    if (property.title.trim().isEmpty) {
      throw const ValidationFailure('Please enter a property title.');
    }

    if (property.description.trim().length < 20) {
      throw const ValidationFailure(
        'Please write a description of at least 20 characters.',
      );
    }

    if (property.price <= 0) {
      throw const ValidationFailure('Price must be greater than zero.');
    }

    if (localImagePaths.isEmpty) {
      throw const ValidationFailure('Please add at least one photo of the property.');
    }

    if (property.bedrooms < 0 || property.bathrooms < 0) {
      throw const ValidationFailure('Bedrooms and bathrooms cannot be negative.');
    }

    // New listings always start as "pending" no matter what was passed in.
    // A landlord should never be able to self-approve their own listing.
    final sanitized = PropertyEntity(
      id: property.id,
      landlordId: property.landlordId,
      landlordName: property.landlordName,
      landlordPhotoUrl: property.landlordPhotoUrl,
      title: property.title.trim(),
      description: property.description.trim(),
      price: property.price,
      currency: property.currency,
      location: property.location,
      propertyType: property.propertyType,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      squareFootage: property.squareFootage,
      amenities: property.amenities,
      images: const [],
      availabilityStatus: AvailabilityStatus.available,
      listingStatus: ListingStatus.pending,
      createdAt: DateTime.now(),
    );

    return _repository.addProperty(property: sanitized, localImagePaths: localImagePaths);
  }
}
