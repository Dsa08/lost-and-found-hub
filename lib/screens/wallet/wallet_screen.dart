import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/wallet_repository.dart';

/// **WalletScreen (Layar Dompet & Statistik)**
/// Menampilkan ringkasan saldo poin pengguna (Poin Aktif & Ditahan Sistem),
/// statistik tingkat keberhasilan laporan (Success Rate),
/// serta riwayat aliran keluar-masuk poin (Transaction Logs).
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dompet Saya')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Belum login'));
          final historyStream = ref.watch(walletRepositoryProvider).getTransactionHistory(user.uid);
          final isDesktop = MediaQuery.of(context).size.width >= 800;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kolom Kiri: Saldo & Stats
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWalletCard(user),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _StatCard(label: 'Total Diselesaikan', value: '${user.stats.totalResolved}', icon: Icons.check_circle_rounded, color: AppColors.statusActive)),
                            const SizedBox(width: 16),
                            Expanded(child: _StatCard(label: 'Total Laporan', value: '${user.stats.totalReports}', icon: Icons.list_alt_rounded, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _StatCard(
                          label: 'Success Rate Keseluruhan',
                          value: '${user.stats.successRate.toStringAsFixed(0)}%',
                          icon: Icons.trending_up_rounded,
                          color: AppColors.bounty,
                        ),
                      ],
                    ),
                  ),
                ),
                // Pembatas
                Container(width: 1, color: AppColors.divider),
                // Kolom Kanan: Histori
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Text('Riwayat Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                      Expanded(
                        child: _buildHistoryList(historyStream, user.uid),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Layout Mobile
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CustomScrollView(
            slivers: [
              // ── Wallet Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildWalletCard(user),
                ),
              ),

              // ── Stats Row ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Total Diselesaikan', value: '${user.stats.totalResolved}', icon: Icons.check_circle_rounded, color: AppColors.statusActive)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'Total Laporan', value: '${user.stats.totalReports}', icon: Icons.list_alt_rounded, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        label: 'Success Rate',
                        value: '${user.stats.successRate.toStringAsFixed(0)}%',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.bounty,
                      )),
                    ],
                  ),
                ),
              ),

              // ── History Header ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text('Riwayat Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
              ),

              // ── History List ──
              SliverToBoxAdapter(
                child: _buildHistoryList(historyStream, user.uid),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _buildWalletCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text('Total Poin', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${user.totalPoin}',
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
          ),
          const Text('poin tersedia', style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${user.lockedPoin} poin terkunci (ditahan sementara)',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(Stream<List<Map<String, dynamic>>> historyStream, String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: historyStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final logs = snap.data ?? [];
        if (logs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text('Belum ada transaksi', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _TransactionTile(log: logs[i], userId: userId),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)]),
    child: Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
      ],
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> log;
  final String userId;
  const _TransactionTile({required this.log, required this.userId});

  @override
  Widget build(BuildContext context) {
    final type = log['type'] as String? ?? '';
    final amount = log['amount'] as int? ?? 0;
    final isCredit = log['to_user'] == userId;
    final isDebit = log['from_user'] == userId && log['to_user'] != null;

    IconData icon;
    Color color;
    String label;

    switch (type) {
      case 'Escrow_Lock':
        icon = Icons.lock_rounded; color = AppColors.statusPending; label = 'Bounty Dikunci';
        break;
      case 'Escrow_Release':
        icon = Icons.lock_open_rounded; color = AppColors.statusActive; label = isCredit ? 'Bounty Diterima' : 'Bounty Dicairkan';
        break;
      case 'Escrow_Refund':
        icon = Icons.undo_rounded; color = AppColors.primary; label = 'Bounty Dikembalikan';
        break;
      default:
        icon = Icons.swap_horiz_rounded; color = AppColors.textSecondary; label = type;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text('Item ID: ${log['item_id']?.toString().substring(0, 8) ?? '-'}...', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
      trailing: Text(
        '${isCredit ? '+' : isDebit ? '-' : ''}$amount poin',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: isCredit ? AppColors.statusActive : isDebit ? AppColors.statusLost : AppColors.textSecondary,
        ),
      ),
    );
  }
}