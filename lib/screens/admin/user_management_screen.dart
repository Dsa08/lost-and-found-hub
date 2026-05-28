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

  // ── Edit Poin ──────────────────────────────────────────────────────────────
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
          ElevatedButton(onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)), child: const Text('Simpan')),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    await FirebaseFirestore.instance.collection(FirestorePaths.users).doc(userId).update({'total_poin': result});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Poin diubah menjadi $result'), backgroundColor: AppColors.statusActive, behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ── Edit Role ──────────────────────────────────────────────────────────────
  Future<void> _editRole(BuildContext context, String userId, String currentRole) async {
    final roles = ['user', 'moderator', 'vip'];
    String selected = currentRole;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Role User', style: TextStyle(fontWeight: FontWeight.w700)),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: roles.map((role) {
              final isSelected = selected == role;
              return GestureDetector(
                onTap: () => setState(() => selected = role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? AppColors.primary : AppColors.textHint,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Simpan')),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    await FirebaseFirestore.instance.collection(FirestorePaths.users).doc(userId).update({'role': result});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Role diubah ke ${result.toUpperCase()}'), backgroundColor: AppColors.statusActive, behavior: SnackBarBehavior.floating),
    );
  }

  // ── Suspend User ───────────────────────────────────────────────────────────
  Future<void> _suspendUser(BuildContext context, String userId, String nama, {bool alreadySuspended = false, DateTime? currentSuspendUntil}) async {
    int selectedDays = 1;
    final days = [1, 3, 7, 14, 30];

    // Jika sudah suspend, tampilkan info dan tanya apakah extend
    if (alreadySuspended && currentSuspendUntil != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('User Sudah Disuspend', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Text(
            '$nama saat ini masih disuspend hingga ${currentSuspendUntil.day}/${currentSuspendUntil.month}/${currentSuspendUntil.year}.\n\nApakah kamu ingin memperpanjang/mengubah durasi suspend?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusPending),
              child: const Text('Ubah Durasi'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      if (!context.mounted) return;
    }

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Suspend $nama', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih durasi suspend:', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: days.map((d) => ChoiceChip(
                  label: Text('$d hari'),
                  selected: selectedDays == d,
                  selectedColor: AppColors.statusPending.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => selectedDays = d),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selectedDays),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusPending),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;

    final until = DateTime.now().add(Duration(days: result));
    await FirebaseFirestore.instance.collection(FirestorePaths.users).doc(userId).update({
      'is_suspended': true,
      'suspended_until': Timestamp.fromDate(until),
      'suspend_reason': 'Suspended by admin for $result days',
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $nama disuspend $result hari'),
          backgroundColor: AppColors.statusPending,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Blokir/Unblokir User ───────────────────────────────────────────────────
  Future<void> _toggleBlock(BuildContext context, String userId, String nama, bool isBlocked) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBlocked ? 'Buka Blokir $nama?' : 'Blokir $nama?', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(isBlocked
            ? 'User ini akan bisa menggunakan aplikasi kembali.'
            : 'User ini tidak akan bisa login dan menggunakan aplikasi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: isBlocked ? AppColors.statusActive : AppColors.error),
            child: Text(isBlocked ? 'Buka Blokir' : 'Blokir'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await FirebaseFirestore.instance.collection(FirestorePaths.users).doc(userId).update({
      'is_blocked': !isBlocked,
      'blocked_at': isBlocked ? null : FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBlocked ? '✅ $nama berhasil dibuka blokirnya' : '🚫 $nama berhasil diblokir'),
          backgroundColor: isBlocked ? AppColors.statusActive : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Detail Sheet ───────────────────────────────────────────────────────────
  void _showUserDetail(BuildContext context, Map<String, dynamic> data, String userId) {
    final isBlocked = data['is_blocked'] == true;
    final isSuspended = data['is_suspended'] == true;
    final suspendedUntil = (data['suspended_until'] as Timestamp?)?.toDate();
    final stillSuspended = isSuspended && suspendedUntil != null && DateTime.now().isBefore(suspendedUntil);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Avatar + nama
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isBlocked ? AppColors.error : AppColors.primary,
                  child: Text((data['nama'] as String? ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['nama'] ?? '-', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('@${data['username'] ?? '-'}', style: const TextStyle(color: AppColors.textSecondary)),
                      // Status badge
                      if (isBlocked)
                        const _StatusChip(label: 'DIBLOKIR', color: AppColors.error)
                      else if (stillSuspended)
                        _StatusChip(label: 'DISUSPEND s/d ${suspendedUntil.day}/${suspendedUntil.month}', color: AppColors.statusPending)
                      else
                        _StatusChip(label: data['role']?.toString().toUpperCase() ?? 'USER', color: AppColors.statusActive),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            _DetailRow('Email', data['email'] ?? '-'),
            _DetailRow('No. HP', data['no_hp'] ?? '-'),
            _DetailRow('Total Poin', '${data['total_poin'] ?? 0} poin'),
            _DetailRow('Locked Poin', '${data['locked_poin'] ?? 0} poin'),
            _DetailRow('Guild', data['guild_id'] ?? 'Tidak bergabung'),
            _DetailRow('Total Laporan', '${(data['stats'] as Map?)?['total_reports'] ?? 0}'),
            _DetailRow('Diselesaikan', '${(data['stats'] as Map?)?['total_resolved'] ?? 0}'),

            const SizedBox(height: 20),

            // ── Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _editPoin(context, userId, data['total_poin'] ?? 0); },
                    icon: const Icon(Icons.star_rounded, size: 16, color: AppColors.bounty),
                    label: const Text('Edit Poin', style: TextStyle(color: AppColors.bounty)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.bounty)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _editRole(context, userId, data['role'] ?? 'user'); },
                    icon: const Icon(Icons.manage_accounts_rounded, size: 16, color: AppColors.primary),
                    label: const Text('Edit Role', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _suspendUser(context, userId, data['nama'] ?? '', alreadySuspended: stillSuspended, currentSuspendUntil: suspendedUntil); },
                    icon: const Icon(Icons.timer_off_rounded, size: 16, color: AppColors.statusPending),
                    label: const Text('Suspend', style: TextStyle(color: AppColors.statusPending)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.statusPending)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _toggleBlock(context, userId, data['nama'] ?? '', isBlocked); },
                    icon: Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 16),
                    label: Text(isBlocked ? 'Buka Blokir' : 'Blokir'),
                    style: ElevatedButton.styleFrom(backgroundColor: isBlocked ? AppColors.statusActive : AppColors.error),
                  ),
                ),
              ],
            ),
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

                if (docs.isEmpty) return const Center(child: Text('Tidak ada user ditemukan'));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data();
                    final userId = docs[i].id;
                    final isBlocked = data['is_blocked'] == true;
                    final isSuspended = data['is_suspended'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: isBlocked ? Border.all(color: AppColors.error.withValues(alpha: 0.3)) : null,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: isBlocked ? AppColors.error : AppColors.primary,
                          child: Text((data['nama'] as String? ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                        title: Row(
                          children: [
                            Text(data['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(width: 6),
                            if (isBlocked) const _StatusChip(label: 'BLOKIR', color: AppColors.error)
                            else if (isSuspended) const _StatusChip(label: 'SUSPEND', color: AppColors.statusPending),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Text('@${data['username'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            const Icon(Icons.star_rounded, size: 12, color: AppColors.bounty),
                            Text(' ${data['total_poin'] ?? 0}', style: const TextStyle(fontSize: 11, color: AppColors.bounty, fontWeight: FontWeight.w600)),
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );
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
