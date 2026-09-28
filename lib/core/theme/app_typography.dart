import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Pennora typography system using the Inter typeface.
///
/// Clean, professional, structured modern sans-serif scale.
abstract final class AppTypography {
  // ─────────────────────────────────────────────────────────────
  // Light Theme Text Theme
  // ─────────────────────────────────────────────────────────────

  static TextTheme get lightTextTheme => _buildTextTheme(
        primary: AppColors.textPrimaryLight,
        secondary: AppColors.textSecondaryLight,
        tertiary: AppColors.textTertiaryLight,
      );

  // ─────────────────────────────────────────────────────────────
  // Dark Theme Text Theme
  // ─────────────────────────────────────────────────────────────

  static TextTheme get darkTextTheme => _buildTextTheme(
        primary: AppColors.textPrimaryDark,
        secondary: AppColors.textSecondaryDark,
        tertiary: AppColors.textTertiaryDark,
      );

  // ─────────────────────────────────────────────────────────────
  // Internal Builder
  // ─────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
  }) {
    return TextTheme(
      // ── Display ──────────────────────────────────────────────
      displayLarge: _style(
        size: 40,
        weight: FontWeight.w700,
        color: primary,
        letterSpacing: -1.0,
        height: 1.15,
      ),
      displayMedium: _style(
        size: 32,
        weight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.75,
        height: 1.2,
      ),
      displaySmall: _style(
        size: 28,
        weight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
        height: 1.25,
      ),

      // ── Headline ─────────────────────────────────────────────
      headlineLarge: _style(
        size: 26,
        weight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.4,
        height: 1.25,
      ),
      headlineMedium: _style(
        size: 22,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      headlineSmall: _style(
        size: 19,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.2,
        height: 1.35,
      ),

      // ── Title ────────────────────────────────────────────────
      titleLarge: _style(
        size: 17,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      titleMedium: _style(
        size: 15,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.0,
        height: 1.45,
      ),
      titleSmall: _style(
        size: 14,
        weight: FontWeight.w600,
        color: secondary,
        letterSpacing: 0.0,
        height: 1.45,
      ),

      // ── Body ─────────────────────────────────────────────────
      bodyLarge: _style(
        size: 15,
        weight: FontWeight.w400,
        color: primary,
        letterSpacing: 0.0,
        height: 1.5,
      ),
      bodyMedium: _style(
        size: 14,
        weight: FontWeight.w400,
        color: secondary,
        letterSpacing: 0.0,
        height: 1.5,
      ),
      bodySmall: _style(
        size: 12,
        weight: FontWeight.w400,
        color: tertiary,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // ── Label ────────────────────────────────────────────────
      labelLarge: _style(
        size: 14,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: _style(
        size: 12,
        weight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.2,
        height: 1.35,
      ),
      labelSmall: _style(
        size: 11,
        weight: FontWeight.w600,
        color: tertiary,
        letterSpacing: 0.3,
        height: 1.35,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Style Factory (GoogleFonts.inter with fallback)
  // ─────────────────────────────────────────────────────────────

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required Color color,
    double letterSpacing = 0.0,
    double height = 1.0,
  }) {
    try {
      return GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: TextDecoration.none,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: TextDecoration.none,
      );
    }
  }

  /// Specialized financial metric style (large, crisp, tabular)
  static TextStyle financialNumber({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w700,
  }) {
    return _style(
      size: size,
      weight: weight,
      color: color,
      letterSpacing: -0.5,
      height: 1.1,
    );
  }
}
