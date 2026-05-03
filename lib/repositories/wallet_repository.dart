import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/firestore_paths.dart';
import '../providers/items_provider.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(db: ref.watch(firestoreProvider));
});

class WalletRepository {
  final FirebaseFirestore _db;
  WalletRepository({required FirebaseFirestore db}) : _db = db;

  /// Kunci poin ke escrow saat membuat laporan dengan bounty
  Future<void> lockEscrow({
    required String userId,
    required String itemId,
    required int bountyAmount,
  }) async {
    if (bountyAmount <= 0) return;

    final userRef = _db.collection(FirestorePaths.users).doc(userId);
    final itemRef = _db.collection(FirestorePaths.items).doc(itemId);
    final logRef = _db.collection(FirestorePaths.transactionLogs).doc();

    await _db.runTransaction((txn) async {
      final userSnap = await txn.get(userRef);
      final data = userSnap.data()!;
      final currentTotal = (data['total_poin'] ?? 0) as int;
      final currentLocked = (data['locked_poin'] ?? 0) as int;

      if (currentTotal < bountyAmount) {
        throw Exception('Saldo poin tidak mencukupi. Saldo kamu: $currentTotal poin');
      }

      txn.update(userRef, {
        'total_poin': currentTotal - bountyAmount,
        'locked_poin': currentLocked + bountyAmount,
      });

      txn.update(itemRef, {'escrow_status': 'locked'});

      txn.set(logRef, {
        'type': 'Escrow_Lock',
        'from_user': userId,
        'to_user': null,
        'amount': bountyAmount,
        'item_id': itemId,
        'created_at': FieldValue.serverTimestamp(),
        'metadata': {'note': 'Bounty dikunci saat laporan dibuat'},
      });
    });
  }

  /// Refund poin jika item di-cancel atau expired
  Future<void> refundEscrow({
    required String userId,
    required String itemId,
    required int bountyAmount,
  }) async {
    if (bountyAmount <= 0) return;

    final userRef = _db.collection(FirestorePaths.users).doc(userId);
    final itemRef = _db.collection(FirestorePaths.items).doc(itemId);
    final logRef = _db.collection(FirestorePaths.transactionLogs).doc();

    await _db.runTransaction((txn) async {
      final userSnap = await txn.get(userRef);
      final data = userSnap.data()!;
      final currentTotal = (data['total_poin'] ?? 0) as int;
      final currentLocked = (data['locked_poin'] ?? 0) as int;

      txn.update(userRef, {
        'total_poin': currentTotal + bountyAmount,
        'locked_poin': (currentLocked - bountyAmount).clamp(0, double.infinity).toInt(),
      });

      txn.update(itemRef, {
        'escrow_status': 'refunded',
        'status': 'expired',
      });

      txn.set(logRef, {
        'type': 'Escrow_Refund',
        'from_user': null,
        'to_user': userId,
        'amount': bountyAmount,
        'item_id': itemId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Ambil history transaksi user
  Stream<List<Map<String, dynamic>>> getTransactionHistory(String userId) {
    return _db
        .collection(FirestorePaths.transactionLogs)
        .where(Filter.or(
          Filter('from_user', isEqualTo: userId),
          Filter('to_user', isEqualTo: userId),
        ))
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}