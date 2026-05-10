import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/utils/security_utils.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../repositories/wallet_repository.dart';
import '../../services/cloudinary_service.dart';

class CreateItemScreen extends ConsumerStatefulWidget {
  const CreateItemScreen({super.key});

  @override
  ConsumerState<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends ConsumerState<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _bountyCtrl = TextEditingController(text: '0');
  final _questionCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();

  TipeLaporan _tipe = TipeLaporan.lost;
  KategoriBarang _kategori = KategoriBarang.lainnya;
  final List<File> _photos = [];
  File? _videoFile;
  bool _isLoading = false;
  String _loadingMessage = 'Menyimpan laporan...';
  int _currentStep = 0;

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    _lokasiCtrl.dispose();
    _bountyCtrl.dispose();
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 3 foto'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  Future<List<String>> _uploadPhotos(String itemId) async {
    return await CloudinaryService.uploadImages(_photos, itemId);
  }

  Future<String?> _uploadVideo(String itemId) async {
    if (_videoFile == null) return null;
    return await CloudinaryService.uploadVideo(_videoFile!, itemId);
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked != null) {
      setState(() => _videoFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw Exception('Kamu belum login');

      final bounty = int.tryParse(_bountyCtrl.text) ?? 0;

      // Buat item dulu (tanpa foto/video) untuk dapat ID
      final tempItem = ItemModel(
        itemId: '',
        ownerId: user.uid,
        judul: _judulCtrl.text.trim(),
        deskripsi: _deskripsiCtrl.text.trim(),
        kategori: _kategori,
        fotoUrls: [],
        videoUrl: null,
        lokasi: ItemLocation(latitude: 0, longitude: 0, namaLokasi: _lokasiCtrl.text.trim()),
        tanggalKejadian: DateTime.now(),
        createdAt: DateTime.now(),
        tipeLaporan: _tipe,
        nominalBounty: bounty,
        securityQuestion: _questionCtrl.text.trim().isNotEmpty ? _questionCtrl.text.trim() : null,
        securityAnswerHash: _answerCtrl.text.trim().isNotEmpty
            ? SecurityUtils.hashAnswer(_answerCtrl.text.trim())
            : null,
      );

      final itemId = await ref.read(itemsRepositoryProvider).createItem(tempItem);

      // Upload foto & video ke Cloudinary — hanya jika ada file
      if (_photos.isNotEmpty || _videoFile != null) {
        final Map<String, dynamic> updates = {};
        try {
          if (_photos.isNotEmpty) {
            setState(() => _loadingMessage = 'Mengupload foto ke Cloudinary...');
            updates['foto_urls'] = await _uploadPhotos(itemId);
          }
          if (_videoFile != null) {
            setState(() => _loadingMessage = 'Mengupload video (mungkin butuh waktu)...');
            updates['video_url'] = await _uploadVideo(itemId);
          }
          setState(() => _loadingMessage = 'Menyimpan data...');
          await ref.read(firestoreProvider)
              .collection('items')
              .doc(itemId)
              .update(updates);
        } catch (storageError) {
          debugPrint('Upload Cloudinary gagal: $storageError');
        }
      }

      // Lock escrow jika ada bounty
      if (bounty > 0) {
        await ref.read(walletRepositoryProvider).lockEscrow(
          userId: user.uid,
          itemId: itemId,
          bountyAmount: bounty,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Laporan berhasil dibuat! Menunggu moderasi admin.'),
            backgroundColor: AppColors.statusActive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                // Loading message saat upload
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(_loadingMessage, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : details.onStepContinue,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_currentStep == 2 ? 'Kirim Laporan' : 'Lanjut'),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isLoading ? null : details.onStepCancel,
                        child: const Text('Kembali'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          steps: [
            // Step 1: Info Dasar
            Step(
              title: const Text('Info Barang'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  // Tipe Toggle
                  Row(
                    children: [
                      Expanded(child: _TipeBtn(label: '🔍 Barang Hilang', selected: _tipe == TipeLaporan.lost, onTap: () => setState(() => _tipe = TipeLaporan.lost))),
                      const SizedBox(width: 10),
                      Expanded(child: _TipeBtn(label: '📦 Barang Temuan', selected: _tipe == TipeLaporan.found, onTap: () => setState(() => _tipe = TipeLaporan.found))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _judulCtrl,
                    decoration: const InputDecoration(labelText: 'Judul Laporan *', hintText: 'Contoh: Dompet Cokelat Hilang'),
                    validator: (v) => v!.isEmpty ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _deskripsiCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Deskripsi *', hintText: 'Deskripsikan ciri-ciri barang secara detail'),
                    validator: (v) => v!.isEmpty ? 'Deskripsi wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  // Kategori Dropdown
                  DropdownButtonFormField<KategoriBarang>(
                    initialValue: _kategori,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: KategoriBarang.values.map((k) => DropdownMenuItem(
                      value: k,
                      child: Text(k.name[0].toUpperCase() + k.name.substring(1)),
                    )).toList(),
                    onChanged: (v) => setState(() => _kategori = v!),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _lokasiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi *',
                      hintText: 'Contoh: Perpustakaan Lantai 2',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => v!.isEmpty ? 'Lokasi wajib diisi' : null,
                  ),
                ],
              ),
            ),

            // Step 2: Foto & Bounty
            Step(
              title: const Text('Foto & Bounty'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Foto Barang (max 3)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ..._photos.map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2, right: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _photos.remove(f)),
                                child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (_photos.length < 3)
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: AppColors.textHint),
                                Text('Tambah', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── VIDEO BUKTI ──
                  const Text('Video Bukti (Opsional, max 60 detik)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  _videoFile == null
                      ? GestureDetector(
                          onTap: _pickVideo,
                          child: Container(
                            width: double.infinity,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_outlined, color: AppColors.textHint, size: 28),
                                SizedBox(height: 4),
                                Text('Tap untuk pilih video', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _videoFile!.path.split('/').last,
                                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                                onPressed: () => setState(() => _videoFile = null),
                              ),
                            ],
                          ),
                        ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bountyLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.bounty.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star_rounded, color: AppColors.bounty, size: 18),
                            SizedBox(width: 6),
                            Text('Nominal Bounty', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF7B5800))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Poin akan dikunci saat laporan dibuat dan otomatis cair ke penemu.', style: TextStyle(fontSize: 12, color: Color(0xFF7B5800))),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _bountyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Jumlah Poin (0 = tanpa bounty)', suffixText: 'poin'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 0) return 'Masukkan angka valid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Step 3: Security Question
            Step(
              title: const Text('Pertanyaan Keamanan'),
              isActive: _currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      '💡 Buat pertanyaan yang hanya bisa dijawab oleh orang yang benar-benar menemukan barangmu. Contoh: "Apa nama toko terdekat dari tempat kamu menemukan dompet ini?"',
                      style: TextStyle(fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _questionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Pertanyaan',
                      hintText: 'Masukkan pertanyaan verifikasi...',
                      prefixIcon: Icon(Icons.help_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _answerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Jawaban (rahasia)',
                      hintText: 'Jawaban akan di-hash, tidak bisa dilihat siapapun',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    '⚠️ Harap catat jawaban ini karena tidak bisa dilihat kembali setelah disimpan.',
                    style: TextStyle(fontSize: 12, color: AppColors.statusPending),
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

class _TipeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TipeBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
    ),
  );
}