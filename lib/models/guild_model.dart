import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import 'package:flutter/material.dart';

enum GuildLevel { bronze, silver, gold, platinum, diamond }

class GuildModel {
  final String guildId;
  final String namaGuild;
  final String deskripsi;
  final String? fotoGuildUrl;
  final GuildLevel levelGuild;
  final int totalReputasi;
  final int memberCount;
  final String createdBy;
  final DateTime createdAt;

  const GuildModel({
    required this.guildId,
    required this.namaGuild,
    required this.deskripsi,
    this.fotoGuildUrl,
    this.levelGuild = GuildLevel.bronze,
    this.totalReputasi = 0,
    this.memberCount = 1,
    required this.createdBy,
    required this.createdAt,
  });

  Color get levelColor {
    switch (levelGuild) {
      case GuildLevel.bronze: return AppColors.guildBronze;
      case GuildLevel.silver: return AppColors.guildSilver;
      case GuildLevel.gold: return AppColors.guildGold;
      case GuildLevel.platinum: return AppColors.guildPlatinum;
      case GuildLevel.diamond: return AppColors.guildDiamond;
    }
  }

  String get levelLabel {
    switch (levelGuild) {
      case GuildLevel.bronze: return 'Bronze';
      case GuildLevel.silver: return 'Silver';
      case GuildLevel.gold: return 'Gold';
      case GuildLevel.platinum: return 'Platinum';
      case GuildLevel.diamond: return 'Diamond';
    }
  }

  static GuildLevel _levelFromReputasi(int reputasi) {
    if (reputasi >= 5000) return GuildLevel.diamond;
    if (reputasi >= 2000) return GuildLevel.platinum;
    if (reputasi >= 1000) return GuildLevel.gold;
    if (reputasi >= 300) return GuildLevel.silver;
    return GuildLevel.bronze;
  }

  factory GuildModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final reputasi = (data['total_reputasi'] ?? 0).toInt();
    return GuildModel(
      guildId: doc.id,
      namaGuild: data['nama_guild'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      fotoGuildUrl: data['foto_guild_url'],
      levelGuild: _levelFromReputasi(reputasi),
      totalReputasi: reputasi,
      memberCount: (data['member_count'] ?? 1).toInt(),
      createdBy: data['created_by'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nama_guild': namaGuild,
    'deskripsi': deskripsi,
    'foto_guild_url': fotoGuildUrl,
    'level_guild': levelGuild.index + 1,
    'total_reputasi': totalReputasi,
    'member_count': memberCount,
    'created_by': createdBy,
    'created_at': FieldValue.serverTimestamp(),
  };
}