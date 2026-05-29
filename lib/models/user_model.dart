import 'package:cloud_firestore/cloud_firestore.dart';

/// **UserModel**
/// Merepresentasikan entitas pengguna (User) di dalam database Firestore (koleksi 'users').
/// Kelas ini immutable (tidak bisa diubah langsung), perubahan state harus menggunakan `copyWith()`.
class UserModel {
  /// UID unik pengguna dari Firebase Auth (sebagai Document ID di Firestore).
  final String uid;
  final String username;
  final String nama;
  final String email;
  final String noHp;
  /// URL foto profil pengguna (bisa null jika belum mengatur foto).
  final String? fotoProfilUrl;
  /// Token Firebase Cloud Messaging untuk mengirimkan Push Notification ke perangkat ini.
  final String? fcmToken;
  
  // ── Sistem Poin (Escrow & Reward) ──
  /// Total poin aktif yang dimiliki pengguna (bisa dipakai untuk membuat sayembara).
  final int totalPoin;
  /// Poin yang saat ini sedang "ditahan" oleh sistem (Escrow) karena pengguna sedang membuat laporan kehilangan.
  /// Poin ini belum dipotong permanen, hanya dikunci sampai laporan selesai.
  final int lockedPoin;
  
  // ── Sistem Reputasi & Guild ──
  /// Skor reputasi pengguna (Mulai dari 50.0). Naik jika sering mengembalikan barang, turun jika sering kena sengketa.
  final double reputationScore;
  /// ID Guild (Komunitas) tempat pengguna ini bergabung. Null jika tidak ikut guild manapun.
  final String? guildId;
  final DateTime createdAt;
  final UserStats stats;

  const UserModel({
    required this.uid,
    required this.username,
    required this.nama,
    required this.email,
    required this.noHp,
    this.fotoProfilUrl,
    this.fcmToken,
    this.totalPoin = 0,
    this.lockedPoin = 0,
    this.reputationScore = 50.0,
    this.guildId,
    required this.createdAt,
    required this.stats,
  });

  /// Mengambil saldo riil yang benar-benar bisa dipakai (Total - Dikunci).
  /// Ini memastikan user tidak bisa pakai poin ganda yang sedang terkunci di sayembara lain.
  int get availablePoin => totalPoin; // TODO: [Refactor] Seharusnya `totalPoin - lockedPoin`

  /// **Konversi dari Document Firestore menjadi Objek Dart (Deserialisasi)**
  /// Fungsi ini digunakan setiap kali kita mengambil data user dari database.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      username: data['username'] ?? '',
      nama: data['nama'] ?? '',
      email: data['email'] ?? '',
      noHp: data['no_hp'] ?? '',
      fotoProfilUrl: data['foto_profil_url'],
      fcmToken: data['fcm_token'],
      totalPoin: (data['total_poin'] ?? 0).toInt(),
      lockedPoin: (data['locked_poin'] ?? 0).toInt(),
      reputationScore: (data['reputation_score'] ?? 50.0).toDouble(),
      guildId: data['guild_id'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stats: UserStats.fromMap(data['stats'] ?? {}),
    );
  }

  /// **Konversi dari Objek Dart menjadi Map (Serialisasi)**
  /// Fungsi ini digunakan saat menyimpan/mengupdate data user ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'nama': nama,
      'email': email,
      'no_hp': noHp,
      'foto_profil_url': fotoProfilUrl,
      'fcm_token': fcmToken,
      'total_poin': totalPoin,
      'locked_poin': lockedPoin,
      'reputation_score': reputationScore,
      'guild_id': guildId,
      'created_at': FieldValue.serverTimestamp(),
      'last_active': FieldValue.serverTimestamp(),
      'stats': stats.toMap(),
    };
  }

  UserModel copyWith({
    String? username,
    String? nama,
    String? noHp,
    String? fotoProfilUrl,
    String? fcmToken,
    int? totalPoin,
    int? lockedPoin,
    String? guildId,
  }) {
    return UserModel(
      uid: uid,
      username: username ?? this.username,
      nama: nama ?? this.nama,
      email: email,
      noHp: noHp ?? this.noHp,
      fotoProfilUrl: fotoProfilUrl ?? this.fotoProfilUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      totalPoin: totalPoin ?? this.totalPoin,
      lockedPoin: lockedPoin ?? this.lockedPoin,
      reputationScore: reputationScore,
      guildId: guildId ?? this.guildId,
      createdAt: createdAt,
      stats: stats,
    );
  }
}

/// **UserStats**
/// Kelas pendukung untuk melacak statistik kontribusi pengguna.
/// Data ini akan tampil di profil pengguna dan menentukan status rank/level mereka.
class UserStats {
  /// Total barang yang berhasil dikembalikan oleh user ini ke pemiliknya.
  final int totalResolved;
  /// Total laporan barang hilang/temuan yang dibuat oleh user ini.
  final int totalReports;

  const UserStats({
    this.totalResolved = 0,
    this.totalReports = 0,
  });

  double get successRate =>
      totalReports == 0 ? 0 : (totalResolved / totalReports * 100);

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalResolved: (map['total_resolved'] ?? 0).toInt(),
      totalReports: (map['total_reports'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_resolved': totalResolved,
      'total_reports': totalReports,
      'success_rate': successRate,
    };
  }
}