import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';

// ── QR Generator (untuk Finder) ───────────────────────────────────────────────
/// **QrGeneratorScreen**
/// Layar ini dibuka oleh Penemu (Finder).
/// Men-generate sebuah QR Code unik yang terhubung ke dokumen `verifications` di Firestore.
/// Token QR ini bersifat *Time-to-Live* (TTL) alias akan hangus dalam 5 menit.
class QrGeneratorScreen extends ConsumerStatefulWidget {
  final ItemModel item;
  const QrGeneratorScreen({super.key, required this.item});

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen>
    with SingleTickerProviderStateMixin {
  String? _verifId;
  bool _isCreating = true;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _createVerification();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// **Fungsi _createVerification**
  /// Membuat dokumen verifikasi baru dengan umur 5 menit.
  Future<void> _createVerification() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    // Buat dokumen verifikasi di Firestore
    final ref2 = FirebaseFirestore.instance.collection(FirestorePaths.verifications).doc();

    await ref2.set({
      'item_id': widget.item.itemId,
      'owner_id': widget.item.ownerId,
      'finder_id': user.uid,
      'qr_token': ref2.id,
      'verified_status': 'Pending',
      'created_at': FieldValue.serverTimestamp(),
      'token_expires_at': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
    });

    if (mounted) {
      setState(() {
        _verifId = ref2.id;
        _isCreating = false;
      });

      // Auto refresh QR setiap 5 menit
      Future.delayed(const Duration(minutes: 5), () {
        if (mounted) _refreshQr();
      });
    }
  }

  Future<void> _refreshQr() async {
    setState(() { _isCreating = true; _verifId = null; });
    await _createVerification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('QR Verifikasi'),
        actions: [
          TextButton.icon(
            onPressed: _isCreating ? null : _refreshQr,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
      body: _isCreating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Membuat QR Code...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Instruksi
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tunjukkan QR Code ini ke pemilik barang untuk di-scan. QR berlaku 5 menit.',
                            style: TextStyle(fontSize: 13, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QR Code dengan animasi pulse
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _verifId!,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Item Info
                  Text(widget.item.judul, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    'ID: ${_verifId!.substring(0, 12)}...',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontFamily: 'monospace'),
                  ),

                  const SizedBox(height: 32),

                  // Timer info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bountyLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.bounty.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.bounty, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            const Text('Bounty yang akan kamu terima', style: TextStyle(fontSize: 12, color: Color(0xFF7B5800))),
                            Text(
                              '${widget.item.nominalBounty} Poin',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.bounty),
                            ),
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

// ── QR Scanner (untuk Owner) ──────────────────────────────────────────────────
/// **QrScannerScreen**
/// Layar ini dibuka oleh Pemilik Barang (Owner).
/// Membuka kamera untuk memindai QR Code yang ditunjukkan oleh Finder saat bertemu.
/// Jika QR valid, ini akan melepaskan (release) saldo poin escrow ke Finder.
class QrScannerScreen extends ConsumerStatefulWidget {
  final ItemModel item;
  const QrScannerScreen({super.key, required this.item});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  MobileScannerController? _scanCtrl;
  bool _isProcessing = false;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _scanCtrl = MobileScannerController();
  }

  @override
  void dispose() {
    _scanCtrl?.dispose();
    super.dispose();
  }

  /// **Fungsi _processQr (Validasi & Transfer)**
  /// 1. Cek apakah dokumen QR ada dan belum expired (TTL < 5 mnt).
  /// 2. Cek apakah QR ini benar untuk barang yang sedang aktif ini.
  /// 3. Jika Valid, jalankan Firebase Transaction (Atomik) untuk:
  ///    - Kurangi poin terkunci (Owner)
  ///    - Tambah poin utama (Finder)
  ///    - Ubah status barang jadi 'resolved'.
  Future<void> _processQr(String verifId) async {
    if (_isProcessing || _scanned) return;
    setState(() => _isProcessing = true);
    _scanCtrl?.stop();

    try {
      // Ambil dokumen verifikasi
      final verifDoc = await FirebaseFirestore.instance
          .collection(FirestorePaths.verifications)
          .doc(verifId)
          .get();

      if (!verifDoc.exists) throw Exception('QR Code tidak valid');

      final verifData = verifDoc.data()!;

      // Cek apakah QR untuk item yang benar
      if (verifData['item_id'] != widget.item.itemId) {
        throw Exception('QR Code bukan untuk barang ini');
      }

      // Cek status
      if (verifData['verified_status'] != 'Pending') {
        throw Exception('QR Code sudah digunakan atau expired');
      }

      // Cek TTL (5 menit)
      final expiresAt = (verifData['token_expires_at'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('QR Code sudah kedaluwarsa. Minta finder generate ulang.');
      }

      final finderId = verifData['finder_id'] as String;
      final bounty = widget.item.nominalBounty;

      // Jalankan transaksi release escrow
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final itemRef = FirebaseFirestore.instance
            .collection(FirestorePaths.items)
            .doc(widget.item.itemId);
        final ownerRef = FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(widget.item.ownerId);
        final finderRef = FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(finderId);

        final ownerSnap = await txn.get(ownerRef);
        final finderSnap = await txn.get(finderRef);

        // Release escrow
        if (bounty > 0) {
          txn.update(ownerRef, {
            'locked_poin': ((ownerSnap.data()?['locked_poin'] ?? 0) - bounty).clamp(0, double.infinity).toInt(),
          });
          txn.update(finderRef, {
            'total_poin': (finderSnap.data()?['total_poin'] ?? 0) + bounty,
            'stats.total_resolved': FieldValue.increment(1),
          });

          // Sinkronisasi guild
          final guildId = finderSnap.data()?['guild_id'];
          if (guildId != null) {
            final guildRef = FirebaseFirestore.instance.collection(FirestorePaths.guilds).doc(guildId);
            txn.update(guildRef, {'total_reputasi': FieldValue.increment(bounty)});
          }

          // Log transaksi
          final logRef = FirebaseFirestore.instance.collection(FirestorePaths.transactionLogs).doc();
          txn.set(logRef, {
            'type': 'Escrow_Release',
            'from_user': widget.item.ownerId,
            'to_user': finderId,
            'amount': bounty,
            'item_id': widget.item.itemId,
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        // Update item dan verifikasi
        txn.update(itemRef, {'status': 'resolved', 'escrow_status': 'released'});
        txn.update(verifDoc.reference, {
          'verified_status': 'Success',
          'verified_at': FieldValue.serverTimestamp(),
        });
      });

      setState(() => _scanned = true);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.statusActive, size: 72),
                const SizedBox(height: 16),
                const Text('Verifikasi Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  bounty > 0
                      ? '$bounty poin berhasil dikirim ke penemu!'
                      : 'Barang berhasil diserahkan!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusActive),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _scanCtrl?.start();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Finder'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scanCtrl,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _processQr(barcode!.rawValue!);
              }
            },
          ),

          // Overlay UI
          Column(
            children: [
              const Spacer(),
              // Frame scanner
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Arahkan kamera ke QR Code milik Finder',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.item.judul,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}