import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/firestore_paths.dart';
import '../providers/items_provider.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(db: ref.watch(firestoreProvider));
});

/// **WalletRepository**
/// Menangani operasi database terkait dompet pengguna dan Sistem Escrow (Poin).
/// Menggunakan `_db.runTransaction` agar operasi baca-tulis aman dari konflik (Race Condition),
/// memastikan saldo poin tidak akan mines jika ada dua transaksi bersamaan.
class WalletRepository {
  final FirebaseFirestore _db;
  WalletRepository({required FirebaseFirestore db}) : _db = db;

  /// **Fungsi lockEscrow (Kunci Saldo)**
  /// Dipanggil saat user membuat laporan dengan menjanjikan hadiah (bounty).
  /// Fungsi ini akan mengurangi `total_poin` user dan memindahkannya ke `locked_poin`.
  /// Jika saldo tidak cukup, transaksi dibatalkan (throw Exception).
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

  /// **Fungsi refundEscrow (Kembalikan Saldo)**
  /// Dipanggil jika laporan ditolak admin, kadaluarsa, atau sengketa dimenangkan pelapor.
  /// Mengurangi `locked_poin` dan menambahkannya kembali ke `total_poin` user.
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