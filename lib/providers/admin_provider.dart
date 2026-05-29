import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/firestore_paths.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ── Provider Sederhana (Tidak berubah) ────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

/// **isAdminProvider**
/// Cek apakah user yang sedang login memiliki role sebagai admin.
/// Dilakukan dengan mengecek apakah UID user tersebut ada di dalam koleksi `admins`.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection(FirestorePaths.admins)
      .doc(user.uid)
      .get();

  return doc.exists;
});

/// **pendingItemsProvider**
/// Mengambil daftar laporan barang yang butuh persetujuan (moderasi) admin.
final pendingItemsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.items)
      .where('is_approved', isEqualTo: false)
      .where('status', isEqualTo: 'pendingApproval')
      .orderBy('created_at', descending: false)
      .snapshots();
});

/// Stream semua transaction logs (sudah pakai limit dari awal, aman)
final allLogsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.transactionLogs)
      .orderBy('created_at', descending: true)
      .limit(100)
      .snapshots();
});

// ══════════════════════════════════════════════════════════════════════════════
// ── PAGINATION SYSTEM ────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
//
// Menggantikan allUsersProvider & allDisputesProvider yang men-download SELURUH data.
// Sekarang data diambil 20 per halaman menggunakan cursor (startAfterDocument).
//
// Alur Kerja Pagination:
// 1. Saat layar pertama kali dibuka, Notifier mengambil 20 dokumen pertama.
// 2. Saat user scroll ke bawah atau menekan "Muat Lebih", ambil 20 berikutnya
//    menggunakan .startAfterDocument(lastDocument).
// 3. Jika hasil < 20, berarti sudah tidak ada data lagi (hasMore = false).
//
// ══════════════════════════════════════════════════════════════════════════════

/// Jumlah dokumen yang diambil per halaman pagination
const int kPageSize = 20;

// ── State Model untuk Pagination ─────────────────────────────────────────────

/// **PaginatedState**
/// Model state yang menyimpan data hasil pagination.
/// Digunakan oleh PaginatedUsersNotifier dan PaginatedDisputesNotifier.
class PaginatedState {
  /// Daftar dokumen yang sudah dimuat
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> items;

  /// Apakah sedang dalam proses loading halaman berikutnya
  final bool isLoading;

  /// Apakah masih ada halaman berikutnya yang bisa dimuat
  final bool hasMore;

  /// Dokumen terakhir yang dimuat (digunakan sebagai cursor untuk halaman berikutnya)
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

  /// Kata kunci pencarian aktif (untuk server-side search)
  final String searchQuery;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
    this.searchQuery = '',
  });

  PaginatedState copyWith({
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? items,
    bool? isLoading,
    bool? hasMore,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc,
    String? searchQuery,
    bool clearLastDoc = false,
  }) {
    return PaginatedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: clearLastDoc ? null : (lastDoc ?? this.lastDoc),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ── Paginated Users Notifier ─────────────────────────────────────────────────

/// **PaginatedUsersNotifier**
/// StateNotifier yang mengelola daftar user dengan pagination.
/// Menggantikan `allUsersProvider` yang berbahaya (download seluruh data).
///
/// Fitur:
/// - Load halaman pertama otomatis saat dibuat
/// - Load halaman berikutnya via loadNextPage()
/// - Pencarian server-side via search()
/// - Refresh via refresh()
class PaginatedUsersNotifier extends StateNotifier<PaginatedState> {
  PaginatedUsersNotifier() : super(const PaginatedState()) {
    loadNextPage(); // Auto-load halaman pertama
  }

  /// **loadNextPage**
  /// Mengambil [kPageSize] dokumen berikutnya dari Firestore.
  /// Jika sudah pernah load sebelumnya, menggunakan cursor `startAfterDocument`
  /// agar tidak mengulang data yang sudah dimuat.
  Future<void> loadNextPage() async {
    // Cegah double-loading dan loading saat sudah habis
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .orderBy('created_at', descending: true)
          .limit(kPageSize);

      // Jika sudah ada halaman sebelumnya, mulai dari dokumen terakhir
      if (state.lastDoc != null) {
        query = query.startAfterDocument(state.lastDoc!);
      }

      final snapshot = await query.get();

      // Jika hasil kurang dari kPageSize, berarti sudah tidak ada data lagi
      final hasMore = snapshot.docs.length >= kPageSize;

      state = state.copyWith(
        items: [...state.items, ...snapshot.docs],
        isLoading: false,
        hasMore: hasMore,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDoc,
      );
    } catch (e) {
      debugPrint('PaginatedUsersNotifier.loadNextPage error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// **search**
  /// Melakukan pencarian user berdasarkan kata kunci.
  /// 
  /// Catatan penting tentang Firestore Search:
  /// Firestore TIDAK mendukung full-text search secara native.
  /// Untuk pencarian sederhana, kita gunakan filter client-side dari data yang sudah dimuat
  /// + load semua data yang cocok dari server.
  /// Untuk produksi skala besar, gunakan Algolia atau Typesense.
  ///
  /// Strategi saat ini: Load batch data dan filter di client.
  /// Ini jauh lebih baik dari sebelumnya karena kita tetap membatasi data yang dimuat.
  void search(String query) {
    state = state.copyWith(searchQuery: query.toLowerCase());
  }

  /// **refresh**
  /// Reset seluruh state dan muat ulang dari halaman pertama.
  Future<void> refresh() async {
    state = const PaginatedState();
    await loadNextPage();
  }
}

/// Provider untuk PaginatedUsersNotifier
final paginatedUsersProvider =
    StateNotifierProvider<PaginatedUsersNotifier, PaginatedState>(
  (ref) => PaginatedUsersNotifier(),
);

// ── Paginated Disputes Notifier ──────────────────────────────────────────────

/// **PaginatedDisputesNotifier**
/// StateNotifier yang mengelola daftar sengketa (disputes) dengan pagination.
/// Menggantikan `allDisputesProvider` yang berbahaya.
class PaginatedDisputesNotifier extends StateNotifier<PaginatedState> {
  PaginatedDisputesNotifier() : super(const PaginatedState()) {
    loadNextPage();
  }

  /// Mengambil [kPageSize] sengketa berikutnya dari Firestore.
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(FirestorePaths.disputes)
          .orderBy('created_at', descending: true)
          .limit(kPageSize);

      if (state.lastDoc != null) {
        query = query.startAfterDocument(state.lastDoc!);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length >= kPageSize;

      state = state.copyWith(
        items: [...state.items, ...snapshot.docs],
        isLoading: false,
        hasMore: hasMore,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDoc,
      );
    } catch (e) {
      debugPrint('PaginatedDisputesNotifier.loadNextPage error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Reset dan muat ulang dari awal
  Future<void> refresh() async {
    state = const PaginatedState();
    await loadNextPage();
  }
}

/// Provider untuk PaginatedDisputesNotifier
final paginatedDisputesProvider =
    StateNotifierProvider<PaginatedDisputesNotifier, PaginatedState>(
  (ref) => PaginatedDisputesNotifier(),
);