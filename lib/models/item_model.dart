import 'package:cloud_firestore/cloud_firestore.dart';

enum TipeLaporan { lost, found }
enum ItemStatus { active, pendingApproval, pendingMeetup, resolved, expired }
enum EscrowStatus { none, locked, released, refunded }
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

class ItemModel {
  final String itemId;
  final String ownerId;
  final String? adminId;
  final String judul;
  final String deskripsi;
  final KategoriBarang kategori;
  final List<String> fotoUrls;
  final String? videoUrl;        // ← BARU: URL video bukti
  final ItemLocation lokasi;
  final DateTime tanggalKejadian;
  final DateTime createdAt;
  final TipeLaporan tipeLaporan;
  final ItemStatus status;
  final int nominalBounty;
  final EscrowStatus escrowStatus;
  final String? securityQuestion;
  final String? securityAnswerHash;
  final bool isApproved;
  final String? activeClaimId;
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