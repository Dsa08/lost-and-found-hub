import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/firestore_paths.dart';

// ── Raw Firebase Auth stream ──────────────────────────────────────────────────
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// ── Current UserModel dari Firestore ─────────────────────────────────────────
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ── Auth Actions ──────────────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    db: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRepository({required FirebaseAuth auth, required FirebaseFirestore db})
      : _auth = auth,
        _db = db;

  // Register user baru
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
    required String nama,
    required String noHp,
  }) async {
    // Cek username unik
    final usernameCheck = await _db
        .collection(FirestorePaths.users)
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (usernameCheck.docs.isNotEmpty) {
      throw Exception('Username sudah digunakan');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: credential.user!.uid,
      username: username,
      nama: nama,
      email: email,
      noHp: noHp,
      totalPoin: 100, // Bonus poin awal untuk user baru
      lockedPoin: 0,
      createdAt: DateTime.now(),
      stats: const UserStats(),
    );

    await _db
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .set(user.toFirestore());

    return user;
  }

  // Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}