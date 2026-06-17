import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../services/firestore_service.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_filter.dart';
import '../models/property_model.dart';

class PropertyRemoteDatasource {
  final FirestoreService _firestore;

  PropertyRemoteDatasource(this._firestore);

  // Builds and streams a Firestore query based on the given filter.
  //
  // NOTE ON FIRESTORE LIMITS:
  // Firestore can't combine arbitrary "where" filters easily, so we apply
  // what we can directly in the query (listingStatus, availability, price)
  // and apply the rest (bedrooms, bathrooms, type, rating, text search)
  // on the results AFTER they come back. This is fine at small-to-medium
  // scale; a dedicated search service (like Algolia) would be the next
  // step at large scale.
  Stream<List<PropertyModel>> watchProperties(PropertyFilter filter) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestorePaths.properties)
        .where('listingStatus', isEqualTo: ListingStatus.approved.name);

    if (filter.availableOnly) {
      query = query.where('availabilityStatus', isEqualTo: AvailabilityStatus.available.name);
    }
    if (filter.minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: filter.minPrice);
    }
    if (filter.maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: filter.maxPrice);
    }

    query = query.orderBy('createdAt', descending: true).limit(50);

    return query.snapshots().map((snapshot) {
      var results = snapshot.docs.map(PropertyModel.fromFirestore).toList();

      if (filter.minBedrooms != null) {
        results = results.where((p) => p.bedrooms >= filter.minBedrooms!).toList();
      }
      if (filter.minBathrooms != null) {
        results = results.where((p) => p.bathrooms >= filter.minBathrooms!).toList();
      }
      if (filter.propertyTypes != null && filter.propertyTypes!.isNotEmpty) {
        results = results.where((p) => filter.propertyTypes!.contains(p.propertyType)).toList();
      }
      if (filter.minRating != null) {
        results = results.where((p) => p.averageRating >= filter.minRating!).toList();
      }
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final q = filter.searchQuery!.trim().toLowerCase();
        results = results.where((p) {
          return p.title.toLowerCase().contains(q) ||
              p.location.city.toLowerCase().contains(q) ||
              p.location.address.toLowerCase().contains(q) ||
              p.landlordName.toLowerCase().contains(q);
        }).toList();
      }

      return results;
    });
  }

  Stream<PropertyModel?> watchProperty(String propertyId) {
    return _firestore.doc(FirestorePaths.properties, propertyId).snapshots().map(
          (snapshot) => snapshot.exists ? PropertyModel.fromFirestore(snapshot) : null,
        );
  }

  // Landlord's own properties — no listingStatus filter, since a landlord
  // should see ALL their properties including pending/rejected ones.
  Stream<List<PropertyModel>> watchLandlordProperties(String landlordId) {
    return _firestore
        .collection(FirestorePaths.properties)
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PropertyModel.fromFirestore).toList());
  }

  // Creates a new property doc and returns its generated ID.
  // We call .doc() first (without saving) so we know the ID BEFORE
  // uploading images, since images are stored in a folder named after it.
  Future<String> createProperty(Map<String, dynamic> data) async {
    final docRef = _firestore.collection(FirestorePaths.properties).doc();
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateImages(String propertyId, List<String> imageUrls) async {
    await _firestore.doc(FirestorePaths.properties, propertyId).update({'images': imageUrls});
  }

  Future<void> updateProperty(String propertyId, Map<String, dynamic> data) async {
    await _firestore.doc(FirestorePaths.properties, propertyId).update(data);
  }

  Future<void> deleteProperty(String propertyId) async {
    await _firestore.doc(FirestorePaths.properties, propertyId).delete();
  }

  Future<void> setAvailability(String propertyId, String statusName) async {
    await _firestore.doc(FirestorePaths.properties, propertyId).update({
      'availabilityStatus': statusName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // FieldValue.increment(1) safely adds 1 on Firestore's SERVER, even if
  // many users view the property at the exact same moment. This avoids a
  // race condition that a manual "read, add 1, write" approach would have.
  Future<void> incrementViewCount(String propertyId) async {
    await _firestore.doc(FirestorePaths.properties, propertyId).update({
      'viewsCount': FieldValue.increment(1),
    });
  }
}
