import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bounty_badge.dart';
import 'item_detail_screen.dart';
import 'claim_review_screen.dart';

final myItemsStreamProvider = StreamProvider.family<List<ItemModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.items)
      .where('owner_id', isEqualTo: userId)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ItemModel.fromFirestore).toList());
});

class MyItemsScreen extends ConsumerWidget {
  const MyItemsScreen({super.key});

  Color _statusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.active: return AppColors.statusActive;
      case ItemStatus.pendingApproval: return AppColors.statusPending;
      case ItemStatus.pendingMeetup: return AppColors.primary;
      case ItemStatus.resolved: return AppColors.textSecondary;
      case ItemStatus.expired: return AppColors.error;
    }
  }

  String _statusLabel(ItemStatus status) {
    switch (status) {
      case ItemStatus.active: return 'Aktif';
      case ItemStatus.pendingApproval: return 'Menunggu Moderasi';
      case ItemStatus.pendingMeetup: return 'Pending Meetup';
      case ItemStatus.resolved: return 'Selesai';
      case ItemStatus.expired: return 'Ditolak/Expired';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: Text('Belum login')));

    final itemsAsync = ref.watch(myItemsStreamProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Laporan Saya')),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text('Belum ada laporan', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                  const Text('Tekan + untuk buat laporan baru', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final statusColor = _statusColor(item.status);

              return GestureDetector(
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.itemId)),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      // Foto kecil
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                        child: item.fotoUrls.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.fotoUrls.first,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _photoPlaceholder(),
                              )
                            : _photoPlaceholder(),
                      ),

                      // Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.judul,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  BountyBadge(poin: item.nominalBounty),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _statusLabel(item.status),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timeago.format(item.createdAt, locale: 'id'),
                                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tombol review klaim (hanya jika ada klaim pending)
                      if (item.status == ItemStatus.active || item.status == ItemStatus.pendingMeetup)
                        _ClaimBadge(itemId: item.itemId, onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(builder: (_) => ClaimReviewScreen(item: item)),
                        )),

                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
    width: 90, height: 90,
    color: AppColors.surfaceVariant,
    child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textHint),
  );
}

/// Badge merah yang tampil kalau ada klaim pending
class _ClaimBadge extends StatelessWidget {
  final String itemId;
  final VoidCallback onTap;
  const _ClaimBadge({required this.itemId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.itemClaims(itemId))
          .where('status', isEqualTo: 'waiting')
          .snapshots(),
      builder: (ctx, snap) {
        final count = snap.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.statusLost,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const Text('Klaim', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }
}