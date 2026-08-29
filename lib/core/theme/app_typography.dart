import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.onest(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.onest(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.onest(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.onest(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.onest(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.onest(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMedium => GoogleFonts.onest(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.onest(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.onest(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: AppColors.primaryForeground,
      );

  static TextStyle get labelMedium => GoogleFonts.onest(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.onest(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.textSecondary,
      );

  static TextStyle get numberMetric => GoogleFonts.onest(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      );
}
