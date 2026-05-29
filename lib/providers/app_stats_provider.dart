import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_stats_model.dart';

/// **appStatsProvider**
/// Menyediakan stream (aliran data real-time) untuk statistik utama aplikasi yang tampil di Dashboard.
/// Menggunakan fitur agregasi Firestore `count()` agar JAUH lebih efisien daripada download seluruh dokumen.
///
/// Statistik yang dihitung:
/// - `totalBarang`: Jumlah item yang sudah di-approve
/// - `totalSelesai`: Jumlah item berstatus 'resolved'
/// - `totalGuild`: Jumlah guild yang terdaftar
/// - `totalUsers`: Jumlah seluruh user (BARU - menggantikan allUsersProvider.docs.length)
/// - `openDisputes`: Jumlah sengketa yang masih Open (BARU - menggantikan allDisputesProvider filter)
///
/// // TODO: [Refactor] Jika data mencapai jutaan, pertimbangkan menggunakan Cloud Functions
/// // trigger untuk menyimpan angka-angka ini di satu dokumen khusus 'stats/global'.
final appStatsProvider = StreamProvider<AppStats>((ref) {
  final db = FirebaseFirestore.instance;

  // Re-trigger setiap ada perubahan di koleksi items
  return db
      .collection('items')
      .snapshots()
      .asyncMap((_) async {
    final results = await Future.wait([
      db.collection('items')
          .where('is_approved', isEqualTo: true)
          .count()
          .get(),
      db.collection('items')
          .where('status', isEqualTo: 'resolved')
          .count()
          .get(),
      db.collection('guilds')
          .count()
          .get(),
      // BARU: Hitung total user dengan count() — tanpa download data
      db.collection('users')
          .count()
          .get(),
      // BARU: Hitung sengketa Open dengan count() — tanpa download data
      db.collection('disputes')
          .where('status', isEqualTo: 'Open')
          .count()
          .get(),
    ]);

    return AppStats(
      totalBarang: results[0].count ?? 0,
      totalSelesai: results[1].count ?? 0,
      totalGuild: results[2].count ?? 0,
      totalUsers: results[3].count ?? 0,
      openDisputes: results[4].count ?? 0,
    );
  });
});