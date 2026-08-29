import 'package:flutter/material.dart';

class AppColors {
  // Pure Monochromatic Base Palette (Reference 4 Aesthetic: Crisp, Editorial, No Neon/Glows)
  static const Color background = Color(0xFFF9F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F3F5);
  static const Color surfaceDark = Color(0xFF141414);
  static const Color surfaceDarkMuted = Color(0xFF1F1F1F);

  // Translucent Glass Surfaces
  static Color glassLight = Colors.white.withValues(alpha: 0.85);
  static Color glassDark = Colors.black.withValues(alpha: 0.45);
  static Color glassPill = Colors.white.withValues(alpha: 0.18);
  static Color glassCard = Colors.white.withValues(alpha: 0.12);

  // Pure High-Contrast Monochromatic Accents
  static const Color primary = Color(0xFF111111);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF222222);
  static const Color accent = Color(0xFF111111);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textLightPrimary = Color(0xFFFFFFFF);
  static const Color textLightSecondary = Color(0xCCFFFFFF);

  // Subtle Status Tints (Muted & Elegant, No Loud Neon)
  static const Color statusUrgent = Color(0xFFD32F2F);
  static const Color statusWarning = Color(0xFF555555);
  static const Color statusFresh = Color(0xFF2E7D32);
  static const Color statusMuted = Color(0xFF757575);

  // Clean Borders (Invisible or Ultra Subtle)
  static const Color cardBorder = Color(0x08000000);
  static const Color cardBorderDark = Color(0x1FFFFFFF);
  static const Color divider = Color(0x0D000000);

  // Backward compatibility alias constants
  static const Color freshGood = Color(0xFF2E7D32);
  static const Color soonExpiring = Color(0xFF616161);
  static const Color freshExpiring = Color(0xFF616161);
  static const Color urgentExpiring = Color(0xFFD32F2F);
  static const Color frozenPantry = Color(0xFF546E7A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF2F3F5);
  static const Color surfaceElevatedDark = Color(0xFF1F1F1F);
  static const Color backgroundDark = Color(0xFF0D0D0D);
  static const Color backgroundLight = Color(0xFFF9F9FA);
  static const Color caloriesColor = Color(0xFF111111);
  static const Color proteinColor = Color(0xFF333333);
  static const Color fatColor = Color(0xFF555555);
  static const Color carbColor = Color(0xFF777777);
  static const Color secondaryLight = Color(0xFFF2F3F5);
  static const Color secondaryContainer = Color(0xFFF2F3F5);
  static const Color primaryDark = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFF333333);
  static const Color primaryContainer = Color(0xFFF2F3F5);
  static const Color ecoGreen = Color(0xFF2E7D32);
  static const Color savingsGold = Color(0xFF111111);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color textSecondaryLight = Color(0xFF6E6E73);
  static const Color textTertiaryDark = Color(0xFF636366);
  static const Color textTertiaryLight = Color(0xFF9E9E9E);
}
