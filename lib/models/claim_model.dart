import 'package:cloud_firestore/cloud_firestore.dart';

enum ClaimStatus { waiting, approved, rejected }

class ClaimModel {
  final String claimId;
  final String itemId;
  final String finderId;
  final String securityAnswer; // jawaban yang disubmit (untuk ditampilkan ke owner)
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