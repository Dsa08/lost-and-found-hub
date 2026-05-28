import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/app_stats_provider.dart';
import '../../widgets/item_card.dart';
import '../../widgets/category_filter.dart';
import '../../widgets/desktop_scaffold.dart';
import '../items/create_item_screen.dart';
import '../items/item_detail_screen.dart';
import '../items/my_items_screen.dart';
import '../wallet/wallet_screen.dart';
import '../guild/guild_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  // Pages: index 0-4 dipakai langsung (tidak ada FAB placeholder)
  // 0 = Beranda, 1 = Cari, 2 = Laporan Saya, 3 = Dompet, 4 = Guild
  static const List<Widget> _pages = [
    _HomePage(),
    _SearchPage(),
    MyItemsScreen(),
    WalletScreen(),
    GuildScreen(),
  ];

  void _onNavTap(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      return DesktopScaffold(
        currentIndex: _currentIndex,
        onNavTap: _onNavTap,
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      );
    }

    // ── Mobile Layout ──────────────────────────────────────────────────
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavTap,
        backgroundColor: AppColors.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        indicatorColor: AppColors.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Cari',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Dompet',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Guild',
          ),
        ],
      ),
    );
  }
}

// ── Home Page ─────────────────────────────────────────────────────────────────
class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final filter = ref.watch(itemFilterProvider);
    final itemsAsync = ref.watch(activeItemsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 16, isDesktop ? 24 : 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${user?.nama.split(' ').first ?? 'Pengguna'}! 👋',
                            style: TextStyle(
                              fontSize: isDesktop ? 24 : 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Ada barang hilang hari ini?',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Poin widget
                    if (user != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bountyLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.bounty.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.bounty, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${user.totalPoin}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF7B5800), fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Avatar → tap buka ProfileScreen
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (user?.nama.isNotEmpty == true) ? user!.nama[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    // Tombol Buat Laporan di header (mobile, menggantikan FAB)
                    if (!isDesktop) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateItemScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Stats Banner (real-time) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 16, isDesktop ? 24 : 16, 0),
                child: const _StatsBanner(),
              ),
            ),

            // ── Banner laporan pending milik user ──
            if (user != null)
              SliverToBoxAdapter(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('items')
                      .where('owner_id', isEqualTo: user.uid)
                      .where('is_approved', isEqualTo: false)
                      .where('status', isEqualTo: 'pendingApproval')
                      .snapshots(),
                  builder: (ctx, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      margin: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 12, isDesktop ? 24 : 16, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusPending.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusPending.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pending_actions_rounded, color: AppColors.statusPending, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$count laporan menunggu persetujuan admin',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.statusPending),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // ── Filter Toggle ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 16, isDesktop ? 24 : 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _TipeToggle(
                        label: 'Barang Hilang',
                        icon: Icons.search_off_rounded,
                        isSelected: filter.tipe == TipeLaporan.lost,
                        color: AppColors.statusLost,
                        onTap: () => ref.read(itemFilterProvider.notifier).state =
                            filter.copyWith(tipe: filter.tipe == TipeLaporan.lost ? null : TipeLaporan.lost),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TipeToggle(
                        label: 'Barang Temuan',
                        icon: Icons.inventory_2_outlined,
                        isSelected: filter.tipe == TipeLaporan.found,
                        color: AppColors.statusFound,
                        onTap: () => ref.read(itemFilterProvider.notifier).state =
                            filter.copyWith(tipe: filter.tipe == TipeLaporan.found ? null : TipeLaporan.found),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category Filter ──
            SliverToBoxAdapter(
              child: CategoryFilter(
                selected: filter.kategori,
                onChanged: (k) => ref.read(itemFilterProvider.notifier).state = filter.copyWith(kategori: k),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Items List (desktop: 2 kolom, mobile: 1 kolom) ──
            itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text('Belum ada laporan', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                          const Text('Jadilah yang pertama!', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                if (isDesktop) {
                  // Desktop: 2-column grid
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.6,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => ItemCard(
                          item: items[i],
                          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: items[i].itemId))),
                        ),
                        childCount: items.length,
                      ),
                    ),
                  );
                }

                // Mobile: list biasa
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => ItemCard(
                      item: items[i],
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: items[i].itemId))),
                    ),
                    childCount: items.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ── Stats Banner REAL-TIME ────────────────────────────────────────────────────
class _StatsBanner extends ConsumerWidget {
  const _StatsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(appStatsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: statsAsync.when(
        data: (stats) => Row(
          children: [
            Expanded(child: _StatItem(label: 'Barang\nDilaporkan', value: '${stats.totalBarang}', icon: Icons.list_alt_rounded)),
            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
            Expanded(child: _StatItem(label: 'Berhasil\nDiselesaikan', value: '${stats.totalSelesai}', icon: Icons.check_circle_outline_rounded)),
            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
            Expanded(child: _StatItem(label: 'Guild\nAktif', value: '${stats.totalGuild}', icon: Icons.shield_rounded)),
          ],
        ),
        loading: () => const Center(
          child: SizedBox(height: 40, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
        ),
        error: (_, __) => Row(
          children: [
            const Expanded(child: _StatItem(label: 'Barang\nDilaporkan', value: '-', icon: Icons.list_alt_rounded)),
            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
            const Expanded(child: _StatItem(label: 'Berhasil\nDiselesaikan', value: '-', icon: Icons.check_circle_outline_rounded)),
            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
            const Expanded(child: _StatItem(label: 'Guild\nAktif', value: '-', icon: Icons.shield_rounded)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
    ],
  );
}

class _TipeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TipeToggle({required this.label, required this.icon, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? color : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: isSelected ? color : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? color : AppColors.textSecondary)),
        ],
      ),
    ),
  );
}

// ── Search Page ───────────────────────────────────────────────────────────────
class _SearchPage extends ConsumerStatefulWidget {
  const _SearchPage();
  @override
  ConsumerState<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<_SearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(activeItemsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Cari barang...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _query.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _ctrl.clear(); setState(() => _query = ''); })
                : null,
          ),
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          final filtered = _query.isEmpty ? items : items.where((i) =>
            i.judul.toLowerCase().contains(_query) ||
            i.deskripsi.toLowerCase().contains(_query) ||
            i.lokasi.namaLokasi.toLowerCase().contains(_query)).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(_query.isEmpty ? 'Mulai ketik untuk mencari' : 'Tidak ditemukan: "$_query"',
                    style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          if (isDesktop) {
            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.6,
              ),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => ItemCard(
                item: filtered[i],
                onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: filtered[i].itemId))),
              ),
            );
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => ItemCard(
              item: filtered[i],
              onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: filtered[i].itemId))),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}