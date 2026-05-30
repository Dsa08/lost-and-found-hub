import 'package:flutter/material.dart';

/// **AppColors (Palet Warna Utama)**
/// Menyimpan seluruh konstanta warna agar konsisten di seluruh aplikasi.
/// Dikelompokkan berdasarkan fungsi (Primary, Status, Background, Guild).
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF1A73E8);       // Biru Google (kepercayaan)
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFFE8F0FE);

  // Desktop Sidebar (SaaS Dark Mode)
  static const Color sidebarDark = Color(0xFF0B0F19);   // Midnight Blue / Sangat Gelap
  static const Color sidebarSurface = Color(0xFF151B2B); // Sedikit lebih terang untuk card di sidebar
  static const Color sidebarActive = Color(0xFF1E40AF);  // Soft glow blue untuk hover
  static const Color sidebarText = Color(0xFF94A3B8);    // Slate 400
  static const Color sidebarTextActive = Color(0xFFFFFFFF); // Putih bersih

  // Hover Effect (Glassmorphism)
  static const Color glassWhite = Color(0x1AFFFFFF); // Putih transparan 10%

  // Bounty / Gold Accent
  static const Color bounty = Color(0xFFFFB300);         // Amber — untuk bounty/poin
  static const Color bountyLight = Color(0xFFFFF8E1);

  // Status Colors
  static const Color statusActive = Color(0xFF34A853);   // Hijau
  static const Color statusPending = Color(0xFFFB8C00);  // Oranye
  static const Color statusResolved = Color(0xFF9E9E9E); // Abu
  static const Color statusLost = Color(0xFFE53935);     // Merah
  static const Color statusFound = Color(0xFF43A047);    // Hijau

  // Background
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);

  // Text
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9AA0A6);

  // Guild Colors (tiap level)
  static const Color guildBronze = Color(0xFFCD7F32);
  static const Color guildSilver = Color(0xFFC0C0C0);
  static const Color guildGold = Color(0xFFFFD700);
  static const Color guildPlatinum = Color(0xFF00BCD4);
  static const Color guildDiamond = Color(0xFF7C4DFF);

  // Danger / Error
  static const Color error = Color(0xFFB00020);
  static const Color errorLight = Color(0xFFFFEDED);

  // Border & Divider
  static const Color border = Color(0xFFDADCE0);
  static const Color divider = Color(0xFFE8EAED);
}