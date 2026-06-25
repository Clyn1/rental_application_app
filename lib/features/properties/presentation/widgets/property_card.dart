import 'package:flutter/material.dart';
import '../../domain/entities/property_entity.dart';

// Reusable card used on Home, Search, Favorites, Recently Viewed — every
// place that shows a list of properties. Build once, looks the same everywhere.
class PropertyCard extends StatelessWidget {
  final PropertyEntity property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: property.images.isNotEmpty
                      ? Image.network(
                          property.images.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(child: Icon(Icons.home_outlined, size: 40)),
                        ),
                ),
                if (onFavoriteTap != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.4),
                        radius: 18,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                          size: 20,
                        ),  
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${property.currency} ${_formatPrice(property.price)}/mo',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      if (property.totalRatings > 0) ...[
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          property.averageRating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statChip(Icons.bed_outlined, '${property.bedrooms}'),
                      const SizedBox(width: 12),
                      _statChip(Icons.bathtub_outlined, '${property.bathrooms}'),
                      const SizedBox(width: 12),
                      _statChip(Icons.square_foot_outlined, '${property.squareFootage.toInt()} sqft'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _formatPrice(double price) {
    final intPrice = price.toInt();
    final str = intPrice.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
