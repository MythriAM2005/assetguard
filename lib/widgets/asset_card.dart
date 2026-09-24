import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../theme/app_theme.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;
  final VoidCallback? onReportLost;

  const AssetCard({
    super.key,
    required this.asset,
    this.onTap,
    this.onReportLost,
  });

  IconData get _categoryIcon {
    switch (asset.category.toLowerCase()) {
      case 'bag':
      case 'backpack':
        return Icons.backpack_outlined;
      case 'laptop':
      case 'computer':
        return Icons.laptop_outlined;
      case 'id card':
        return Icons.badge_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'phone':
      case 'mobile':
        return Icons.smartphone_outlined;
      case 'keys':
        return Icons.key_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'electronics':
        return Icons.headphones_outlined;
      default:
        return Icons.devices_other_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = asset.status.statusColor;
    final statusBg = asset.status.statusBgColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_categoryIcon,
                  color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          asset.status[0].toUpperCase() +
                              asset.status.substring(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined,
                          size: 13, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        asset.category,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.nfc_outlined,
                          size: 13, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        asset.trackerId,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          asset.lastDetectedLocation,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9CA3AF)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: Color(0xFFD1D5DB), size: 20),
          ],
        ),
      ),
    );
  }
}
