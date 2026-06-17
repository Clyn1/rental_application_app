import 'dart:io';
import '../../../../services/storage_service.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_filter.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_remote_datasource.dart';
import '../models/property_model.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDatasource _datasource;
  final StorageService _storage;

  PropertyRepositoryImpl(this._datasource, this._storage);

  @override
  Stream<List<PropertyEntity>> watchProperties(PropertyFilter filter) {
    return _datasource.watchProperties(filter);
  }

  @override
  Stream<PropertyEntity?> watchProperty(String propertyId) {
    return _datasource.watchProperty(propertyId);
  }

  @override
  Stream<List<PropertyEntity>> watchLandlordProperties(String landlordId) {
    return _datasource.watchLandlordProperties(landlordId);
  }

  @override
  Future<String> addProperty({
    required PropertyEntity property,
    required List<String> localImagePaths,
  }) async {
    final model = PropertyModel(
      id: '',
      landlordId: property.landlordId,
      landlordName: property.landlordName,
      landlordPhotoUrl: property.landlordPhotoUrl,
      title: property.title,
      description: property.description,
      price: property.price,
      currency: property.currency,
      location: property.location,
      propertyType: property.propertyType,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      squareFootage: property.squareFootage,
      amenities: property.amenities,
      images: const [],
      availabilityStatus: property.availabilityStatus,
      listingStatus: property.listingStatus,
      createdAt: property.createdAt,
    );

    // STEP 1: create the Firestore doc first (empty images list) so we get
    // a real property ID to use as the Storage folder name.
    final propertyId = await _datasource.createProperty(model.toMap(imageUrls: const []));

    // STEP 2: upload images now that we have a propertyId.
    final files = localImagePaths.map((path) => File(path)).toList();
    final imageUrls = await _storage.uploadPropertyImages(propertyId: propertyId, files: files);

    // STEP 3: go back and add the final image URLs to the document.
    await _datasource.updateImages(propertyId, imageUrls);

    return propertyId;
  }

  @override
  Future<void> updateProperty(PropertyEntity property) async {
    final model = PropertyModel(
      id: property.id,
      landlordId: property.landlordId,
      landlordName: property.landlordName,
      landlordPhotoUrl: property.landlordPhotoUrl,
      title: property.title,
      description: property.description,
      price: property.price,
      currency: property.currency,
      location: property.location,
      propertyType: property.propertyType,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      squareFootage: property.squareFootage,
      amenities: property.amenities,
      images: property.images,
      availabilityStatus: property.availabilityStatus,
      listingStatus: property.listingStatus,
      createdAt: property.createdAt,
    );

    await _datasource.updateProperty(property.id, model.toUpdateMap());
  }

  @override
  Future<void> deleteProperty(String propertyId) {
    return _datasource.deleteProperty(propertyId);
  }

  @override
  Future<void> setAvailability(String propertyId, AvailabilityStatus status) {
    return _datasource.setAvailability(propertyId, status.name);
  }

  @override
  Future<void> incrementViewCount(String propertyId) {
    return _datasource.incrementViewCount(propertyId);
  }
}
