import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../core/constants/firestore_paths.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ── Filter State ──────────────────────────────────────────────────────────────
class ItemFilter {
  final String? kategori;
  final TipeLaporan? tipe;
  final bool showOnlyBounty;

  const ItemFilter({
    this.kategori,
    this.tipe,
    this.showOnlyBounty = false,
  });

  ItemFilter copyWith({
    String? kategori,
    TipeLaporan? tipe,
    bool? showOnlyBounty,
  }) => ItemFilter(
    kategori: kategori ?? this.kategori,
    tipe: tipe ?? this.tipe,
    showOnlyBounty: showOnlyBounty ?? this.showOnlyBounty,
  );
}

final itemFilterProvider = StateProvider<ItemFilter>((ref) => const ItemFilter());

// ── Active Items Stream (Dashboard) ──────────────────────────────────────────
final activeItemsProvider = StreamProvider<List<ItemModel>>((ref) {
  final filter = ref.watch(itemFilterProvider);
  final db = ref.watch(firestoreProvider);

  Query<Map<String, dynamic>> query = db
      .collection(FirestorePaths.items)
      .where('status', isEqualTo: 'active')
      .where('is_approved', isEqualTo: true)
      .orderBy('created_at', descending: true)
      .limit(30);

  if (filter.kategori != null) {
    query = query.where('kategori', isEqualTo: filter.kategori);
  }
  if (filter.tipe != null) {
    query = query.where(
      'tipe_laporan',
      isEqualTo: filter.tipe == TipeLaporan.lost ? 'Lost' : 'Found',
    );
  }
  if (filter.showOnlyBounty) {
    query = query.where('nominal_bounty', isGreaterThan: 0);
  }

  return query
      .snapshots()
      .map((snap) => snap.docs.map(ItemModel.fromFirestore).toList());
});

// ── Item By ID ────────────────────────────────────────────────────────────────
final itemByIdProvider = StreamProvider.family<ItemModel?, String>((ref, itemId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection(FirestorePaths.items)
      .doc(itemId)
      .snapshots()
      .map((doc) => doc.exists ? ItemModel.fromFirestore(doc) : null);
});

// ── My Items (laporan saya) ───────────────────────────────────────────────────
final myItemsProvider = StreamProvider.family<List<ItemModel>, String>((ref, userId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection(FirestorePaths.items)
      .where('owner_id', isEqualTo: userId)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ItemModel.fromFirestore).toList());
});

// ── Items Repository ──────────────────────────────────────────────────────────
final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepository(db: ref.watch(firestoreProvider));
});

class ItemsRepository {
  final FirebaseFirestore _db;
  ItemsRepository({required FirebaseFirestore db}) : _db = db;

  Future<String> createItem(ItemModel item) async {
    final ref = _db.collection(FirestorePaths.items).doc();
    final itemWithId = item;
    await ref.set(itemWithId.toFirestore());
    return ref.id;
  }

  Future<void> incrementViewCount(String itemId) async {
    await _db.collection(FirestorePaths.items).doc(itemId).update({
      'view_count': FieldValue.increment(1),
    });
  }

  Future<void> submitClaim({
    required String itemId,
    required String finderId,
    required String securityAnswer,
  }) async {
    // Cek apakah sudah ada klaim aktif dari user ini
    final existing = await _db
        .collection(FirestorePaths.itemClaims(itemId))
        .where('finder_id', isEqualTo: finderId)
        .where('status', whereIn: ['waiting', 'approved'])
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Kamu sudah mengajukan klaim untuk barang ini');
    }

    await _db.collection(FirestorePaths.itemClaims(itemId)).add({
      'item_id': itemId,
      'finder_id': finderId,
      'security_answer': securityAnswer,
      'status': 'waiting',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveClaim({
    required String itemId,
    required String claimId,
    required String finderId,
  }) async {
    final batch = _db.batch();

    // Approve klaim ini
    batch.update(
      _db.doc(FirestorePaths.claimDoc(itemId, claimId)),
      {'status': 'approved'},
    );

    // Update status item ke pending meetup
    batch.update(_db.doc(FirestorePaths.itemDoc(itemId)), {
      'status': 'pendingMeetup',
      'active_claim_id': finderId,
    });

    await batch.commit();
  }

  Future<void> rejectClaim(String itemId, String claimId) async {
    await _db
        .doc(FirestorePaths.claimDoc(itemId, claimId))
        .update({'status': 'rejected'});
  }
}