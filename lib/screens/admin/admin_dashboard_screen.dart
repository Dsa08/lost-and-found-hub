import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/app_stats_provider.dart';
import 'moderation_screen.dart';
import 'user_management_screen.dart';
import 'dispute_screen.dart';
import 'transaction_log_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _AdminHomePage(),
    ModerationScreen(),
    UserManagementScreen(),
    DisputeScreen(),
    TransactionLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.pending_actions_rounded), label: 'Moderasi'),
          NavigationDestination(icon: Icon(Icons.people_rounded), label: 'User'),
          NavigationDestination(icon: Icon(Icons.gavel_rounded), label: 'Sengketa'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Log'),
        ],
      ),
    );
  }
}

// ── Admin Home Page ──────────────────────────────────────────────────────────
class _AdminHomePage extends ConsumerWidget {
  const _AdminHomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(appStatsProvider);
    final pendingAsync = ref.watch(pendingItemsProvider);
    final disputesAsync = ref.watch(allDisputesProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: Colors.red, size: 14),
                SizedBox(width: 4),
                Text('ADMIN', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selamat Datang, Admin 👋', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Lost & Found Hub', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  statsAsync.when(
                    data: (stats) => Row(
                      children: [
                        _QuickStat(label: 'Total Item', value: '${stats.totalBarang}', color: AppColors.primary),
                        const SizedBox(width: 16),
                        _QuickStat(label: 'Selesai', value: '${stats.totalSelesai}', color: AppColors.statusActive),
                        const SizedBox(width: 16),
                        _QuickStat(label: 'Guild', value: '${stats.totalGuild}', color: AppColors.bounty),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(color: Colors.white),
                    error: (_, __) => const Text('Error memuat statistik', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('Perlu Perhatian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            // ── Alert Cards ──
            Row(
              children: [
                Expanded(
                  child: _AlertCard(
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.statusPending,
                    label: 'Menunggu Moderasi',
                    value: pendingAsync.when(
                      data: (s) => '${s.docs.length}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AlertCard(
                    icon: Icons.gavel_rounded,
                    color: AppColors.statusLost,
                    label: 'Sengketa Aktif',
                    value: disputesAsync.when(
                      data: (s) => '${s.docs.where((d) => d['status'] == 'Open').length}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AlertCard(
                    icon: Icons.people_rounded,
                    color: AppColors.primary,
                    label: 'Total User',
                    value: usersAsync.when(
                      data: (s) => '${s.docs.length}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Menu Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            // ── Menu Grid ──
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: const [
                _MenuCard(
                  icon: Icons.pending_actions_rounded,
                  label: 'Moderasi\nPostingan',
                  color: AppColors.statusPending,
                  description: 'Approve/reject laporan baru',
                ),
                _MenuCard(
                  icon: Icons.people_rounded,
                  label: 'Kelola\nUser',
                  color: AppColors.primary,
                  description: 'Lihat & edit data pengguna',
                ),
                _MenuCard(
                  icon: Icons.gavel_rounded,
                  label: 'Resolusi\nSengketa',
                  color: AppColors.statusLost,
                  description: 'Handle dispute owner-finder',
                ),
                _MenuCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Log\nTransaksi',
                  color: AppColors.statusActive,
                  description: 'Riwayat perpindahan poin',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _QuickStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ],
  );
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final VoidCallback onTap;
  const _AlertCard({required this.icon, required this.color, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label, description;
  final Color color;
  const _MenuCard({required this.icon, required this.label, required this.color, required this.description});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const Spacer(),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(description, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      ],
    ),
  );
}