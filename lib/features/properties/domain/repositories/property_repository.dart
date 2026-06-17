import '../entities/property_entity.dart';
import '../entities/property_filter.dart';

// The contract for anything that manages properties.
abstract class PropertyRepository {
  // Real-time stream of properties matching the filter.
  Stream<List<PropertyEntity>> watchProperties(PropertyFilter filter);

  // Real-time stream of a single property (for the Details screen).
  Stream<PropertyEntity?> watchProperty(String propertyId);

  // All properties belonging to one landlord (My Properties screen).
  Stream<List<PropertyEntity>> watchLandlordProperties(String landlordId);

  // Adds a new property. Returns the new property's ID.
  Future<String> addProperty({
    required PropertyEntity property,
    required List<String> localImagePaths,
  });

  Future<void> updateProperty(PropertyEntity property);

  Future<void> deleteProperty(String propertyId);

  Future<void> setAvailability(String propertyId, AvailabilityStatus status);

  Future<void> incrementViewCount(String propertyId);
}
