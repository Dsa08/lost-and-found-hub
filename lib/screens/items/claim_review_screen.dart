import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/utils/security_utils.dart';
import '../../models/item_model.dart';
import '../../providers/items_provider.dart';

/// **ClaimReviewScreen (Layar Peninjauan Klaim)**
/// Layar ini hanya bisa diakses oleh Pemilik (Owner) barang.
/// Digunakan untuk melihat daftar orang yang mengaku menemukan barangnya,
/// memverifikasi jawaban keamanan (Security Question) yang mereka masukkan,
/// lalu menekan tombol 'Approve' atau 'Tolak'.
class ClaimReviewScreen extends ConsumerWidget {
  final ItemModel item;
  const ClaimReviewScreen({super.key, required this.item});

  /// Mengambil daftar klaim secara realtime dari sub-koleksi `claims` pada item ini
  /// yang statusnya masih 'waiting'.
  Stream<QuerySnapshot> get _claimsStream => FirebaseFirestore.instance
      .collection(FirestorePaths.itemClaims(item.itemId))
      .where('status', isEqualTo: 'waiting')
      .orderBy('created_at', descending: false)
      .snapshots();

  Future<Map<String, dynamic>?> _getFinderInfo(String finderId) async {
    final doc = await FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .doc(finderId)
        .get();
    return doc.data();
  }

  /// **Fungsi _approveClaim**
  /// Jika owner yakin orang ini benar penemunya (jawaban benar).
  /// Ini akan memanggil `ItemsRepository.approveClaim` yang mana:
  /// 1. Mengubah status klaim jadi 'approved'.
  /// 2. Mengubah status barang jadi 'pendingMeetup'.
  /// 3. Mengaktifkan fitur Chat antara owner dan finder.
  Future<void> _approveClaim(
    BuildContext context,
    WidgetRef ref,
    String claimId,
    String finderId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Klaim?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Setelah approve, chat akan diaktifkan dan status berubah ke Pending Meetup. '
          'Lanjutkan?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusActive),
            child: const Text('Ya, Approve'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(itemsRepositoryProvider).approveClaim(
        itemId: item.itemId,
        claimId: claimId,
        finderId: finderId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Klaim diapprove! Chat sudah aktif.'),
            backgroundColor: AppColors.statusActive,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// **Fungsi _rejectClaim**
  /// Menolak klaim palsu (biasanya karena jawaban sekuriti salah).
  /// Mengubah status klaim menjadi 'rejected'.
  Future<void> _rejectClaim(
    BuildContext context,
    WidgetRef ref,
    String claimId,
  ) async {
    try {
      await ref.read(itemsRepositoryProvider).rejectClaim(item.itemId, claimId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Klaim ditolak'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Klaim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(item.judul, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
          // Info Security Question
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pertanyaan Keamananmu:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        item.securityQuestion ?? 'Tidak ada pertanyaan',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List Klaim
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _claimsStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 56, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('Belum ada klaim masuk', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        Text('Notifikasi akan masuk saat ada yang klaim', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final claimData = docs[i].data() as Map<String, dynamic>;
                    final claimId = docs[i].id;
                    final finderId = claimData['finder_id'] as String? ?? '';
                    final answer = claimData['security_answer'] as String? ?? '';

                    // Cek apakah jawaban benar
                    final isCorrect = item.securityAnswerHash != null &&
                        SecurityUtils.verifyAnswer(answer, item.securityAnswerHash!);

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getFinderInfo(finderId),
                      builder: (ctx, finderSnap) {
                        final finderData = finderSnap.data;
                        final finderNama = finderData?['nama'] ?? 'Loading...';
                        final finderUsername = finderData?['username'] ?? '-';
                        final finderReputation = finderData?['reputation_score'] ?? 50;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCorrect
                                  ? AppColors.statusActive.withValues(alpha: 0.4)
                                  : AppColors.border,
                              width: isCorrect ? 1.5 : 1,
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Finder Info
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      finderNama.isNotEmpty ? finderNama[0].toUpperCase() : 'F',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(finderNama, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                        Text('@$finderUsername · Rep: $finderReputation', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  // Badge benar/salah
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCorrect
                                          ? AppColors.statusActive.withValues(alpha: 0.1)
                                          : AppColors.statusLost.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                          size: 14,
                                          color: isCorrect ? AppColors.statusActive : AppColors.statusLost,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isCorrect ? 'Jawaban Benar' : 'Jawaban Salah',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isCorrect ? AppColors.statusActive : AppColors.statusLost,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Jawaban
                              const Text('Jawaban Security Question:', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  answer.isEmpty ? '(tidak menjawab)' : answer,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Tombol aksi
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _rejectClaim(context, ref, claimId),
                                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                                      label: const Text('Tolak', style: TextStyle(color: AppColors.error)),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approveClaim(context, ref, claimId, finderId),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: const Text('Approve & Chat'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isCorrect ? AppColors.statusActive : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}