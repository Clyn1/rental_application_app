import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/property_filter.dart';
import '../providers/property_provider.dart';
import '../widgets/property_card.dart';

// This is the TENANT home screen.
// A tenant's job is to BROWSE and FIND properties — nothing else.
// They do not add, edit, or manage listings.
// The "Add Property" button that was here before has been removed
// because it belonged to the Landlord role, not the Tenant role.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final propertiesAsync = ref.watch(
      propertyListProvider(PropertyFilter.empty),
    );

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (user) => Text(
            user != null
                ? 'Hello, ${user.fullName.split(' ').first} 👋'
                : 'Welcome',
          ),
          loading: () => const Text('Welcome'),
          error: (_, __) => const Text('Welcome'),
        ),
        actions: [
          // Notifications bell — tenants receive alerts when
          // their viewing requests are approved/rejected.
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed('/notifications'),
          ),
        ],
      ),

      // WHY NO floatingActionButton HERE:
      // The tenant's primary action is browsing — they tap on
      // property cards, not adding new listings.
      // The "Add Property" FAB lives on LandlordDashboardScreen
      // because only a landlord should ever see or use it.
      // Mixing landlord controls into the tenant screen would
      // confuse tenants and break the role separation we designed.

      body: RefreshIndicator(
        // Pull down to refresh the property list manually.
        // Since we use a StreamProvider (real-time), data usually
        // updates automatically — but this is a useful fallback
        // if the user suspects data is stale.
        onRefresh: () async => ref.invalidate(
          propertyListProvider(PropertyFilter.empty),
        ),
        child: propertiesAsync.when(
          data: (properties) {
            if (properties.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              // WHY BOTTOM PADDING OF 16 (not 80):
              // We removed the FAB, so there's no floating button
              // covering the bottom of the list anymore.
              // Normal padding is enough.
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return PropertyCard(
                  property: property,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/property-details',
                      arguments: property.id,
                    );
                  },
                  // Favorite toggling — wired up when we build
                  // the Favorites feature next.
                  onFavoriteTap: () {},
                  isFavorite: false,
                );
              },
            );
          },

          // While Firestore is loading, show skeleton placeholder
          // cards so the layout doesn't jump when data arrives.
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => _buildSkeletonCard(context),
          ),

          // If the query fails (e.g. Firestore index missing,
          // or network error), show a clear error with a retry button.
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load properties.\n${error.toString()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(
                      propertyListProvider(PropertyFilter.empty),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Shown when Firestore returns an empty list — no approved
  // listings exist yet. Gives tenants a clear message rather
  // than a confusing blank screen.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No properties available yet.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder cards shown while the property list loads.
  // They match the shape of a real PropertyCard so the screen
  // doesn't jump or reflow when real data arrives.
  Widget _buildSkeletonCard(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(color: color),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 100, color: color),
                const SizedBox(height: 8),
                Container(height: 14, width: 180, color: color),
                const SizedBox(height: 8),
                Container(height: 12, width: 120, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
