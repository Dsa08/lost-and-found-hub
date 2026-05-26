import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/app_stats_provider.dart';
import '../../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
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

  static const List<Widget> _pages = [
    _AdminHomePage(),
    ModerationScreen(),
    UserManagementScreen(),
    DisputeScreen(),
    TransactionLogScreen(),
  ];

  void _onNavTap(int i) => setState(() => _currentIndex = i);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      return _AdminDesktopLayout(
        currentIndex: _currentIndex,
        onNavTap: _onNavTap,
        body: IndexedStack(index: _currentIndex, children: _pages),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavTap,
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: Colors.white.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Colors.white),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.pending_actions_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.pending_actions_rounded, color: Colors.white),
            label: 'Moderasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: Colors.white54),
            selectedIcon: Icon(Icons.people_rounded, color: Colors.white),
            label: 'User',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.gavel_rounded, color: Colors.white),
            label: 'Sengketa',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: Colors.white),
            label: 'Log',
          ),
        ],
      ),
    );
  }
}

// ── Desktop Sidebar Layout ────────────────────────────────────────────────────
class _AdminDesktopLayout extends ConsumerStatefulWidget {
  final Widget body;
  final int currentIndex;
  final void Function(int) onNavTap;

  const _AdminDesktopLayout({
    required this.body,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  ConsumerState<_AdminDesktopLayout> createState() => _AdminDesktopLayoutState();
}

class _AdminDesktopLayoutState extends ConsumerState<_AdminDesktopLayout> {
  static const _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.pending_actions_outlined, Icons.pending_actions_rounded, 'Moderasi'),
    (Icons.people_outline, Icons.people_rounded, 'Kelola User'),
    (Icons.gavel_outlined, Icons.gavel_rounded, 'Sengketa'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Log Transaksi'),
  ];

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Admin Sidebar ─────────────────────────────────────────────
          Container(
            width: 240,
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          Text('Panel', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                // User info
                if (user != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Text(user.nama[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.nama, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              const Text('Administrator', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    children: [
                      ..._navItems.asMap().entries.map((e) {
                        final i = e.key;
                        final item = e.value;
                        final isActive = widget.currentIndex == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              leading: Icon(
                                isActive ? item.$2 : item.$1,
                                color: isActive ? Colors.white : Colors.white54,
                                size: 20,
                              ),
                              title: Text(
                                item.$3,
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.white70,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onTap: () => widget.onNavTap(i),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Logout
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: InkWell(
                    onTap: _logout,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                          SizedBox(width: 10),
                          Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content ─────────────────────────────────────────────
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}

// ── Admin Home Page ───────────────────────────────────────────────────────────
class _AdminHomePage extends ConsumerWidget {
  const _AdminHomePage();

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Kamu akan keluar dari admin panel.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authRepositoryProvider).logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  // Ambil parent state untuk navigasi antar tab
  static _AdminDashboardScreenState? _findParentState(BuildContext context) {
    return context.findAncestorStateOfType<_AdminDashboardScreenState>();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(appStatsProvider);
    final pendingAsync = ref.watch(pendingItemsProvider);
    final disputesAsync = ref.watch(allDisputesProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => _logout(context, ref),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    user?.nama.split(' ').first ?? 'Admin',
                    style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Banner ──
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
                  Text(
                    'Selamat Datang, ${user?.nama.split(' ').first ?? 'Admin'} 👋',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
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
                    error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('Perlu Perhatian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            // ── Alert Cards — onTap sudah berfungsi ──
            Row(
              children: [
                Expanded(
                  child: _AlertCard(
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.statusPending,
                    label: 'Menunggu\nModerasi',
                    value: pendingAsync.when(
                      data: (s) => '${s.docs.length}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    onTap: () => _findParentState(context)?._onNavTap(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AlertCard(
                    icon: Icons.gavel_rounded,
                    color: AppColors.statusLost,
                    label: 'Sengketa\nAktif',
                    value: disputesAsync.when(
                      data: (s) => '${s.docs.where((d) => d['status'] == 'Open').length}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    onTap: () => _findParentState(context)?._onNavTap(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AlertCard(
                    icon: Icons.people_rounded,
                    color: AppColors.primary,
                    label: 'Total\nUser',
                    value: usersAsync.when(
                      data: (s) => '${s.docs.length}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    onTap: () => _findParentState(context)?._onNavTap(2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Menu Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            // ── Menu Grid — navigasi via tab index ──
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isDesktop ? 1.6 : 1.5,
              children: [
                _MenuCard(
                  icon: Icons.pending_actions_rounded,
                  label: 'Moderasi',
                  color: AppColors.statusPending,
                  description: 'Approve/reject laporan',
                  onTap: () => _findParentState(context)?._onNavTap(1),
                ),
                _MenuCard(
                  icon: Icons.people_rounded,
                  label: 'Kelola User',
                  color: AppColors.primary,
                  description: 'Lihat & edit pengguna',
                  onTap: () => _findParentState(context)?._onNavTap(2),
                ),
                _MenuCard(
                  icon: Icons.gavel_rounded,
                  label: 'Sengketa',
                  color: AppColors.statusLost,
                  description: 'Handle dispute',
                  onTap: () => _findParentState(context)?._onNavTap(3),
                ),
                _MenuCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Log Transaksi',
                  color: AppColors.statusActive,
                  description: 'Riwayat poin',
                  onTap: () => _findParentState(context)?._onNavTap(4),
                ),
              ],
            ),

            const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.6), size: 10),
        ],
      ),
    ),
  );
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label, description;
  final Color color;
  final VoidCallback onTap;
  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(description, style: const TextStyle(fontSize: 10, color: AppColors.textHint), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 18),
        ],
      ),
    ),
  );
}