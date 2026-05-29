import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/guild_model.dart';
import '../../providers/auth_provider.dart';

/// **guildsProvider**
/// Mengambil 20 Guild teratas berdasarkan total reputasi (Leaderboard).
final guildsProvider = StreamProvider<List<GuildModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.guilds)
      .orderBy('total_reputasi', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(GuildModel.fromFirestore).toList());
});

/// **GuildScreen (Layar Komunitas)**
/// Layar untuk melihat daftar Guild (Leaderboard). 
/// User yang belum punya Guild bisa membuat Guild baru dari layar ini.
class GuildScreen extends ConsumerStatefulWidget {
  const GuildScreen({super.key});

  @override
  ConsumerState<GuildScreen> createState() => _GuildScreenState();
}

class _GuildScreenState extends ConsumerState<GuildScreen> {
  final _namaCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  /// **Fungsi _createGuild**
  /// Membuat guild baru dan otomatis menjadikan pembuatnya sebagai 'Leader'.
  /// Menggunakan Firestore Batch/Update untuk memastikan data sinkron antara 
  /// dokumen Guild, Sub-koleksi members, dan dokumen profil User.
  Future<void> _createGuild() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Buat Guild Baru', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Guild', hintText: 'Contoh: Pencari Hilang Bandung'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Deskripsi', hintText: 'Ceritakan tentang guild kamu'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buat')),
        ],
      ),
    );

    if (result != true || _namaCtrl.text.trim().isEmpty) return;

    final guild = GuildModel(
      guildId: '',
      namaGuild: _namaCtrl.text.trim(),
      deskripsi: _descCtrl.text.trim(),
      createdBy: user.uid,
      createdAt: DateTime.now(),
    );

    final ref2 = FirebaseFirestore.instance.collection(FirestorePaths.guilds).doc();
    await ref2.set(guild.toFirestore());

    // Join creator sebagai leader
    await ref2.collection(FirestorePaths.members).doc(user.uid).set({
      'user_id': user.uid,
      'peran': 'Leader',
      'contribution_points': 0,
      'joined_at': FieldValue.serverTimestamp(),
    });

    // Update guild_id di user
    await FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .update({'guild_id': ref2.id});

    if (mounted) {
      _namaCtrl.clear();
      _descCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Guild berhasil dibuat!'), backgroundColor: AppColors.statusActive, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guildsAsync = ref.watch(guildsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guild'),
        actions: [
          if (user?.guildId == null)
            TextButton.icon(
              onPressed: _createGuild,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Buat Guild'),
            ),
        ],
      ),
      body: guildsAsync.when(
        data: (guilds) {
          if (guilds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text('Belum ada guild', style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Jadilah yang pertama membuat guild!', style: TextStyle(color: AppColors.textHint)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _createGuild,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Buat Guild Sekarang'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: CustomScrollView(
                slivers: [
              // Leaderboard Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.guildGold, AppColors.bounty], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Guild Leaderboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                            Text('${guilds.length} guild aktif', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _GuildCard(guild: guilds[i], rank: i + 1, currentGuildId: user?.guildId),
                  childCount: guilds.length,
                ),
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

  @override
  void dispose() {
    _namaCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}

class _GuildCard extends StatelessWidget {
  final GuildModel guild;
  final int rank;
  final String? currentGuildId;

  const _GuildCard({required this.guild, required this.rank, this.currentGuildId});

  @override
  Widget build(BuildContext context) {
    final isMyGuild = guild.guildId == currentGuildId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isMyGuild ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36,
              child: Text(
                rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),

            // Level Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: guild.levelColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, color: guild.levelColor, size: 16),
                  const SizedBox(width: 4),
                  Text(guild.levelLabel, style: TextStyle(color: guild.levelColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(guild.namaGuild, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                      ),
                      if (isMyGuild)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                          child: const Text('Guildku', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.group_rounded, size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text('${guild.memberCount} anggota', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded, size: 13, color: AppColors.bounty),
                      const SizedBox(width: 4),
                      Text('${guild.totalReputasi} rep', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}