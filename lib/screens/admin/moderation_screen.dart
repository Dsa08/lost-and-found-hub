import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../providers/admin_provider.dart';

/// **ModerationScreen (Layar Moderasi)**
/// Layar ini digunakan oleh Admin untuk meninjau laporan barang (hilang/temuan)
/// sebelum dipublikasikan ke beranda semua user. Tujuannya mencegah spam atau konten tidak pantas.
class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  /// **Fungsi _approveItem**
  /// Menyetujui laporan agar tampil di publik.
  /// 1. Mengubah `is_approved` menjadi true dan `status` menjadi active.
  /// 2. Menambah statistik `total_reports` pada profil pengguna pelapor.
  Future<void> _approveItem(BuildContext context, String itemId, String uid) async {
    await FirebaseFirestore.instance
        .collection(FirestorePaths.items)
        .doc(itemId)
        .update({
      'is_approved': true,
      'status': 'active',
      'admin_id': uid,
      'approved_at': FieldValue.serverTimestamp(),
    });

    // Update stats user
    await FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .doc(uid)
        .update({'stats.total_reports': FieldValue.increment(1)});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Postingan diapprove!'), backgroundColor: AppColors.statusActive, behavior: SnackBarBehavior.floating),
      );
    }
  }

  /// **Fungsi _rejectItem**
  /// Menolak laporan. Admin diwajibkan mengisi alasan penolakan lewat pop-up (Dialog).
  /// Laporan yang ditolak akan diubah statusnya menjadi 'expired' dan alasannya disimpan di `reject_reason`.
  Future<void> _rejectItem(BuildContext context, String itemId, String ownerId) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Alasan Penolakan', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Tuliskan alasan penolakan...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    await FirebaseFirestore.instance
        .collection(FirestorePaths.items)
        .doc(itemId)
        .update({
      'status': 'expired',
      'reject_reason': reason,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Postingan ditolak'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingItemsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(
        title: const Text('Moderasi Postingan'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: pendingAsync.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.statusActive.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.statusActive),
                  ),
                  const SizedBox(height: 16),
                  const Text('Semua postingan sudah dimoderasi!', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  const Text('Tidak ada yang perlu ditinjau saat ini.', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ],
              ),
            );
          }

          // Desktop: 2-column grid, Mobile: list
          if (isDesktop) {
            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 420,
              ),
              itemCount: snapshot.docs.length,
              itemBuilder: (ctx, i) => _buildModerationCard(context, snapshot.docs[i], isDesktop),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.docs.length,
            itemBuilder: (ctx, i) => _buildModerationCard(context, snapshot.docs[i], isDesktop),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _buildModerationCard(BuildContext context, QueryDocumentSnapshot doc, bool isDesktop) {
    final data = doc.data() as Map<String, dynamic>;
    final fotoUrls = List<String>.from(data['foto_urls'] ?? []);
    final ownerId = data['owner_id'] ?? '';

    return Container(
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: fotoUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: fotoUrls.first,
                    height: isDesktop ? 180 : 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: isDesktop ? 120 : 100,
                    color: AppColors.surfaceVariant,
                    child: const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.textHint, size: 32)),
                  ),
          ),

          // Info Owner
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
            builder: (ctx, userSnap) {
              final ownerData = userSnap.data?.data() as Map<String, dynamic>?;
              final ownerName = ownerData?['nama'] as String? ?? 'Unknown';
              final ownerUsername = ownerData?['username'] as String? ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ownerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          if (ownerUsername.isNotEmpty)
                            Text('@$ownerUsername', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('Pelapor', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipe badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: data['tipe_laporan'] == 'Lost'
                            ? AppColors.statusLost.withValues(alpha: 0.12)
                            : AppColors.statusFound.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['tipe_laporan'] == 'Lost' ? 'HILANG' : 'DITEMUKAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: data['tipe_laporan'] == 'Lost' ? AppColors.statusLost : AppColors.statusFound,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(data['kategori'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 8),

                Text(
                  data['judul'] ?? 'Tanpa Judul',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data['deskripsi'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Info tambahan
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        (data['lokasi'] as Map?)?['nama_lokasi'] ?? '-',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((data['nominal_bounty'] ?? 0) > 0) ...[
                      const Icon(Icons.star_rounded, size: 13, color: AppColors.bounty),
                      const SizedBox(width: 4),
                      Text('${data['nominal_bounty']} poin', style: const TextStyle(fontSize: 12, color: AppColors.bounty, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectItem(context, doc.id, ownerId),
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                        label: const Text('Tolak', style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _approveItem(context, doc.id, ownerId),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusActive),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}