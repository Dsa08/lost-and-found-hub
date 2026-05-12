import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../services/pdf_service.dart';
import '../../widgets/bounty_badge.dart';
import '../video/video_player_screen.dart';
import '../chat/chat_screen.dart';
import '../qr/qr_screen.dart';
import 'claim_review_screen.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _showClaimForm = false;
  final _answerCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitClaim(ItemModel item) async {
    if (_answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jawaban tidak boleh kosong'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;
      await ref.read(itemsRepositoryProvider).submitClaim(
        itemId: item.itemId,
        finderId: user.uid,
        securityAnswer: _answerCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _showClaimForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Klaim berhasil dikirim! Tunggu persetujuan pemilik.'),
            backgroundColor: AppColors.statusActive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _downloadPdf(ItemModel item) async {
    setState(() => _isGeneratingPdf = true);
    try {
      // Ambil nama owner dari Firestore
      final ownerDoc = await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(item.ownerId)
          .get();
      final namaOwner = ownerDoc.data()?['nama'] ?? 'Tidak diketahui';

      // Ambil nama finder jika ada
      String namaFinder = '-';
      if (item.activeClaimId != null) {
        final finderDoc = await FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(item.activeClaimId)
            .get();
        namaFinder = finderDoc.data()?['nama'] ?? '-';
      }

      await PdfService.generateSertifikat(
        item: item,
        namaOwner: namaOwner,
        namaFinder: namaFinder,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal generate PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemByIdProvider(widget.itemId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: itemAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Item tidak ditemukan'));
          }
          final isOwner = currentUser?.uid == item.ownerId;

          return CustomScrollView(
            slivers: [
              // ── App Bar dengan foto ──
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: item.fotoUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.fotoUrls.first,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.image_not_supported_outlined, size: 60, color: AppColors.textHint),
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner pending moderasi
                      if (!item.isApproved && item.status == ItemStatus.pendingApproval) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.statusPending.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.statusPending.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.pending_actions_rounded, color: AppColors.statusPending, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Menunggu Persetujuan Admin', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.statusPending)),
                                    Text('Laporan akan tampil di dashboard setelah diapprove admin.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Badges
                      Row(
                        children: [
                          StatusBadge(status: item.tipeLaporan == TipeLaporan.lost ? 'lost' : 'found'),
                          const SizedBox(width: 8),
                          StatusBadge(status: item.status.name),
                          const Spacer(),
                          BountyBadge(poin: item.nominalBounty, large: true),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Judul
                      Text(item.judul, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text(
                        'Dilaporkan ${timeago.format(item.createdAt, locale: 'id')}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Deskripsi
                      const Text('Deskripsi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(item.deskripsi, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),

                      const SizedBox(height: 20),

                      // Lokasi
                      _InfoTile(
                        icon: Icons.location_on_rounded,
                        iconColor: AppColors.statusLost,
                        title: 'Lokasi',
                        value: item.lokasi.namaLokasi,
                      ),
                      const SizedBox(height: 12),

                      // Kategori
                      _InfoTile(
                        icon: Icons.category_rounded,
                        iconColor: AppColors.primary,
                        title: 'Kategori',
                        value: item.kategori.name[0].toUpperCase() + item.kategori.name.substring(1),
                      ),

                      // ── VIDEO BUKTI ──────────────────────────────────────
                      if (item.hasVideo) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Video Bukti',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        VideoThumbnailWidget(
                          videoUrl: item.videoUrl!,
                          title: 'Video Bukti — ${item.judul}',
                        ),
                      ],

                      // ── DOWNLOAD PDF (hanya jika Resolved) ──────────────
                      if (item.isResolved) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.statusActive.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.statusActive.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppColors.statusActive, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Barang Berhasil Dikembalikan!', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.statusActive)),
                                    Text('Download sertifikat serah terima sebagai bukti resmi.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingPdf ? null : () => _downloadPdf(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusActive,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isGeneratingPdf
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.download_rounded, color: Colors.white),
                            label: Text(
                              _isGeneratingPdf ? 'Membuat PDF...' : 'Download Sertifikat PDF',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],

                      // ── Security Question ──
                      if (item.securityQuestion != null && !isOwner) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.security_rounded, color: AppColors.primary, size: 18),
                                  SizedBox(width: 8),
                                  Text('Pertanyaan Keamanan', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item.securityQuestion!, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],

                      // Claim Form
                      if (_showClaimForm && !isOwner) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _answerCtrl,
                          decoration: InputDecoration(
                            labelText: 'Jawaban kamu',
                            hintText: 'Masukkan jawabanmu dengan teliti',
                            suffixIcon: _isSubmitting
                                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                : null,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _showClaimForm = false),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : () => _submitClaim(item),
                                child: const Text('Kirim Klaim'),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
      ),
      bottomNavigationBar: itemAsync.when(
        data: (item) {
          if (item == null) return null;
          final isOwner = currentUser?.uid == item.ownerId;
          final isFinder = item.activeClaimId == currentUser?.uid;

          // ── OWNER ACTIONS ──────────────────────────────────────────────
          if (isOwner) {
            // Pending Meetup: owner bisa scan QR dan buka chat
            if (item.status == ItemStatus.pendingMeetup) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Cari nama finder
                            final doc = await FirebaseFirestore.instance
                                .collection(FirestorePaths.users)
                                .doc(item.activeClaimId)
                                .get();
                            final name = doc.data()?['nama'] ?? 'Finder';
                            if (context.mounted) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  item: item,
                                  otherUserId: item.activeClaimId!,
                                  otherUserName: name,
                                ),
                              ));
                            }
                          },
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text('Chat'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => QrScannerScreen(item: item))),
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                          label: const Text('Scan QR Finder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Active: owner bisa review klaim
            if (item.status == ItemStatus.active) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ClaimReviewScreen(item: item))),
                    icon: const Icon(Icons.rate_review_rounded),
                    label: const Text('Lihat Klaim Masuk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusPending,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              );
            }
            return null;
          }

          // ── FINDER ACTIONS ─────────────────────────────────────────────
          if (isFinder && item.status == ItemStatus.pendingMeetup) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final doc = await FirebaseFirestore.instance
                              .collection(FirestorePaths.users)
                              .doc(item.ownerId)
                              .get();
                          final name = doc.data()?['nama'] ?? 'Owner';
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                item: item,
                                otherUserId: item.ownerId,
                                otherUserName: name,
                              ),
                            ));
                          }
                        },
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('Chat'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => QrGeneratorScreen(item: item))),
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text('Generate QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusFound,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── PUBLIC: Tombol klaim (jika active dan bukan owner) ─────────
          if (!isOwner && item.status == ItemStatus.active) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showClaimForm = true),
                  icon: const Icon(Icons.volunteer_activism_rounded),
                  label: const Text('Saya Menemukan Ini!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusFound,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            );
          }

          return null;
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, value;
  const _InfoTile({required this.icon, required this.iconColor, required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    ],
  );
}