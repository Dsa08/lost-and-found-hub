import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipe laporan yang dibuat user.
enum TipeLaporan { lost, found }

/// **Status Laporan Barang (Siklus Hidup)**
/// - `pendingApproval`: Laporan baru dibuat, menunggu admin (Moderasi) untuk disetujui agar tampil di publik.
/// - `active`: Laporan tayang di beranda dan bisa dicari oleh orang lain.
/// - `pendingMeetup`: Ada pihak yang mengklaim barang, sedang proses ketemuan (meetup).
/// - `resolved`: Kasus selesai (barang kembali ke pemilik).
/// - `expired`: Laporan ditolak admin atau masa berlakunya habis.
enum ItemStatus { active, pendingApproval, pendingMeetup, resolved, expired }

/// **Status Uang Jaminan (Escrow Poin)**
/// - `none`: Laporan ini tidak ada bounty (imbalan) poin.
/// - `locked`: Pelapor menyediakan bounty, poin sudah dipotong dari saldonya dan "ditahan" oleh sistem.
/// - `released`: Kasus selesai sukses, poin yang ditahan dicairkan ke penemu barang.
/// - `refunded`: Kasus gagal/dibatalkan/sengketa dimenangkan pelapor, poin dikembalikan ke pelapor.
enum EscrowStatus { none, locked, released, refunded }

/// Kategori jenis barang untuk memudahkan filter pencarian.
enum KategoriBarang { elektronik, dompet, kunci, pakaian, dokumen, tas, lainnya }

class ItemLocation {
  final double latitude;
  final double longitude;
  final String namaLokasi;

  const ItemLocation({
    required this.latitude,
    required this.longitude,
    required this.namaLokasi,
  });

  factory ItemLocation.fromMap(Map<String, dynamic> map) => ItemLocation(
        latitude: (map['latitude'] ?? 0.0).toDouble(),
        longitude: (map['longitude'] ?? 0.0).toDouble(),
        namaLokasi: map['nama_lokasi'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'nama_lokasi': namaLokasi,
      };
}

/// **ItemModel**
/// Merepresentasikan entitas laporan barang (baik barang hilang maupun temuan) di Firestore (koleksi 'items').
class ItemModel {
  /// ID Dokumen di Firestore.
  final String itemId;
  /// UID pembuat laporan (bisa yang kehilangan, bisa yang menemukan).
  final String ownerId;
  /// ID Admin yang meng-approve laporan ini (null jika belum di-approve).
  final String? adminId;
  final String judul;
  final String deskripsi;
  final KategoriBarang kategori;
  /// List URL gambar bukti barang (di-host di Cloudinary/Storage).
  final List<String> fotoUrls;
  /// URL video bukti (opsional).
  final String? videoUrl;
  /// Lokasi perkiraan barang hilang/ditemukan (Koordinat GPS & Nama Tempat).
  final ItemLocation lokasi;
  final DateTime tanggalKejadian;
  final DateTime createdAt;
  final TipeLaporan tipeLaporan;
  final ItemStatus status;
  
  // ── Fitur Bounty & Keamanan ──
  /// Jumlah poin yang dijanjikan sebagai imbalan (Bounty). Jika 0 berarti sukarela.
  final int nominalBounty;
  /// Status penahanan poin bounty saat ini.
  final EscrowStatus escrowStatus;
  
  /// (Opsional) Pertanyaan keamanan yang harus dijawab penemu untuk membuktikan barang itu benar miliknya.
  final String? securityQuestion;
  /// Hash jawaban keamanan (MD5/Bcrypt) agar jawaban asli tidak terlihat di database.
  final String? securityAnswerHash;
  
  /// True jika admin sudah menekan tombol Approve di layar moderasi.
  final bool isApproved;
  /// Jika sedang proses klaim (pendingMeetup), ini adalah ID dokumen dari koleksi 'claims'.
  final String? activeClaimId;
  /// Jumlah orang yang melihat laporan ini (Statistik).
  final int viewCount;

  const ItemModel({
    required this.itemId,
    required this.ownerId,
    this.adminId,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.fotoUrls,
    this.videoUrl,
    required this.lokasi,
    required this.tanggalKejadian,
    required this.createdAt,
    required this.tipeLaporan,
    this.status = ItemStatus.pendingApproval,
    this.nominalBounty = 0,
    this.escrowStatus = EscrowStatus.none,
    this.securityQuestion,
    this.securityAnswerHash,
    this.isApproved = false,
    this.activeClaimId,
    this.viewCount = 0,
  });

  bool get hasBounty => nominalBounty > 0;
  bool get isLost => tipeLaporan == TipeLaporan.lost;
  bool get isResolved => status == ItemStatus.resolved;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      itemId: doc.id,
      ownerId: data['owner_id'] ?? '',
      adminId: data['admin_id'],
      judul: data['judul'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      kategori: _parseKategori(data['kategori']),
      fotoUrls: List<String>.from(data['foto_urls'] ?? []),
      videoUrl: data['video_url'],
      lokasi: ItemLocation.fromMap(data['lokasi'] ?? {}),
      tanggalKejadian: (data['tanggal_kejadian'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipeLaporan: data['tipe_laporan'] == 'Found' ? TipeLaporan.found : TipeLaporan.lost,
      status: _parseStatus(data['status']),
      nominalBounty: (data['nominal_bounty'] ?? 0).toInt(),
      escrowStatus: _parseEscrow(data['escrow_status']),
      securityQuestion: data['security_question'],
      securityAnswerHash: data['security_answer_hash'],
      isApproved: data['is_approved'] ?? false,
      activeClaimId: data['active_claim_id'],
      viewCount: (data['view_count'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'owner_id': ownerId,
      'admin_id': adminId,
      'judul': judul,
      'deskripsi': deskripsi,
      'kategori': kategori.name,
      'foto_urls': fotoUrls,
      'video_url': videoUrl,
      'lokasi': lokasi.toMap(),
      'tanggal_kejadian': Timestamp.fromDate(tanggalKejadian),
      'created_at': FieldValue.serverTimestamp(),
      'tipe_laporan': tipeLaporan == TipeLaporan.found ? 'Found' : 'Lost',
      'status': status.name,
      'nominal_bounty': nominalBounty,
      'escrow_status': escrowStatus.name,
      'security_question': securityQuestion,
      'security_answer_hash': securityAnswerHash,
      'is_approved': false,
      'active_claim_id': null,
      'view_count': 0,
    };
  }

  static KategoriBarang _parseKategori(String? value) {
    return KategoriBarang.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => KategoriBarang.lainnya,
    );
  }

  static ItemStatus _parseStatus(String? value) {
    return ItemStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ItemStatus.active,
    );
  }

  static EscrowStatus _parseEscrow(String? value) {
    return EscrowStatus.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => EscrowStatus.none,
    );
  }
}