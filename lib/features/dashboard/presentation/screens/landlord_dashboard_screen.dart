import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../properties/domain/entities/property_filter.dart';
import '../../../properties/presentation/providers/property_provider.dart';
import '../../../properties/presentation/widgets/property_card.dart';

// WHY THIS SCREEN EXISTS:
// A landlord's job is completely different from a tenant's.
// A tenant browses and saves properties.
// A landlord manages their own listings and handles booking requests.
// Showing both the same home screen would be confusing and wrong.
// This screen is the landlord's "command centre."
class LandlordDashboardScreen extends ConsumerWidget {
  const LandlordDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final myPropertiesAsync = ref.watch(myPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (user) => Text(
            user != null ? 'Welcome, ${user.fullName.split(' ').first} 👋' : 'Dashboard',
          ),
          loading: () => const Text('Dashboard'),
          error: (_, __) => const Text('Dashboard'),
        ),
        actions: [
          // Notifications bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed('/notifications'),
          ),
          // Profile/logout menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authActionsProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Log Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // The FAB lets the landlord quickly add a new property
      // from anywhere on this screen without hunting for a button.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/add-property'),
        icon: const Icon(Icons.add),
        label: const Text('Add Property'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── QUICK STATS SECTION ──────────────────────────
            // WHY SHOW STATS AT THE TOP?
            // The first thing a landlord wants to know when they
            // open the app is: "how are my properties doing?"
            // Summary cards give them that at a glance without
            // having to navigate anywhere.
            myPropertiesAsync.when(
              data: (properties) => _StatsRow(
                totalListings: properties.length,
                activeListings: properties
                    .where((p) => p.availabilityStatus.name == 'available')
                    .length,
                pendingListings: properties
                    .where((p) => p.listingStatus.name == 'pending')
                    .length,
              ),
              loading: () => const _StatsRowSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 28),

            // ── PENDING REQUESTS BANNER ───────────────────────
            // Shown only if there are pending booking requests.
            // A landlord should never miss an incoming request.
            _PendingRequestsBanner(),

            const SizedBox(height: 28),

            // ── MY PROPERTIES SECTION ────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Properties',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/my-properties'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            myPropertiesAsync.when(
              data: (properties) {
                if (properties.isEmpty) {
                  return _buildEmptyProperties(context);
                }
                // Show up to 3 most recent properties as a preview.
                // "View All" takes them to the full My Properties screen.
                final preview = properties.take(3).toList();
                return Column(
                  children: preview
                      .map((property) => PropertyCard(
                            property: property,
                            onTap: () => Navigator.of(context).pushNamed(
                              '/property-details',
                              arguments: property.id,
                            ),
                            // Landlords don't favorite their own properties
                            onFavoriteTap: null,
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Could not load properties: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProperties(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.home_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            "You haven't listed any properties yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (context as Element)
                .findAncestorStateOfType<NavigatorState>() != null
                ? () => Navigator.of(context).pushNamed('/add-property')
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Property'),
          ),
        ],
      ),
    );
  }
}

// ── STATS ROW ────────────────────────────────────────────────
// Three cards showing key numbers at a glance.
// WHY SEPARATE WIDGET?
// Keeping this as its own widget means if the stats data
// is still loading, we show a skeleton version of this exact
// widget — same layout, just greyed out. Cleaner than
// mixing loading logic into the main build method.
class _StatsRow extends StatelessWidget {
  final int totalListings;
  final int activeListings;
  final int pendingListings;

  const _StatsRow({
    required this.totalListings,
    required this.activeListings,
    required this.pendingListings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: '$totalListings',
            icon: Icons.home_work_outlined,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Active',
            value: '$activeListings',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Pending',
            value: '$pendingListings',
            icon: Icons.pending_outlined,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Skeleton version shown while stats are loading.
// Same layout as _StatsRow but with grey placeholder boxes.
class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// ── PENDING REQUESTS BANNER ─────────────────────────────────
// A highlighted banner that appears when there are
// unanswered booking requests. Landlords should not miss these.
class _PendingRequestsBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now this is a static placeholder.
    // When we build the Bookings feature, this will watch
    // a real incomingRequestsProvider and show the actual count.
    // We build the UI now so the layout is correct from the start.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Requests',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Booking management coming soon.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.orange),
        ],
      ),
    );
  }
}
