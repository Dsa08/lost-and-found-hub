import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String nama;
  final String email;
  final String noHp;
  final String? fotoProfilUrl;
  final String? fcmToken;
  final int totalPoin;
  final int lockedPoin;
  final double reputationScore;
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

  /// Saldo yang benar-benar bisa digunakan (tidak termasuk yang terkunci)
  int get availablePoin => totalPoin;

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

class UserStats {
  final int totalResolved;
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