import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/property_filter.dart';
import '../providers/property_provider.dart';
import '../widgets/property_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final propertiesAsync = ref.watch(propertyListProvider(PropertyFilter.empty));

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
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed('/notifications'),
          ),
        ],
      ),

      // WHY FloatingActionButton HERE:
      // The FAB is Flutter's standard "primary action" button for a screen.
      // It floats above everything else so it's always visible and tappable
      // no matter how far the user has scrolled down the property list.
      // Tapping it navigates to '/add-property' which is registered in
      // app.dart's routes map and shows AddPropertyScreen.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/add-property'),
        icon: const Icon(Icons.add),
        label: const Text('Add Property'),
      ),

      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(propertyListProvider(PropertyFilter.empty)),
        child: propertiesAsync.when(
          data: (properties) {
            if (properties.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              // WHY BOTTOM PADDING OF 80:
              // The FAB floats over the bottom of the list. Without
              // extra bottom padding, the last property card would be
              // hidden behind the FAB and unreachable by scrolling.
              // 80px is enough to clear the FAB height comfortably.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                  onFavoriteTap: () {},
                  isFavorite: false,
                );
              },
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => _buildSkeletonCard(context),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load properties.\n${error.toString()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(
                        propertyListProvider(PropertyFilter.empty)),
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

  Widget _buildSkeletonCard(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
