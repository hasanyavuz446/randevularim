import 'package:flutter/material.dart';

class AppThemeConfig {
  final String id;
  final String name;
  final Color primary;
  final Color accent;
  final Color lightBg;
  final Color darkBg;
  final Color darkSurface;

  const AppThemeConfig({
    required this.id,
    required this.name,
    required this.primary,
    required this.accent,
    required this.lightBg,
    this.darkBg = const Color(0xFF1C1C1E),
    this.darkSurface = const Color(0xFF2C2C2E),
  });

  static AppThemeConfig fromId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => nightBlue);

  static const all = [
    nightBlue,
    forest,
    rose,
    lavender,
    ocean,
    sunset,
    anthracite,
    cream,
  ];

  // ─── Temalar ────────────────────────────────────────────────────────────────

  static const nightBlue = AppThemeConfig(
    id: 'night_blue',
    name: 'Gece Mavisi',
    primary: Color(0xFF496ED9),
    accent: Color(0xFFC9A84C),
    lightBg: Color(0xFFF2F2F7),
    darkBg: Color(0xFF0D0D1A),
    darkSurface: Color(0xFF1A1A2E),
  );

  static const forest = AppThemeConfig(
    id: 'forest',
    name: 'Orman Yeşili',
    primary: Color(0xFF2D6A4F),
    accent: Color(0xFF52B788),
    lightBg: Color(0xFFF0F7F4),
    darkBg: Color(0xFF0B1A12),
    darkSurface: Color(0xFF1A2E22),
  );

  static const rose = AppThemeConfig(
    id: 'rose',
    name: 'Gül',
    primary: Color(0xFF9D0208),
    accent: Color(0xFFE85D04),
    lightBg: Color(0xFFFFF5F5),
    darkBg: Color(0xFF1A0203),
    darkSurface: Color(0xFF2E0A0B),
  );

  static const lavender = AppThemeConfig(
    id: 'lavender',
    name: 'Lavanta',
    primary: Color(0xFF5E548E),
    accent: Color(0xFFBE95C4),
    lightBg: Color(0xFFF4F0F8),
    darkBg: Color(0xFF16111F),
    darkSurface: Color(0xFF26203A),
  );

  static const ocean = AppThemeConfig(
    id: 'ocean',
    name: 'Okyanus',
    primary: Color(0xFF0077B6),
    accent: Color(0xFF00B4D8),
    lightBg: Color(0xFFF0F7FF),
    darkBg: Color(0xFF001A2E),
    darkSurface: Color(0xFF002D4E),
  );

  static const sunset = AppThemeConfig(
    id: 'sunset',
    name: 'Güneş Batımı',
    primary: Color(0xFFD62828),
    accent: Color(0xFFF77F00),
    lightBg: Color(0xFFFFF8F0),
    darkBg: Color(0xFF1F0A00),
    darkSurface: Color(0xFF331200),
  );

  static const anthracite = AppThemeConfig(
    id: 'anthracite',
    name: 'Antrasit',
    primary: Color(0xFF2B2D42),
    accent: Color(0xFF8D99AE),
    lightBg: Color(0xFFF0F1F2),
    darkBg: Color(0xFF0D0E12),
    darkSurface: Color(0xFF1A1C24),
  );

  static const cream = AppThemeConfig(
    id: 'cream',
    name: 'Krem',
    primary: Color(0xFF6B4226),
    accent: Color(0xFFD4A373),
    lightBg: Color(0xFFFAF3E0),
    darkBg: Color(0xFF1A0C03),
    darkSurface: Color(0xFF2E1A0A),
  );
}
