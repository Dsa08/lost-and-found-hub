import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/pdf_service.dart';
import '../../models/item_model.dart';
import '../video/video_player_screen.dart';

/// **TestPlaygroundScreen**
/// Halaman tes mandiri (solo) untuk menguji fitur-fitur yang biasanya membutuhkan
/// 2 orang atau koneksi server:
/// - QR Code Generate & Scan
/// - Upload Foto ke Cloudinary
/// - Upload Video ke Cloudinary & Playback
/// - Generate & Download PDF
/// - Chat (kirim pesan ke diri sendiri)
/// - Video Player dari URL
class TestPlaygroundScreen extends ConsumerStatefulWidget {
  const TestPlaygroundScreen({super.key});

  @override
  ConsumerState<TestPlaygroundScreen> createState() => _TestPlaygroundScreenState();
}

class _TestPlaygroundScreenState extends ConsumerState<TestPlaygroundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🧪 Test Playground'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_rounded, size: 20), text: 'QR Code'),
            Tab(icon: Icon(Icons.photo_camera_rounded, size: 20), text: 'Upload Foto'),
            Tab(icon: Icon(Icons.videocam_rounded, size: 20), text: 'Upload Video'),
            Tab(icon: Icon(Icons.picture_as_pdf_rounded, size: 20), text: 'PDF'),
            Tab(icon: Icon(Icons.chat_rounded, size: 20), text: 'Chat'),
            Tab(icon: Icon(Icons.play_circle_rounded, size: 20), text: 'Video Player'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _QrTestTab(),
          _UploadPhotoTab(),
          _UploadVideoTab(),
          _PdfTestTab(),
          _ChatTestTab(),
          _VideoPlayerTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1: QR CODE TEST
// ═══════════════════════════════════════════════════════════════════════════════
class _QrTestTab extends ConsumerStatefulWidget {
  const _QrTestTab();
  @override
  ConsumerState<_QrTestTab> createState() => _QrTestTabState();
}

class _QrTestTabState extends ConsumerState<_QrTestTab>
    with AutomaticKeepAliveClientMixin {
  String _qrData = '';
  String? _scannedResult;
  bool _showScanner = false;
  bool _isGenerating = false;
  MobileScannerController? _scanCtrl;
  final _qrInputCtrl = TextEditingController(text: 'test-qr-token-${DateTime.now().millisecondsSinceEpoch}');

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _qrInputCtrl.dispose();
    _scanCtrl?.dispose();
    super.dispose();
  }

  void _generateQr() {
    setState(() {
      _isGenerating = true;
      _qrData = _qrInputCtrl.text.trim();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isGenerating = false);
    });
  }

  Future<void> _generateFirestoreQr() async {
    setState(() => _isGenerating = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw Exception('Belum login');

      final docRef = FirebaseFirestore.instance
          .collection(FirestorePaths.verifications)
          .doc();

      await docRef.set({
        'item_id': 'TEST_ITEM',
        'owner_id': user.uid,
        'finder_id': user.uid,
        'qr_token': docRef.id,
        'verified_status': 'Test',
        'created_at': FieldValue.serverTimestamp(),
        'token_expires_at': Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 5))),
        'is_test': true,
      });

      setState(() => _qrData = docRef.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ QR Token tersimpan di Firestore: ${docRef.id.substring(0, 12)}...'),
            backgroundColor: AppColors.statusActive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _startScanner() {
    _scanCtrl = MobileScannerController();
    setState(() {
      _showScanner = true;
      _scannedResult = null;
    });
  }

  void _stopScanner() {
    _scanCtrl?.dispose();
    _scanCtrl = null;
    setState(() => _showScanner = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Generate QR Section ──
              _TestCard(
                title: '📲 Generate QR Code',
                subtitle: 'Buat QR Code dari teks atau simpan token ke Firestore',
                child: Column(
                  children: [
                    TextField(
                      controller: _qrInputCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Data QR Code',
                        hintText: 'Masukkan teks apapun...',
                        prefixIcon: Icon(Icons.text_fields_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _generateQr,
                            icon: const Icon(Icons.qr_code_rounded, size: 18),
                            label: const Text('Generate Lokal'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _generateFirestoreQr,
                            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                            label: const Text('+ Firestore'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusActive,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isGenerating) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(color: AppColors.primary),
                    ],
                    if (_qrData.isNotEmpty && !_isGenerating) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 200,
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
                      const SizedBox(height: 8),
                      Text(
                        'Data: ${_qrData.length > 40 ? '${_qrData.substring(0, 40)}...' : _qrData}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'monospace'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Scanner Section ──
              _TestCard(
                title: '📷 Scan QR Code',
                subtitle: 'Buka kamera untuk memindai QR Code yang sudah di-generate',
                child: Column(
                  children: [
                    if (!_showScanner)
                      ElevatedButton.icon(
                        onPressed: _startScanner,
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Buka Scanner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      )
                    else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 250,
                          child: MobileScanner(
                            controller: _scanCtrl,
                            onDetect: (capture) {
                              final barcode = capture.barcodes.firstOrNull;
                              if (barcode?.rawValue != null) {
                                setState(() => _scannedResult = barcode!.rawValue);
                                _stopScanner();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _stopScanner,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Tutup Scanner'),
                      ),
                    ],
                    if (_scannedResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.statusActive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.statusActive.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.statusActive, size: 32),
                            const SizedBox(height: 6),
                            const Text('Hasil Scan:', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.statusActive)),
                            const SizedBox(height: 4),
                            SelectableText(
                              _scannedResult!,
                              style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: AppColors.textPrimary),
                              textAlign: TextAlign.center,
                            ),
                            if (_scannedResult == _qrData && _qrData.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.statusActive,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('✓ COCOK dengan QR yang di-generate!',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2: UPLOAD FOTO
// ═══════════════════════════════════════════════════════════════════════════════
class _UploadPhotoTab extends StatefulWidget {
  const _UploadPhotoTab();
  @override
  State<_UploadPhotoTab> createState() => _UploadPhotoTabState();
}

class _UploadPhotoTabState extends State<_UploadPhotoTab>
    with AutomaticKeepAliveClientMixin {
  final List<File> _selectedPhotos = [];
  final List<String> _uploadedUrls = [];
  bool _isUploading = false;
  String _uploadStatus = '';
  double _uploadProgress = 0;

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickPhoto() async {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 3 foto'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked != null) {
      setState(() => _selectedPhotos.add(File(picked.path)));
    }
  }

  Future<void> _uploadAll() async {
    if (_selectedPhotos.isEmpty) return;
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Memulai upload...';
      _uploadProgress = 0;
      _uploadedUrls.clear();
    });

    try {
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      for (int i = 0; i < _selectedPhotos.length; i++) {
        setState(() {
          _uploadStatus = 'Mengupload foto ${i + 1}/${_selectedPhotos.length}...';
          _uploadProgress = (i) / _selectedPhotos.length;
        });
        final url = await CloudinaryService.uploadImage(_selectedPhotos[i], testId);
        _uploadedUrls.add(url);
      }
      setState(() {
        _uploadStatus = '✅ Semua foto berhasil diupload!';
        _uploadProgress = 1.0;
      });
    } catch (e) {
      setState(() => _uploadStatus = '❌ Gagal: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TestCard(
                title: '📸 Upload Foto ke Cloudinary',
                subtitle: 'Pilih foto dari galeri, upload, lalu lihat hasilnya',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo picker grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._selectedPhotos.asMap().entries.map((e) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(e.value, width: 90, height: 90, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedPhotos.removeAt(e.key)),
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                        if (_selectedPhotos.length < 3)
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.textHint, size: 28),
                                  Text('Pilih', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Upload button
                    ElevatedButton.icon(
                      onPressed: _isUploading || _selectedPhotos.isEmpty ? null : _uploadAll,
                      icon: _isUploading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(_isUploading ? 'Mengupload...' : 'Upload ke Cloudinary'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    ),

                    if (_uploadStatus.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      if (_isUploading)
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: AppColors.surfaceVariant,
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      const SizedBox(height: 6),
                      Text(_uploadStatus,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _uploadStatus.startsWith('✅')
                                ? AppColors.statusActive
                                : _uploadStatus.startsWith('❌')
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                          )),
                    ],

                    // Uploaded results
                    if (_uploadedUrls.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Hasil Upload:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      ..._uploadedUrls.asMap().entries.map((e) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    e.value,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        height: 150,
                                        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SelectableText(
                                    e.value,
                                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textHint),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3: UPLOAD VIDEO
// ═══════════════════════════════════════════════════════════════════════════════
class _UploadVideoTab extends StatefulWidget {
  const _UploadVideoTab();
  @override
  State<_UploadVideoTab> createState() => _UploadVideoTabState();
}

class _UploadVideoTabState extends State<_UploadVideoTab>
    with AutomaticKeepAliveClientMixin {
  File? _videoFile;
  String? _uploadedVideoUrl;
  bool _isUploading = false;
  String _uploadStatus = '';

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null) return;

    final file = File(picked.path);
    final sizeInMB = await file.length() / (1024 * 1024);

    if (sizeInMB > 50) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video terlalu besar (${sizeInMB.toStringAsFixed(1)} MB). Max 50 MB.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _videoFile = file;
      _uploadStatus = 'Video dipilih: ${sizeInMB.toStringAsFixed(1)} MB';
    });
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Mengupload video ke Cloudinary... (mungkin butuh waktu)';
    });

    try {
      final testId = 'test_video_${DateTime.now().millisecondsSinceEpoch}';
      final url = await CloudinaryService.uploadVideo(_videoFile!, testId);
      setState(() {
        _uploadedVideoUrl = url;
        _uploadStatus = '✅ Video berhasil diupload!';
      });
    } catch (e) {
      setState(() => _uploadStatus = '❌ Gagal: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TestCard(
                title: '🎬 Upload Video ke Cloudinary',
                subtitle: 'Pilih video, upload, lalu putar hasilnya langsung',
                child: Column(
                  children: [
                    // Video picker
                    if (_videoFile == null)
                      GestureDetector(
                        onTap: _pickVideo,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_outlined, color: AppColors.textHint, size: 40),
                              SizedBox(height: 8),
                              Text('Tap untuk pilih video', style: TextStyle(color: AppColors.textHint)),
                              Text('Max 60 detik, 50 MB', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _videoFile!.path.split(Platform.pathSeparator).last,
                                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                              onPressed: () => setState(() {
                                _videoFile = null;
                                _uploadedVideoUrl = null;
                                _uploadStatus = '';
                              }),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Upload button
                    ElevatedButton.icon(
                      onPressed: _isUploading || _videoFile == null ? null : _uploadVideo,
                      icon: _isUploading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(_isUploading ? 'Mengupload...' : 'Upload Video'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    ),

                    if (_uploadStatus.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      if (_isUploading)
                        const LinearProgressIndicator(
                          backgroundColor: AppColors.surfaceVariant,
                          color: AppColors.primary,
                        ),
                      const SizedBox(height: 6),
                      Text(_uploadStatus,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _uploadStatus.startsWith('✅')
                                ? AppColors.statusActive
                                : _uploadStatus.startsWith('❌')
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                          )),
                    ],

                    // Play uploaded video
                    if (_uploadedVideoUrl != null) ...[
                      const SizedBox(height: 16),
                      VideoThumbnailWidget(
                        videoUrl: _uploadedVideoUrl!,
                        title: 'Test Video Playback',
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _uploadedVideoUrl!,
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textHint),
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4: PDF TEST
// ═══════════════════════════════════════════════════════════════════════════════
class _PdfTestTab extends ConsumerStatefulWidget {
  const _PdfTestTab();
  @override
  ConsumerState<_PdfTestTab> createState() => _PdfTestTabState();
}

class _PdfTestTabState extends ConsumerState<_PdfTestTab>
    with AutomaticKeepAliveClientMixin {
  bool _isGenerating = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _generateTestPdf() async {
    setState(() => _isGenerating = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final testItem = ItemModel(
        itemId: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        ownerId: user?.uid ?? 'test_owner',
        judul: 'Dompet Cokelat (TES)',
        deskripsi: 'Ini adalah barang tes untuk menguji fitur PDF sertifikat serah terima.',
        kategori: KategoriBarang.dompet,
        fotoUrls: [],
        lokasi: const ItemLocation(latitude: -6.2088, longitude: 106.8456, namaLokasi: 'Perpustakaan Kampus, Lantai 2'),
        tanggalKejadian: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now(),
        tipeLaporan: TipeLaporan.lost,
        status: ItemStatus.resolved,
        nominalBounty: 50,
        escrowStatus: EscrowStatus.released,
      );

      await PdfService.generateSertifikat(
        item: testItem,
        namaOwner: user?.nama ?? 'Pemilik (Tes)',
        namaFinder: user?.nama ?? 'Penemu (Tes)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF berhasil di-generate!'),
            backgroundColor: AppColors.statusActive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _TestCard(
                title: '📄 Generate Sertifikat PDF',
                subtitle: 'Buat sertifikat serah terima barang sebagai dokumen PDF',
                child: Column(
                  children: [
                    // Preview info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preview Data Tes:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          SizedBox(height: 8),
                          _PdfInfoRow(label: 'Barang', value: 'Dompet Cokelat (TES)'),
                          _PdfInfoRow(label: 'Kategori', value: 'Dompet'),
                          _PdfInfoRow(label: 'Lokasi', value: 'Perpustakaan Kampus, Lantai 2'),
                          _PdfInfoRow(label: 'Bounty', value: '50 Poin'),
                          _PdfInfoRow(label: 'Status', value: 'Resolved ✓'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateTestPdf,
                      icon: _isGenerating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate & Share PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PDF akan otomatis membuka dialog Share/Print bawaan OS',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfInfoRow extends StatelessWidget {
  final String label, value;
  const _PdfInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint))),
            const Text(': ', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 5: CHAT TEST (Self-chat)
// ═══════════════════════════════════════════════════════════════════════════════
class _ChatTestTab extends ConsumerStatefulWidget {
  const _ChatTestTab();
  @override
  ConsumerState<_ChatTestTab> createState() => _ChatTestTabState();
}

class _ChatTestTabState extends ConsumerState<_ChatTestTab>
    with AutomaticKeepAliveClientMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  String? _testChatItemId;
  bool _isCreatingChat = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _createTestChat() async {
    setState(() => _isCreatingChat = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw Exception('Belum login');

      // Buat item tes sementara untuk chat
      final docRef = FirebaseFirestore.instance.collection(FirestorePaths.items).doc();
      await docRef.set({
        'owner_id': user.uid,
        'judul': '[TEST] Chat Solo Test',
        'deskripsi': 'Item tes untuk menguji fitur chat secara mandiri',
        'kategori': 'lainnya',
        'foto_urls': [],
        'lokasi': {'latitude': 0, 'longitude': 0, 'nama_lokasi': 'Test'},
        'tanggal_kejadian': Timestamp.now(),
        'created_at': FieldValue.serverTimestamp(),
        'tipe_laporan': 'Lost',
        'status': 'active',
        'nominal_bounty': 0,
        'escrow_status': 'none',
        'is_approved': false,
        'view_count': 0,
        'is_test': true,
      });

      setState(() => _testChatItemId = docRef.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ruang chat tes berhasil dibuat!'),
            backgroundColor: AppColors.statusActive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingChat = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending || _testChatItemId == null) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSending = true);
    _msgCtrl.clear();

    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.itemChats(_testChatItemId!))
          .add({
        'sender_id': user.uid,
        'sender_name': user.nama,
        'text': text,
        'created_at': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent + 60,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _msgCtrl.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _cleanupTestChat() async {
    if (_testChatItemId == null) return;
    try {
      // Hapus semua chat messages
      final chatSnap = await FirebaseFirestore.instance
          .collection(FirestorePaths.itemChats(_testChatItemId!))
          .get();
      for (final doc in chatSnap.docs) {
        await doc.reference.delete();
      }
      // Hapus item tes
      await FirebaseFirestore.instance
          .collection(FirestorePaths.items)
          .doc(_testChatItemId)
          .delete();

      setState(() => _testChatItemId = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧹 Data tes chat berhasil dihapus!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal cleanup: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    if (_testChatItemId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('Tes Chat Mandiri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Kirim pesan ke diri sendiri untuk menguji fitur chat real-time.\nPesan akan tersimpan di Firestore.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isCreatingChat ? null : _createTestChat,
                icon: _isCreatingChat
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add_comment_rounded, size: 20),
                label: Text(_isCreatingChat ? 'Membuat...' : 'Buat Ruang Chat Tes'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(240, 52),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Chat aktif
    return Column(
      children: [
        // Header info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.bountyLight,
          child: Row(
            children: [
              const Icon(Icons.science_rounded, size: 16, color: AppColors.bounty),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mode Tes: Pesan dikirim dan diterima oleh akunmu sendiri',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7B5800)),
                ),
              ),
              TextButton(
                onPressed: _cleanupTestChat,
                child: const Text('🧹 Hapus', style: TextStyle(fontSize: 12, color: AppColors.error)),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirestorePaths.itemChats(_testChatItemId!))
                .orderBy('created_at', descending: false)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final docs = snap.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text('Kirim pesan pertamamu!', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final isMe = data['sender_id'] == currentUser?.uid;
                  final time = (data['created_at'] as Timestamp?)?.toDate();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: const Radius.circular(4),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(data['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                            if (time != null)
                              Text(
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Input field
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan tes...',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 6: VIDEO PLAYER (dari URL)
// ═══════════════════════════════════════════════════════════════════════════════
class _VideoPlayerTab extends StatefulWidget {
  const _VideoPlayerTab();
  @override
  State<_VideoPlayerTab> createState() => _VideoPlayerTabState();
}

class _VideoPlayerTabState extends State<_VideoPlayerTab>
    with AutomaticKeepAliveClientMixin {
  final _urlCtrl = TextEditingController(
    text: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _playVideo() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoUrl: url, title: 'Test Video'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _TestCard(
                title: '▶️ Tes Video Player',
                subtitle: 'Masukkan URL video untuk menguji pemutar video',
                child: Column(
                  children: [
                    TextField(
                      controller: _urlCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'URL Video',
                        hintText: 'Masukkan URL video (mp4, mov, dll)',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _playVideo,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text('Putar Video'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: const Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Contoh URL Lainnya:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    _SampleVideoBtn(
                      title: '🐰 Big Buck Bunny',
                      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                      onTap: (url) => setState(() => _urlCtrl.text = url),
                    ),
                    _SampleVideoBtn(
                      title: '🐘 Elephant Dream',
                      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                      onTap: (url) => setState(() => _urlCtrl.text = url),
                    ),
                    _SampleVideoBtn(
                      title: '🎬 Sintel Trailer',
                      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
                      onTap: (url) => setState(() => _urlCtrl.text = url),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SampleVideoBtn extends StatelessWidget {
  final String title, url;
  final ValueChanged<String> onTap;
  const _SampleVideoBtn({required this.title, required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap(url),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Card pembungkus untuk setiap fitur tes
class _TestCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _TestCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}
