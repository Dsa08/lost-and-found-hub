import 'dart:async';
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

/// **AdminDashboardScreen (Layar Utama Admin)**
/// Ini adalah layar induk (wrapper) untuk seluruh panel admin.
/// Layar ini mendukung responsivitas:
/// - Desktop: Menampilkan Sidebar di kiri dan konten di kanan.
/// - Mobile: Menampilkan BottomNavigationBar di bawah.
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

  static const _pageTitles = [
    'Dashboard',
    'Moderasi Postingan',
    'Kelola User',
    'Resolusi Sengketa',
    'Log Transaksi',
  ];

  void _onNavTap(int i) => setState(() => _currentIndex = i);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      return _AdminDesktopLayout(
        currentIndex: _currentIndex,
        onNavTap: _onNavTap,
        pageTitle: _pageTitles[_currentIndex],
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

// ══════════════════════════════════════════════════════════════════════════════
// ── Desktop Layout with Premium Sidebar + Top Bar ─────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _AdminDesktopLayout extends ConsumerStatefulWidget {
  final Widget body;
  final int currentIndex;
  final String pageTitle;
  final void Function(int) onNavTap;

  const _AdminDesktopLayout({
    required this.body,
    required this.currentIndex,
    required this.pageTitle,
    required this.onNavTap,
  });

  @override
  ConsumerState<_AdminDesktopLayout> createState() => _AdminDesktopLayoutState();
}

class _AdminDesktopLayoutState extends ConsumerState<_AdminDesktopLayout> {
  int _hoveredIndex = -1;
  late Timer _clockTimer;
  String _timeString = '';

  static const _navSections = [
    _NavSection('MENU UTAMA', [
      _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard', 0),
      _NavItem(Icons.pending_actions_outlined, Icons.pending_actions_rounded, 'Moderasi', 1),
    ]),
    _NavSection('MANAJEMEN', [
      _NavItem(Icons.people_outline, Icons.people_rounded, 'Kelola User', 2),
      _NavItem(Icons.gavel_outlined, Icons.gavel_rounded, 'Sengketa', 3),
      _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Log Transaksi', 4),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    setState(() {
      _timeString = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _logout() async {
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
    if (confirm != true) return;
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
          // ── Premium Sidebar ─────────────────────────────────────────
          _buildSidebar(user),

          // ── Content Area ───────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _buildTopBar(user),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SIDEBAR ──────────────────────────────────────────────────────────────
  Widget _buildSidebar(dynamic user) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x30000000), blurRadius: 20, offset: Offset(4, 0)),
        ],
      ),
      child: Column(
        children: [
          // ── Logo Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
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
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                    Text('Lost & Found Hub', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.3)),
                  ],
                ),
              ],
            ),
          ),

          // ── User Card ──
          if (user != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4A90E2)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        user.nama[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.nama, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.statusActive.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Administrator', style: TextStyle(color: AppColors.statusActive, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),

          // ── Nav Sections ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                for (final section in _navSections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Text(
                      section.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  for (final item in section.items) _buildNavItem(item),
                ],
              ],
            ),
          ),

          // ── Logout ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 16),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Branding ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Text(
              'Lost & Found Hub v1.0',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item) {
    final isActive = widget.currentIndex == item.index;
    final isHovered = _hoveredIndex == item.index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredIndex = item.index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: GestureDetector(
          onTap: () => widget.onNavTap(item.index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : isHovered
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Active indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: 3,
                  height: isActive ? 24 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isActive
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 6)]
                        : [],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: isActive ? AppColors.primary : (isHovered ? Colors.white70 : Colors.white38),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : (isHovered ? Colors.white : Colors.white60),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 4)],
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(dynamic user) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.7))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Breadcrumb
          Row(
            children: [
              const Text('Admin', style: TextStyle(color: AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.textHint.withValues(alpha: 0.5), size: 18),
              ),
              Text(widget.pageTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),

          const Spacer(),

          // Date & Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(_timeString, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // User Avatar
          if (user != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.primary,
                    child: Text(user.nama[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Text(user.nama.split(' ').first, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Nav Data Models ──────────────────────────────────────────────────────────
class _NavSection {
  final String label;
  final List<_NavItem> items;
  const _NavSection(this.label, this.items);
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  const _NavItem(this.icon, this.activeIcon, this.label, this.index);
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Admin Home Page (Dashboard) ───────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
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

  static _AdminDashboardScreenState? _findParentState(BuildContext context) {
    return context.findAncestorStateOfType<_AdminDashboardScreenState>();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(appStatsProvider);
    final pendingAsync = ref.watch(pendingItemsProvider);
    // REFAKTOR: Tidak lagi menggunakan allDisputesProvider/allUsersProvider
    // yang men-download SELURUH data. Sekarang angka diambil dari appStatsProvider
    // yang menggunakan count() query (efisien, tanpa download dokumen).
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
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Banner ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 28 : 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1A1A2E).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang, ${user?.nama.split(' ').first ?? 'Admin'} 👋',
                          style: TextStyle(color: Colors.white70, fontSize: isDesktop ? 15 : 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Lost & Found Hub',
                          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 26 : 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola laporan, user, dan sengketa dari satu tempat.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 20),
                    // Stats inline
                    statsAsync.when(
                      data: (stats) => Row(
                        children: [
                          _StatBadge(label: 'Total Item', value: '${stats.totalBarang}', icon: Icons.inventory_2_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          _StatBadge(label: 'Selesai', value: '${stats.totalSelesai}', icon: Icons.check_circle_rounded, color: AppColors.statusActive),
                          const SizedBox(width: 12),
                          _StatBadge(label: 'Guild', value: '${stats.totalGuild}', icon: Icons.shield_rounded, color: AppColors.bounty),
                        ],
                      ),
                      loading: () => const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),

            // Mobile stats (only show on mobile)
            if (!isDesktop) ...[
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
                loading: () => const CircularProgressIndicator(color: AppColors.primary),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],

            SizedBox(height: isDesktop ? 28 : 20),
            Text('Perlu Perhatian', style: TextStyle(fontSize: isDesktop ? 18 : 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            SizedBox(height: isDesktop ? 16 : 12),

            // ── Alert Cards ──
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
                    isDesktop: isDesktop,
                    onTap: () => _findParentState(context)?._onNavTap(1),
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: _AlertCard(
                    icon: Icons.gavel_rounded,
                    color: AppColors.statusLost,
                    label: 'Sengketa\nAktif',
                    // REFAKTOR: Menggunakan count() dari appStatsProvider
                    value: statsAsync.when(
                      data: (s) => '${s.openDisputes}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    isDesktop: isDesktop,
                    onTap: () => _findParentState(context)?._onNavTap(3),
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: _AlertCard(
                    icon: Icons.people_rounded,
                    color: AppColors.primary,
                    label: 'Total\nUser',
                    // REFAKTOR: Menggunakan count() dari appStatsProvider
                    value: statsAsync.when(
                      data: (s) => '${s.totalUsers}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    isDesktop: isDesktop,
                    onTap: () => _findParentState(context)?._onNavTap(2),
                  ),
                ),
              ],
            ),

            SizedBox(height: isDesktop ? 32 : 24),
            Text('Menu Admin', style: TextStyle(fontSize: isDesktop ? 18 : 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            SizedBox(height: isDesktop ? 16 : 12),

            // ── Menu Grid ──
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: isDesktop ? 16 : 12,
              mainAxisSpacing: isDesktop ? 16 : 12,
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

// ══════════════════════════════════════════════════════════════════════════════
// ── Shared Widgets ────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _StatBadge extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    ),
  );
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
      Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
    ],
  );
}

class _AlertCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final bool isDesktop;
  final VoidCallback onTap;
  const _AlertCard({required this.icon, required this.color, required this.label, required this.value, this.isDesktop = false, required this.onTap});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _isHovered = true),
    onExit: (_) => setState(() => _isHovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(widget.isDesktop ? 16 : 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.color.withValues(alpha: _isHovered ? 0.5 : 0.2)),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _isHovered ? 0.12 : 0.05),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: widget.color, size: widget.isDesktop ? 24 : 20),
            ),
            SizedBox(height: widget.isDesktop ? 10 : 6),
            Text(widget.value, style: TextStyle(color: widget.color, fontSize: widget.isDesktop ? 24 : 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(widget.label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Icon(Icons.arrow_forward_ios_rounded, color: widget.color.withValues(alpha: 0.5), size: 10),
          ],
        ),
      ),
    ),
  );
}

class _MenuCard extends StatefulWidget {
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
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _isHovered = true),
    onExit: (_) => setState(() => _isHovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        transform: _isHovered ? Matrix4.diagonal3Values(1.02, 1.02, 1.0) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _isHovered ? widget.color.withValues(alpha: 0.3) : AppColors.divider.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 4 : 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(widget.description, style: const TextStyle(fontSize: 10, color: AppColors.textHint), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: widget.color.withValues(alpha: _isHovered ? 0.8 : 0.4), size: 18),
          ],
        ),
      ),
    ),
  );
}
