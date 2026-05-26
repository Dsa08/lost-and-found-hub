import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_stats_provider.dart';
import '../screens/items/create_item_screen.dart';
import '../screens/items/my_items_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/guild/guild_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final statsAsync = ref.watch(appStatsProvider);

    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'Beranda'},
      {'icon': Icons.search_rounded, 'label': 'Cari'},
      {'icon': Icons.list_alt_rounded, 'label': 'Laporan Saya'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Dompet'},
      {'icon': Icons.shield_rounded, 'label': 'Guild'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF4A90E2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.find_in_page_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lost & Found', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                            Text('Hub', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // User info
                if (user != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.primaryLight,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(user.nama[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.nama, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.bounty, size: 14),
                                  const SizedBox(width: 2),
                                  Text('${user.totalPoin} poin', style: const TextStyle(fontSize: 11, color: AppColors.bounty, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      ...navItems.asMap().entries.map((e) {
                        final i = e.key;
                        final item = e.value;
                        final isActive = widget.currentIndex == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            leading: Icon(
                              item['icon'] as IconData,
                              color: isActive ? AppColors.primary : AppColors.textSecondary,
                              size: 22,
                            ),
                            title: Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? AppColors.primary : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            selected: isActive,
                            selectedTileColor: AppColors.primaryLight,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onTap: () => widget.onNavTap(i),
                          ),
                        );
                      }),

                      const Divider(height: 24),

                      // Buat Laporan button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CreateItemScreen())),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Buat Laporan'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Profil & Logout
                      ListTile(
                        leading: const Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 22),
                        title: const Text('Profil', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                        title: const Text('Logout', style: TextStyle(fontSize: 14, color: AppColors.error)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),

                // Stats di bawah sidebar
                statsAsync.when(
                  data: (stats) => Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SidebarStat(label: 'Item', value: '${stats.totalBarang}'),
                        _SidebarStat(label: 'Selesai', value: '${stats.totalSelesai}'),
                        _SidebarStat(label: 'Guild', value: '${stats.totalGuild}'),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Main Content ────────────────────────────────────────────────
          Expanded(
            child: widget.body,
          ),
        ],
      ),
    );
  }
}

class _SidebarStat extends StatelessWidget {
  final String label, value;
  const _SidebarStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ],
  );
}