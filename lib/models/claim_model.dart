import 'package:cloud_firestore/cloud_firestore.dart';

/// **Status Klaim (ClaimStatus)**
/// Siklus klaim saat seseorang mengaku menemukan/memiliki barang:
/// - `waiting`: Klaim diajukan, menunggu pemilik asli membaca jawaban keamanan dan menyetujui.
/// - `approved`: Pemilik setuju bahwa klaim valid. Mengubah status barang jadi 'pendingMeetup'.
/// - `rejected`: Pemilik merasa klaim palsu (jawaban keamanan salah). Klaim dibatalkan.
enum ClaimStatus { waiting, approved, rejected }

/// **ClaimModel**
/// Merepresentasikan entitas "Klaim" di Firestore (koleksi 'claims').
/// Terjadi ketika user B melihat laporan user A, lalu mengeklik "Klaim Barang"
/// dan menjawab Pertanyaan Keamanan yang dibuat user A.
class ClaimModel {
  /// ID dokumen klaim di Firestore.
  final String claimId;
  /// ID barang (ItemModel) yang sedang diklaim.
  final String itemId;
  /// UID pengguna yang mengajukan klaim.
  final String finderId;
  /// Jawaban teks yang dimasukkan saat menjawab Pertanyaan Keamanan.
  /// Ini akan ditampilkan kepada pemilik asli untuk diverifikasi manual.
  final String securityAnswer; 
  /// Status klaim saat ini (waiting / approved / rejected).
  final ClaimStatus status;
  final DateTime createdAt;

  const ClaimModel({
    required this.claimId,
    required this.itemId,
    required this.finderId,
    required this.securityAnswer,
    this.status = ClaimStatus.waiting,
    required this.createdAt,
  });

  factory ClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClaimModel(
      claimId: doc.id,
      itemId: data['item_id'] ?? '',
      finderId: data['finder_id'] ?? '',
      securityAnswer: data['security_answer'] ?? '',
      status: ClaimStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ClaimStatus.waiting,
      ),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'item_id': itemId,
      'finder_id': finderId,
      'security_answer': securityAnswer,
      'status': status.name,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}