import 'package:flutter/material.dart';

class AppColors {
  // Sabit UI renkleri (tema bağımsız)
  static const background = Color(0xFFF2F2F7);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);
  static const divider = Color(0xFFE5E5EA);
  static const success = Color(0xFF34C759);
  static const danger = Color(0xFFFF3B30);
  static const warning = Color(0xFFFF9500);

  // Tema primary rengi context'ten alınır; fallback
  static const primary = Color(0xFF1A1A2E);
  static const accent = Color(0xFFC9A84C);

  // Hizmet renk paleti (varsayılan hizmetler için)
  static const List<String> serviceColorPalette = [
    '#FF3B30', '#FF9500', '#FFCC00', '#34C759',
    '#00C7BE', '#30D158', '#32ADE6', '#007AFF',
    '#5856D6', '#AF52DE', '#FF2D55', '#8E8E93',
    '#C9A84C', '#D4A373', '#6B4226', '#2D6A4F',
  ];

  static Color fromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  // Dark mode uyumlu arka plan rengi
  static Color adaptiveBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color adaptiveSurface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color adaptiveTextPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color primaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color accentColor(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
}
