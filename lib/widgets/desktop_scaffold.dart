import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_stats_provider.dart';
import '../screens/items/create_item_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';

class DesktopScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final int currentIndex;
  final void Function(int) onNavTap;

  const DesktopScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  ConsumerState<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends ConsumerState<DesktopScaffold> {

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  // Nav items — index harus sinkron dengan _pages di DashboardScreen
  // 0=Beranda, 1=Cari, 2=Laporan Saya, 3=Dompet, 4=Guild
  static const _navItems = [
    _NavEntry(icon: Icons.home_outlined,                   activeIcon: Icons.home_rounded,                          label: 'Beranda'),
    _NavEntry(icon: Icons.search_outlined,                 activeIcon: Icons.search_rounded,                        label: 'Cari'),
    _NavEntry(icon: Icons.list_alt_outlined,               activeIcon: Icons.list_alt_rounded,                      label: 'Laporan Saya'),
    _NavEntry(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded,        label: 'Dompet'),
    _NavEntry(icon: Icons.shield_outlined,                 activeIcon: Icons.shield_rounded,                        label: 'Guild'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final statsAsync = ref.watch(appStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────
          _buildSidebar(user, statsAsync),

          // ── Main Content ─────────────────────────────────────────────
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  Widget _buildSidebar(dynamic user, AsyncValue statsAsync) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          right: BorderSide(color: AppColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo Header ──
          _buildLogoHeader(),

          // ── User Info ──
          if (user != null) _buildUserInfo(user),

          const SizedBox(height: 8),

          // ── Nav Items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                ..._navItems.asMap().entries.map((e) => _buildNavTile(e.key, e.value)),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.divider),
                ),

                // ── Buat Laporan Button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateItemScreen()),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Buat Laporan'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Profile ──
                _buildActionTile(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  color: AppColors.textSecondary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),

                // ── Logout ──
                _buildActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: AppColors.error,
                  onTap: _logout,
                ),
              ],
            ),
          ),

          // ── Stats Footer ──
          _buildStatsFooter(statsAsync),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.find_in_page_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lost & Found',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, height: 1.2),
                ),
                Text(
                  'Hub',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.primaryLight,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              user.nama[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.bounty, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${user.totalPoin} poin',
                      style: const TextStyle(fontSize: 11, color: AppColors.bounty, fontWeight: FontWeight.w600),
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

  Widget _buildNavTile(int index, _NavEntry entry) {
    final isActive = widget.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          title: Text(
            entry.label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          // Active indicator bar + icon on the left
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: isActive ? 24 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isActive ? entry.activeIcon : entry.icon,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 21,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: () => widget.onNavTap(index),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Icon(icon, color: color, size: 21),
      title: Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }

  Widget _buildStatsFooter(AsyncValue statsAsync) {
    return statsAsync.when(
      data: (stats) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SidebarStat(label: 'Item', value: '${stats.totalBarang}'),
            Container(width: 1, height: 28, color: AppColors.divider),
            _SidebarStat(label: 'Selesai', value: '${stats.totalSelesai}'),
            Container(width: 1, height: 28, color: AppColors.divider),
            _SidebarStat(label: 'Guild', value: '${stats.totalGuild}'),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Data class untuk nav entry ───────────────────────────────────────────────
class _NavEntry {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavEntry({required this.icon, required this.activeIcon, required this.label});
}

class _SidebarStat extends StatelessWidget {
  final String label, value;
  const _SidebarStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ],
  );
}