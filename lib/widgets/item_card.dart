import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/constants/app_colors.dart';
import '../models/item_model.dart';
import 'bounty_badge.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Foto ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  item.fotoUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.fotoUrls.first,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 160,
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),

                  // Tipe laporan badge (kiri atas)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: StatusBadge(
                      status: item.tipeLaporan == TipeLaporan.lost ? 'lost' : 'found',
                    ),
                  ),

                  // Bounty badge (kanan atas)
                  if (item.hasBounty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: BountyBadge(poin: item.nominalBounty),
                    ),
                ],
              ),
            ),

            // ── Info ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul + Kategori
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.judul,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _KategoriBadge(item.kategori),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Deskripsi
                  Text(
                    item.deskripsi,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Lokasi + Waktu
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.lokasi.namaLokasi,
                          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeago.format(item.createdAt, locale: 'id'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
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

  Widget _placeholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.tipeLaporan == TipeLaporan.lost
                ? Icons.search_off_rounded
                : Icons.inventory_2_outlined,
            size: 40,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 6),
          const Text('Tidak ada foto', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _KategoriBadge extends StatelessWidget {
  final KategoriBarang kategori;
  const _KategoriBadge(this.kategori);

  static const Map<KategoriBarang, IconData> _icons = {
    KategoriBarang.elektronik: Icons.devices_rounded,
    KategoriBarang.dompet: Icons.account_balance_wallet_rounded,
    KategoriBarang.kunci: Icons.key_rounded,
    KategoriBarang.pakaian: Icons.checkroom_rounded,
    KategoriBarang.dokumen: Icons.description_rounded,
    KategoriBarang.tas: Icons.backpack_rounded,
    KategoriBarang.lainnya: Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[kategori] ?? Icons.help_outline, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            kategori.name[0].toUpperCase() + kategori.name.substring(1),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}