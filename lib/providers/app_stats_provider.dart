import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_stats_model.dart';

/// Stream real-time statistik app dari Firestore menggunakan count()
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
    ]);

    return AppStats(
      totalBarang: results[0].count ?? 0,
      totalSelesai: results[1].count ?? 0,
      totalGuild: results[2].count ?? 0,
    );
  });
});