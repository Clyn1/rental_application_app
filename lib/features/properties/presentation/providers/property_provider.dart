import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/property_remote_datasource.dart';
import '../../data/repositories/property_repository_impl.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_filter.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/usecases/add_property_usecase.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final propertyRemoteDatasourceProvider = Provider<PropertyRemoteDatasource>((ref) {
  return PropertyRemoteDatasource(ref.watch(firestoreServiceProvider));
});

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepositoryImpl(
    ref.watch(propertyRemoteDatasourceProvider),
    ref.watch(storageServiceProvider),
  );
});

final addPropertyUsecaseProvider = Provider<AddPropertyUsecase>((ref) {
  return AddPropertyUsecase(ref.watch(propertyRepositoryProvider));
});

final propertyListProvider = StreamProvider.family<List<PropertyEntity>, PropertyFilter>(
  (ref, filter) {
    return ref.watch(propertyRepositoryProvider).watchProperties(filter);
  },
);

final propertyDetailsProvider = StreamProvider.family<PropertyEntity?, String>(
  (ref, propertyId) {
    return ref.watch(propertyRepositoryProvider).watchProperty(propertyId);
  },
);

final myPropertiesProvider = StreamProvider<List<PropertyEntity>>((ref) {
  final landlordId = ref.watch(currentUserIdProvider);
  if (landlordId == null) return Stream.value([]);
  return ref.watch(propertyRepositoryProvider).watchLandlordProperties(landlordId);
});

class PropertyFormState {
  final String title;
  final String description;
  final double? price;
  final PropertyType propertyType;
  final int bedrooms;
  final int bathrooms;
  final double? squareFootage;
  final List<String> amenities;
  final PropertyLocation? location;
  final List<String> localImagePaths;

  const PropertyFormState({
    this.title = '',
    this.description = '',
    this.price,
    this.propertyType = PropertyType.apartment,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.squareFootage,
    this.amenities = const [],
    this.location,
    this.localImagePaths = const [],
  });

  PropertyFormState copyWith({
    String? title,
    String? description,
    double? price,
    PropertyType? propertyType,
    int? bedrooms,
    int? bathrooms,
    double? squareFootage,
    List<String>? amenities,
    PropertyLocation? location,
    List<String>? localImagePaths,
  }) {
    return PropertyFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      propertyType: propertyType ?? this.propertyType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      squareFootage: squareFootage ?? this.squareFootage,
      amenities: amenities ?? this.amenities,
      location: location ?? this.location,
      localImagePaths: localImagePaths ?? this.localImagePaths,
    );
  }
}

class PropertyFormNotifier extends Notifier<PropertyFormState> {
  @override
  PropertyFormState build() => const PropertyFormState();

  void setTitle(String value) => state = state.copyWith(title: value);
  void setDescription(String value) => state = state.copyWith(description: value);
  void setPrice(double value) => state = state.copyWith(price: value);
  void setPropertyType(PropertyType value) => state = state.copyWith(propertyType: value);
  void setBedrooms(int value) => state = state.copyWith(bedrooms: value);
  void setBathrooms(int value) => state = state.copyWith(bathrooms: value);
  void setSquareFootage(double value) => state = state.copyWith(squareFootage: value);

  void toggleAmenity(String amenity) {
    final current = List<String>.from(state.amenities);
    if (current.contains(amenity)) {
      current.remove(amenity);
    } else {
      current.add(amenity);
    }
    state = state.copyWith(amenities: current);
  }

  void setLocation(PropertyLocation location) => state = state.copyWith(location: location);

  void addImagePaths(List<String> paths) {
    state = state.copyWith(localImagePaths: [...state.localImagePaths, ...paths]);
  }

  void removeImagePath(String path) {
    final updated = List<String>.from(state.localImagePaths)..remove(path);
    state = state.copyWith(localImagePaths: updated);
  }

  void reset() => state = const PropertyFormState();
}

final propertyFormProvider = NotifierProvider<PropertyFormNotifier, PropertyFormState>(() {
  return PropertyFormNotifier();
});

class PropertyFormSubmitNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final form = ref.read(propertyFormProvider);
      final user = await ref.read(currentUserProvider.future);

      if (user == null) {
        throw Exception('You must be logged in to add a property.');
      }
      if (form.location == null) {
        throw Exception('Please set the property location on the map.');
      }

      final property = PropertyEntity(
        id: '',
        landlordId: user.uid,
        landlordName: user.fullName,
        landlordPhotoUrl: user.profilePhotoUrl,
        title: form.title,
        description: form.description,
        price: form.price ?? 0,
        location: form.location!,
        propertyType: form.propertyType,
        bedrooms: form.bedrooms,
        bathrooms: form.bathrooms,
        squareFootage: form.squareFootage ?? 0,
        amenities: form.amenities,
        createdAt: DateTime.now(),
      );

      await ref.read(addPropertyUsecaseProvider).call(
            property: property,
            localImagePaths: form.localImagePaths,
          );

      ref.read(propertyFormProvider.notifier).reset();
    });
  }
}

final propertyFormSubmitProvider = AsyncNotifierProvider<PropertyFormSubmitNotifier, void>(() {
  return PropertyFormSubmitNotifier();
});
  