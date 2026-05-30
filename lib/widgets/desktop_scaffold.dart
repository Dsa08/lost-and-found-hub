import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_stats_provider.dart';
import '../screens/items/create_item_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';

/// **DesktopScaffold**
/// Widget layout utama khusus untuk mode Desktop atau Tablet (layar lebar).
/// Menampilkan Sidebar tetap di sisi kiri layar yang berisi menu navigasi utama,
/// tombol 'Buat Laporan', profil, logout, dan ringkasan statistik (Stats Footer).
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
      decoration: const BoxDecoration(
        color: AppColors.sidebarDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(4, 0),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                ..._navItems.asMap().entries.map((e) => _HoverNavTile(
                      index: e.key,
                      entry: e.value,
                      isActive: widget.currentIndex == e.key,
                      onTap: () => widget.onNavTap(e.key),
                    )),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: AppColors.sidebarSurface),
                ),

                // ── Buat Laporan Button ──
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateItemScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Buat Laporan', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Profile ──
                _HoverActionTile(
                  icon: Icons.person_rounded,
                  label: 'Profil Saya',
                  defaultColor: AppColors.sidebarText,
                  hoverColor: AppColors.sidebarTextActive,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),

                // ── Logout ──
                _HoverActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  defaultColor: AppColors.error,
                  hoverColor: const Color(0xFFFF5252),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.sidebarDark,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.find_in_page_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lost & Found',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.2),
                ),
                Text(
                  'Dashboard Workspace',
                  style: TextStyle(color: AppColors.sidebarText, fontSize: 11),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryDark,
            child: Text(
              user.nama[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.sidebarTextActive),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.bounty, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${user.totalPoin} poin',
                      style: const TextStyle(fontSize: 12, color: AppColors.bounty, fontWeight: FontWeight.w600),
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

  Widget _buildStatsFooter(AsyncValue statsAsync) {
    return statsAsync.when(
      data: (stats) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.sidebarSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SidebarStat(label: 'Item', value: '${stats.totalBarang}'),
            Container(width: 1, height: 32, color: AppColors.sidebarText.withValues(alpha: 0.2)),
            _SidebarStat(label: 'Selesai', value: '${stats.totalSelesai}'),
            Container(width: 1, height: 32, color: AppColors.sidebarText.withValues(alpha: 0.2)),
            _SidebarStat(label: 'Guild', value: '${stats.totalGuild}'),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Hover Components ──────────────────────────────────────────────────────

class _HoverNavTile extends StatefulWidget {
  final int index;
  final _NavEntry entry;
  final bool isActive;
  final VoidCallback onTap;

  const _HoverNavTile({required this.index, required this.entry, required this.isActive, required this.onTap});

  @override
  State<_HoverNavTile> createState() => _HoverNavTileState();
}

class _HoverNavTileState extends State<_HoverNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final showHighlight = widget.isActive || _isHovered;
    final color = showHighlight ? AppColors.sidebarTextActive : AppColors.sidebarText;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.primary.withValues(alpha: 0.15) : (_isHovered ? AppColors.glassWhite : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(
              widget.entry.label,
              style: TextStyle(
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                fontSize: 14,
              ),
            ),
            leading: Icon(
              widget.isActive ? widget.entry.activeIcon : widget.entry.icon,
              color: widget.isActive ? AppColors.primary : color,
              size: 20,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

class _HoverActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color defaultColor;
  final Color hoverColor;
  final VoidCallback onTap;

  const _HoverActionTile({required this.icon, required this.label, required this.defaultColor, required this.hoverColor, required this.onTap});

  @override
  State<_HoverActionTile> createState() => _HoverActionTileState();
}

class _HoverActionTileState extends State<_HoverActionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.glassWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Icon(widget.icon, color: _isHovered ? widget.hoverColor : widget.defaultColor, size: 20),
          title: Text(widget.label, style: TextStyle(fontSize: 14, color: _isHovered ? widget.hoverColor : widget.defaultColor, fontWeight: FontWeight.w500)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: widget.onTap,
        ),
      ),
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
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.sidebarText)),
    ],
  );
}