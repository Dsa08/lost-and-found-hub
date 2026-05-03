import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _namaCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _usernameCtrl.dispose();
    _noHpCtrl.dispose();
    super.dispose();
  }

  void _startEdit(user) {
    _namaCtrl.text = user.nama;
    _usernameCtrl.text = user.username;
    _noHpCtrl.text = user.noHp;
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile(String uid) async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(uid)
          .update({
        'nama': _namaCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'no_hp': _noHpCtrl.text.trim(),
      });
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil berhasil diperbarui!'),
            backgroundColor: AppColors.statusActive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Akun?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Kamu akan keluar dari akun ini.'),
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
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📧 Link reset password dikirim ke ${user.email}'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () => userAsync.valueOrNull != null
                  ? _startEdit(userAsync.valueOrNull)
                  : null,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit'),
            ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Belum login'));
          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header / Avatar ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF4A90E2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        child: Text(
                          user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.nama,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Poin & Level
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _HeaderBadge(
                            icon: Icons.star_rounded,
                            label: '${user.totalPoin} Poin',
                            color: AppColors.bounty,
                          ),
                          const SizedBox(width: 12),
                          _HeaderBadge(
                            icon: Icons.check_circle_rounded,
                            label: '${user.stats.totalResolved} Diselesaikan',
                            color: AppColors.statusActive,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Form Edit / Info ──
                if (_isEditing) ...[
                  _Section(
                    title: 'Edit Profil',
                    child: Column(
                      children: [
                        _buildField('Nama Lengkap', _namaCtrl, Icons.person_outline),
                        const SizedBox(height: 12),
                        _buildField('Username', _usernameCtrl, Icons.alternate_email),
                        const SizedBox(height: 12),
                        _buildField('No. HP', _noHpCtrl, Icons.phone_outlined,
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _isEditing = false),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : () => _saveProfile(user.uid),
                                child: _isSaving
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Simpan Perubahan'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _Section(
                    title: 'Informasi Akun',
                    child: Column(
                      children: [
                        _InfoRow(icon: Icons.person_outline, label: 'Nama', value: user.nama),
                        _InfoRow(icon: Icons.alternate_email, label: 'Username', value: '@${user.username}'),
                        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                        _InfoRow(icon: Icons.phone_outlined, label: 'No. HP', value: user.noHp.isEmpty ? '-' : user.noHp),
                      ],
                    ),
                  ),
                ],

                // ── Statistik ──
                _Section(
                  title: 'Statistik Kamu',
                  child: Row(
                    children: [
                      Expanded(child: _StatTile(label: 'Total Laporan', value: '${user.stats.totalReports}', icon: Icons.list_alt_rounded, color: AppColors.primary)),
                      Expanded(child: _StatTile(label: 'Diselesaikan', value: '${user.stats.totalResolved}', icon: Icons.check_circle_rounded, color: AppColors.statusActive)),
                      Expanded(child: _StatTile(label: 'Success Rate', value: '${user.stats.successRate.toStringAsFixed(0)}%', icon: Icons.trending_up_rounded, color: AppColors.bounty)),
                    ],
                  ),
                ),

                // ── Keamanan ──
                _Section(
                  title: 'Keamanan',
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: const Text('Ganti Password', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Link reset dikirim ke email', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                        onTap: _changePassword,
                      ),
                    ],
                  ),
                ),

                // ── Logout Button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text('Keluar Akun', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeaderBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
    ],
  );
}