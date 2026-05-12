import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/firestore_paths.dart';

/// Cek apakah user yang sedang login adalah admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection(FirestorePaths.admins)
      .doc(user.uid)
      .get();

  return doc.exists;
});

/// Stream semua items yang belum diapprove (antrian moderasi)
final pendingItemsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.items)
      .where('is_approved', isEqualTo: false)
      .where('status', isEqualTo: 'pendingApproval')
      .orderBy('created_at', descending: false)
      .snapshots();
});

/// Stream semua users
final allUsersProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.users)
      .orderBy('created_at', descending: true)
      .snapshots();
});

/// Stream semua disputes
final allDisputesProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.disputes)
      .orderBy('created_at', descending: true)
      .snapshots();
});

/// Stream semua transaction logs
final allLogsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.transactionLogs)
      .orderBy('created_at', descending: true)
      .limit(100)
      .snapshots();
});