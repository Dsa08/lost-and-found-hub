import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../providers/admin_provider.dart';

class DisputeScreen extends ConsumerWidget {
  const DisputeScreen({super.key});

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

    if (resolution == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // Update status dispute
    batch.update(FirebaseFirestore.instance.collection(FirestorePaths.disputes).doc(disputeId), {
      'status': 'Resolved',
      'resolution': resolution,
      'resolved_at': FieldValue.serverTimestamp(),
    });

    // Update status item
    batch.update(FirebaseFirestore.instance.collection(FirestorePaths.items).doc(itemId), {
      'status': resolution == 'Refund_Owner' ? 'active' : 'resolved',
      'escrow_status': resolution == 'Refund_Owner' ? 'refunded' : 'released',
    });

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Sengketa diselesaikan: $resolution'),
          backgroundColor: AppColors.statusActive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputesAsync = ref.watch(allDisputesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resolusi Sengketa'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: disputesAsync.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handshake_rounded, size: 64, color: AppColors.statusActive),
                  SizedBox(height: 12),
                  Text('Tidak ada sengketa aktif!', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.docs.length,
            itemBuilder: (ctx, i) {
              final doc = snapshot.docs[i];
              final data = doc.data();
              final status = data['status'] as String? ?? 'Open';
              final isOpen = status == 'Open';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isOpen ? AppColors.statusLost.withValues(alpha: 0.4) : AppColors.border,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOpen ? AppColors.statusLost.withValues(alpha: 0.1) : AppColors.statusActive.withValues(alpha: 0.1),
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
                    const SizedBox(height: 12),

                    // Alasan
                    const Text('Alasan Sengketa', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    Text(data['reason'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),

                    const SizedBox(height: 10),

                    // Pihak
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pelapor', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                              Text(data['reporter_id']?.toString().substring(0, 8) ?? '-',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Terlapor', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                              Text(data['accused_id']?.toString().substring(0, 8) ?? '-',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (isOpen) ...[
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _resolveDispute(
                            context, doc.id,
                            data['item_id'] ?? '',
                            data['reporter_id'] ?? '',
                            data['accused_id'] ?? '',
                          ),
                          icon: const Icon(Icons.gavel_rounded, size: 16),
                          label: const Text('Selesaikan Sengketa'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Text(
                        'Resolusi: ${data['resolution'] ?? '-'}',
                        style: const TextStyle(fontSize: 13, color: AppColors.statusActive, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
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
}