import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../providers/admin_provider.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _search = '';

  Future<void> _editPoin(BuildContext context, String userId, int currentPoin) async {
    final ctrl = TextEditingController(text: '$currentPoin');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Total Poin', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah Poin', suffixText: 'poin'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == null) return;

    await FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .doc(userId)
        .update({'total_poin': result});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Poin diubah menjadi $result'), backgroundColor: AppColors.statusActive, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _showUserDetail(BuildContext context, Map<String, dynamic> data, String userId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),

            // Avatar + nama
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (data['nama'] as String? ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['nama'] ?? '-', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text('@${data['username'] ?? '-'}', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            _DetailRow('Email', data['email'] ?? '-'),
            _DetailRow('No. HP', data['no_hp'] ?? '-'),
            _DetailRow('Total Poin', '${data['total_poin'] ?? 0} poin'),
            _DetailRow('Locked Poin', '${data['locked_poin'] ?? 0} poin'),
            _DetailRow('Guild ID', data['guild_id'] ?? 'Tidak bergabung'),
            _DetailRow('Total Laporan', '${(data['stats'] as Map?)?['total_reports'] ?? 0}'),
            _DetailRow('Diselesaikan', '${(data['stats'] as Map?)?['total_resolved'] ?? 0}'),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _editPoin(context, userId, data['total_poin'] ?? 0);
                    },
                    icon: const Icon(Icons.star_rounded, size: 16, color: AppColors.bounty),
                    label: const Text('Edit Poin', style: TextStyle(color: AppColors.bounty)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.bounty)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Tutup'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola User'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari user...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          Expanded(
            child: usersAsync.when(
              data: (snapshot) {
                final docs = snapshot.docs.where((doc) {
                  final data = doc.data();
                  if (_search.isEmpty) return true;
                  return (data['nama'] ?? '').toString().toLowerCase().contains(_search) ||
                      (data['username'] ?? '').toString().toLowerCase().contains(_search) ||
                      (data['email'] ?? '').toString().toLowerCase().contains(_search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('Tidak ada user ditemukan', style: TextStyle(color: AppColors.textSecondary)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data();
                    final userId = docs[i].id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (data['nama'] as String? ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(data['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@${data['username'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: AppColors.bounty),
                                const SizedBox(width: 2),
                                Text('${data['total_poin'] ?? 0} poin', style: const TextStyle(fontSize: 11, color: AppColors.bounty, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                          onPressed: () => _showUserDetail(context, data, userId),
                        ),
                        onTap: () => _showUserDetail(context, data, userId),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
      ],
    ),
  );
}