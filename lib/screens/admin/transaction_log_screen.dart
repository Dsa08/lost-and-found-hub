import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_provider.dart';

class TransactionLogScreen extends ConsumerStatefulWidget {
  const TransactionLogScreen({super.key});

  @override
  ConsumerState<TransactionLogScreen> createState() => _TransactionLogScreenState();
}

class _TransactionLogScreenState extends ConsumerState<TransactionLogScreen> {
  // null = semua, 'Escrow_Lock' / 'Escrow_Release' / 'Escrow_Refund'
  String? _filterType;

  static const _filterOptions = [
    (null, 'Semua', Icons.swap_horiz_rounded, AppColors.textSecondary),
    ('Escrow_Lock', 'Dikunci', Icons.lock_rounded, AppColors.statusPending),
    ('Escrow_Release', 'Dicairkan', Icons.lock_open_rounded, AppColors.statusActive),
    ('Escrow_Refund', 'Dikembalikan', Icons.undo_rounded, AppColors.primary),
  ];

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

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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

          final allDocs = snapshot.docs;

          // Hitung summary
          int totalLocked = 0, totalReleased = 0, totalRefunded = 0;
          for (final doc in allDocs) {
            final data = doc.data();
            final type = data['type'] as String? ?? '';
            final amount = data['amount'] as int? ?? 0;
            if (type == 'Escrow_Lock') totalLocked += amount;
            if (type == 'Escrow_Release') totalReleased += amount;
            if (type == 'Escrow_Refund') totalRefunded += amount;
          }

          // Terapkan filter
          final filtered = _filterType == null
              ? allDocs
              : allDocs.where((d) => d['type'] == _filterType).toList();

          return Column(
            children: [
              // ── Summary Stats ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(child: _SummaryItem(
                      label: 'Terkunci',
                      value: '$totalLocked',
                      icon: Icons.lock_rounded,
                      color: AppColors.statusPending,
                    )),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
                    Expanded(child: _SummaryItem(
                      label: 'Dicairkan',
                      value: '$totalReleased',
                      icon: Icons.lock_open_rounded,
                      color: AppColors.statusActive,
                    )),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
                    Expanded(child: _SummaryItem(
                      label: 'Dikembalikan',
                      value: '$totalRefunded',
                      icon: Icons.undo_rounded,
                      color: AppColors.primary,
                    )),
                  ],
                ),
              ),

              // ── Filter Chips ──
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  children: _filterOptions.map((opt) {
                    final isSelected = _filterType == opt.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(opt.$3, size: 14, color: isSelected ? Colors.white : opt.$4),
                            const SizedBox(width: 4),
                            Text(opt.$2, style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : opt.$4,
                            )),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _filterType = opt.$1),
                        selectedColor: opt.$4,
                        backgroundColor: opt.$4.withValues(alpha: 0.1),
                        checkmarkColor: Colors.white,
                        showCheckmark: false,
                        side: BorderSide(color: opt.$4.withValues(alpha: isSelected ? 1 : 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Count label ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} transaksi',
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // ── List ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_typeIcon(_filterType ?? ''), size: 48, color: AppColors.textHint),
                            const SizedBox(height: 10),
                            const Text('Tidak ada transaksi tipe ini', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final data = filtered[i].data();
                          final type = data['type'] as String? ?? '';
                          final amount = data['amount'] as int? ?? 0;
                          final color = _typeColor(type);
                          final timestamp = data['created_at'] as Timestamp?;
                          final fromUser = data['from_user'] as String? ?? '';
                          final toUser = data['to_user'] as String? ?? '';

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
                                if (fromUser.isNotEmpty || toUser.isNotEmpty)
                                  Text(
                                    '${fromUser.isNotEmpty ? "dari ${fromUser.substring(0, 6)}..." : ""}'
                                    '${toUser.isNotEmpty ? " → ${toUser.substring(0, 6)}..." : ""}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                                  ),
                                if (timestamp != null)
                                  Text(
                                    _formatDate(timestamp.toDate()),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$amount',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
                                ),
                                Text('poin', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
                              ],
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
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ],
  );
}