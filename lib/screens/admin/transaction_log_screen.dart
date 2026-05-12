import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_provider.dart';

class TransactionLogScreen extends ConsumerWidget {
  const TransactionLogScreen({super.key});

  Color _typeColor(String type) {
    switch (type) {
      case 'Escrow_Lock': return AppColors.statusPending;
      case 'Escrow_Release': return AppColors.statusActive;
      case 'Escrow_Refund': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Escrow_Lock': return Icons.lock_rounded;
      case 'Escrow_Release': return Icons.lock_open_rounded;
      case 'Escrow_Refund': return Icons.undo_rounded;
      default: return Icons.swap_horiz_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'Escrow_Lock': return 'Bounty Dikunci';
      case 'Escrow_Release': return 'Bounty Dicairkan';
      case 'Escrow_Refund': return 'Bounty Dikembalikan';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(allLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Log Transaksi'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: logsAsync.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('Belum ada transaksi', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white54, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Menampilkan ${snapshot.docs.length} transaksi terakhir',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final data = snapshot.docs[i].data();
                    final type = data['type'] as String? ?? '';
                    final amount = data['amount'] as int? ?? 0;
                    final color = _typeColor(type);
                    final timestamp = data['created_at'] as Timestamp?;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_typeIcon(type), color: color, size: 18),
                      ),
                      title: Text(_typeLabel(type), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item: ${(data['item_id'] ?? '').toString().length > 8 ? (data['item_id'] ?? '').toString().substring(0, 8) : data['item_id'] ?? '-'}...',
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                          ),
                          if (timestamp != null)
                            Text(
                              _formatDate(timestamp.toDate()),
                              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '$amount poin',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}