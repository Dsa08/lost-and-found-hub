import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../providers/admin_provider.dart';

/// **DisputeScreen (Resolusi Sengketa)**
/// Layar ini digunakan oleh Admin untuk menengahi masalah antara Pelapor (Reporter) dan Terlapor (Accused).
/// Misalnya: Terlapor bilang barang sudah dikembalikan, tapi Pelapor bilang belum terima.
///
/// REFAKTOR: Sebelumnya menggunakan `allDisputesProvider` yang men-download SELURUH data sengketa.
/// Sekarang menggunakan `paginatedDisputesProvider` yang mengambil data 20 per halaman.
class DisputeScreen extends ConsumerStatefulWidget {
  const DisputeScreen({super.key});

  @override
  ConsumerState<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends ConsumerState<DisputeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Infinite scroll: muat halaman berikutnya saat mendekati ujung bawah
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedDisputesProvider.notifier).loadNextPage();
    }
  }

  /// Fungsi utama untuk mengeksekusi penyelesaian sengketa (Resolusi).
  /// Fungsi ini menggunakan **Firestore Batch** agar update di tabel 'disputes' dan 'items'
  /// terjadi secara bersamaan (Atomic). Jika salah satu gagal, semuanya batal (mencegah data korup).
  Future<void> _resolveDispute(
    BuildContext context,
    String disputeId,
    String itemId,
    String reporterId,
    String accusedId,
  ) async {
    String? resolution = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolusi Sengketa', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Pilih keputusan akhir untuk sengketa ini:'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'Refund_Owner'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.statusPending),
            child: const Text('Refund ke Owner'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'Release_Finder'),
            child: const Text('Cairkan ke Finder'),
          ),
        ],
      ),
    );

    if (resolution == null) return; // Batal jika admin menutup pop-up tanpa memilih

    // Menggunakan WriteBatch untuk transaksi database yang aman
    final batch = FirebaseFirestore.instance.batch();

    // 1. Update status sengketa menjadi selesai (Resolved) dan catat keputusannya
    batch.update(FirebaseFirestore.instance.collection(FirestorePaths.disputes).doc(disputeId), {
      'status': 'Resolved',
      'resolution': resolution,
      'resolved_at': FieldValue.serverTimestamp(),
    });

    // 2. Update status barang dan status escrow (uang jaminan)
    // Jika Refund -> poin kembali ke pelapor, status barang kembali 'active' (belum selesai)
    // Jika Release -> poin cair ke penemu, status barang 'resolved' (selesai)
    batch.update(FirebaseFirestore.instance.collection(FirestorePaths.items).doc(itemId), {
      'status': resolution == 'Refund_Owner' ? 'active' : 'resolved',
      'escrow_status': resolution == 'Refund_Owner' ? 'refunded' : 'released',
    });

    // Eksekusi semua update sekaligus
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Sengketa diselesaikan: $resolution'),
          backgroundColor: AppColors.statusActive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Refresh data setelah resolve
      ref.read(paginatedDisputesProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // REFAKTOR: Menggunakan paginatedDisputesProvider alih-alih allDisputesProvider
    final disputesState = ref.watch(paginatedDisputesProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    // Pisahkan Open dan Resolved
    final openDocs = disputesState.items.where((d) => (d.data())['status'] == 'Open').toList();
    final resolvedDocs = disputesState.items.where((d) => (d.data())['status'] != 'Open').toList();
    final allDocs = [...openDocs, ...resolvedDocs];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(
        title: const Text('Resolusi Sengketa'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: allDocs.isEmpty && !disputesState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.statusActive.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake_rounded, size: 56, color: AppColors.statusActive),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tidak ada sengketa aktif!', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  const Text('Semua berjalan lancar saat ini.', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ],
              ),
            )
          : isDesktop
              ? GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    mainAxisExtent: 310,
                  ),
                  // +1 untuk loading indicator
                  itemCount: allDocs.length + (disputesState.hasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= allDocs.length) {
                      return Center(
                        child: disputesState.isLoading
                            ? const CircularProgressIndicator(color: AppColors.primary)
                            : TextButton.icon(
                                onPressed: () => ref.read(paginatedDisputesProvider.notifier).loadNextPage(),
                                icon: const Icon(Icons.expand_more_rounded),
                                label: const Text('Muat Lebih Banyak'),
                              ),
                      );
                    }
                    return _buildDisputeCard(context, allDocs[i]);
                  },
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  // +1 untuk loading indicator
                  itemCount: allDocs.length + (disputesState.hasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= allDocs.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: disputesState.isLoading
                              ? const CircularProgressIndicator(color: AppColors.primary)
                              : TextButton.icon(
                                  onPressed: () => ref.read(paginatedDisputesProvider.notifier).loadNextPage(),
                                  icon: const Icon(Icons.expand_more_rounded),
                                  label: const Text('Muat Lebih Banyak'),
                                ),
                        ),
                      );
                    }
                    return _buildDisputeCard(context, allDocs[i]);
                  },
                ),
    );
  }

  Widget _buildDisputeCard(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = data['status'] as String? ?? 'Open';
    final isOpen = status == 'Open';
    final reporterId = data['reporter_id'] as String? ?? '';
    final accusedId = data['accused_id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen ? AppColors.statusLost.withValues(alpha: 0.4) : AppColors.divider.withValues(alpha: 0.5),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isOpen
                  ? AppColors.statusLost.withValues(alpha: 0.06)
                  : AppColors.statusActive.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? AppColors.statusLost.withValues(alpha: 0.12)
                        : AppColors.statusActive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOpen ? '🔴 OPEN' : '✅ RESOLVED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isOpen ? AppColors.statusLost : AppColors.statusActive,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${doc.id.substring(0, 8)}...',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Alasan ──
                const Text('Alasan Sengketa', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(height: 4),
                Text(
                  data['reason'] ?? '-',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // ── Pihak ──
                Row(
                  children: [
                    Expanded(
                      child: _UserInfoTile(
                        userId: reporterId,
                        label: 'Pelapor',
                        color: AppColors.statusLost,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 18),
                    ),
                    Expanded(
                      child: _UserInfoTile(
                        userId: accusedId,
                        label: 'Terlapor',
                        color: AppColors.statusPending,
                        alignRight: true,
                      ),
                    ),
                  ],
                ),

                if (isOpen) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _resolveDispute(
                        context, doc.id,
                        data['item_id'] ?? '',
                        reporterId,
                        accusedId,
                      ),
                      icon: const Icon(Icons.gavel_rounded, size: 16),
                      label: const Text('Selesaikan Sengketa'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.statusActive, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Resolusi: ${data['resolution'] ?? '-'}',
                        style: const TextStyle(fontSize: 13, color: AppColors.statusActive, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget untuk tampilkan info user by ID ───────────────────────────────────
class _UserInfoTile extends StatelessWidget {
  final String userId;
  final String label;
  final Color color;
  final bool alignRight;

  const _UserInfoTile({
    required this.userId,
    required this.label,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (ctx, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final nama = data?['nama'] as String? ?? 'Unknown';
        final username = data?['username'] as String? ?? '';

        return Column(
          crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!alignRight) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      nama.isNotEmpty ? nama[0].toUpperCase() : 'U',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        snap.connectionState == ConnectionState.waiting ? '...' : nama,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (username.isNotEmpty)
                        Text('@$username', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                    ],
                  ),
                ),
                if (alignRight) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      nama.isNotEmpty ? nama[0].toUpperCase() : 'U',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}