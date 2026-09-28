import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_typography.dart';

/// Pennora centralized theme configuration.
///
/// Clean, professional modern finance/SaaS visual system:
/// Deep Indigo (#4F46E5), Violet (#6366F1), Soft Lavender (#8B8CF6),
/// Light Lavender (#EEF2FF), Crisp White surfaces, and Slate borders (#E2E8F0).
abstract final class AppTheme {
  // ─────────────────────────────────────────────────────────────
  // Color Schemes
  // ─────────────────────────────────────────────────────────────

  static ColorScheme get _lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        // Primary
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.supporting,
        onPrimaryContainer: AppColors.primary,
        // Secondary
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.supporting,
        onSecondaryContainer: AppColors.primary,
        // Tertiary
        tertiary: AppColors.mint,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.mintLight,
        onTertiaryContainer: AppColors.mintDark,
        // Error
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorLight,
        onErrorContainer: Color(0xFF991B1B),
        // Surface & Background
        surface: AppColors.lightSurface,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        onSurfaceVariant: AppColors.textSecondaryLight,
        // Outline
        outline: AppColors.lightBorder,
        outlineVariant: Color(0xFFF1F5F9),
        // Misc
        shadow: Color(0x080F172A),
        scrim: Colors.black54,
        inverseSurface: AppColors.darkSurface,
        onInverseSurface: AppColors.textPrimaryDark,
        inversePrimary: AppColors.accent,
      );

  static ColorScheme get _darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        // Primary
        primary: AppColors.accent,
        onPrimary: AppColors.darkBackground,
        primaryContainer: AppColors.darkSurfaceVariant,
        onPrimaryContainer: AppColors.accent,
        // Secondary
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.darkSurfaceVariant,
        onSecondaryContainer: Colors.white,
        // Tertiary
        tertiary: AppColors.mint,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.darkSurface,
        onTertiaryContainer: AppColors.mint,
        // Error
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: AppColors.errorLight,
        // Surface
        surface: AppColors.darkSurface,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.textSecondaryDark,
        // Outline
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkSurfaceVariant,
        // Misc
        shadow: Colors.black,
        scrim: Colors.black87,
        inverseSurface: AppColors.lightSurface,
        onInverseSurface: AppColors.textPrimaryLight,
        inversePrimary: AppColors.primary,
      );

  // ─────────────────────────────────────────────────────────────
  // Light Theme
  // ─────────────────────────────────────────────────────────────

  static ThemeData get lightTheme => _buildTheme(
        colorScheme: _lightColorScheme,
        scaffoldBackgroundColor: AppColors.lightScaffold,
        textTheme: AppTypography.lightTextTheme,
      );

  // ─────────────────────────────────────────────────────────────
  // Dark Theme
  // ─────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => _buildTheme(
        colorScheme: _darkColorScheme,
        scaffoldBackgroundColor: AppColors.darkScaffold,
        textTheme: AppTypography.darkTextTheme,
      );

  // ─────────────────────────────────────────────────────────────
  // Internal Theme Builder
  // ─────────────────────────────────────────────────────────────

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required TextTheme textTheme,
  }) {
    final bool isLight = colorScheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,

      // ── AppBar ───────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:
            isLight ? AppColors.lightScaffold : AppColors.darkBackground,
        foregroundColor:
            isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: isLight
            ? AppTypography.lightTextTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              )
            : AppTypography.darkTextTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Card ─────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        elevation: 0,
        shadowColor: isLight
            ? const Color(0x080F172A)
            : Colors.black.withAlpha(60),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight
                ? AppColors.lightBorder
                : AppColors.darkBorder,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ───────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isLight
              ? const Color(0xFFE2E8F0)
              : AppColors.darkBorder,
          disabledForegroundColor: isLight
              ? AppColors.textTertiaryLight
              : AppColors.textTertiaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── Filled Button ────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
          backgroundColor:
              isLight ? AppColors.lightSurface : AppColors.darkSurface,
          side: BorderSide(
            color: isLight ? AppColors.lightBorder : AppColors.darkBorder,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ─────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: isLight
              ? AppColors.textTertiaryLight
              : AppColors.textTertiaryDark,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isLight
              ? AppColors.textSecondaryLight
              : AppColors.textSecondaryDark,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isLight ? AppColors.lightBorder : AppColors.darkBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
      ),

      // ── Divider ──────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.lightBorder : AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ───────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:
            isLight ? AppColors.lightSurface : AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isLight ? AppColors.lightBorder : AppColors.darkBorder,
            width: 1,
          ),
        ),
      ),

      // ── Bottom Sheet ─────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isLight ? AppColors.lightSurface : AppColors.darkSurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
