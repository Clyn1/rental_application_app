import 'property_entity.dart';

// Bundles all the filter options into one object instead of passing
// 6+ separate parameters around between screens and providers.
//
// WHY EVERYTHING IS NULLABLE:
// null means "this filter is not applied." This is different from, say,
// 0 — "price >= 0" would mean something different from "no price filter."
class PropertyFilter {
  final double? minPrice;
  final double? maxPrice;
  final int? minBedrooms;
  final int? minBathrooms;
  final List<PropertyType>? propertyTypes;
  final bool availableOnly;
  final double? minRating;
  final String? searchQuery;

  const PropertyFilter({
    this.minPrice,
    this.maxPrice,
    this.minBedrooms,
    this.minBathrooms,
    this.propertyTypes,
    this.availableOnly = false,
    this.minRating,
    this.searchQuery,
  });

  // A reusable constant for "no filters applied" — the default state.
  static const empty = PropertyFilter();

  // Used by the Filter Screen to show "Apply Filters (3)" etc.
  int get activeCount {
    int count = 0;
    if (minPrice != null || maxPrice != null) count++;
    if (minBedrooms != null) count++;
    if (minBathrooms != null) count++;
    if (propertyTypes != null && propertyTypes!.isNotEmpty) count++;
    if (availableOnly) count++;
    if (minRating != null) count++;
    return count;
  }

  PropertyFilter copyWith({
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? minBathrooms,
    List<PropertyType>? propertyTypes,
    bool? availableOnly,
    double? minRating,
    String? searchQuery,
  }) {
    return PropertyFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      availableOnly: availableOnly ?? this.availableOnly,
      minRating: minRating ?? this.minRating,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
