import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class BountyBadge extends StatelessWidget {
  final int poin;
  final bool large;

  const BountyBadge({super.key, required this.poin, this.large = false});

  @override
  Widget build(BuildContext context) {
    if (poin <= 0) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.bountyLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bounty.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: AppColors.bounty, size: large ? 18 : 14),
          const SizedBox(width: 4),
          Text(
            '$poin poin',
            style: TextStyle(
              fontSize: large ? 14 : 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7B5800),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config['label'] as String,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config['color'] as Color,
        ),
      ),
    );
  }

  Map<String, dynamic> _getConfig(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return {'label': 'HILANG', 'color': AppColors.statusLost, 'bg': AppColors.statusLost.withValues(alpha: 0.12)};
      case 'found':
        return {'label': 'DITEMUKAN', 'color': AppColors.statusFound, 'bg': AppColors.statusFound.withValues(alpha: 0.12)};
      case 'active':
        return {'label': 'AKTIF', 'color': AppColors.statusActive, 'bg': AppColors.statusActive.withValues(alpha: 0.12)};
      case 'pendingmeetup':
        return {'label': 'PENDING MEETUP', 'color': AppColors.statusPending, 'bg': AppColors.statusPending.withValues(alpha: 0.12)};
      case 'resolved':
        return {'label': 'SELESAI', 'color': AppColors.statusResolved, 'bg': AppColors.statusResolved.withValues(alpha: 0.12)};
      default:
        return {'label': status.toUpperCase(), 'color': AppColors.textSecondary, 'bg': AppColors.surfaceVariant};
    }
  }
}