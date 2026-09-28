import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_typography.dart';

/// Pennora centralized theme configuration.
///
/// Designed to match the modern Pennora visual language:
/// Deep Navy, Royal Blue, Violet, Soft Pink, Lavender, and Mint.
abstract final class AppTheme {
  // ─────────────────────────────────────────────────────────────
  // Color Schemes
  // ─────────────────────────────────────────────────────────────

  static ColorScheme get _lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        // Primary
        primary: AppColors.royalBlue,
        onPrimary: Colors.white,
        primaryContainer: AppColors.lavender,
        onPrimaryContainer: AppColors.deepNavy,
        // Secondary
        secondary: AppColors.purple,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.lavender,
        onSecondaryContainer: AppColors.deepNavy,
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
        shadow: Color(0x0D0F172A),
        scrim: Colors.black54,
        inverseSurface: AppColors.deepNavy,
        onInverseSurface: AppColors.textPrimaryDark,
        inversePrimary: AppColors.purpleLight,
      );

  static ColorScheme get _darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        // Primary
        primary: AppColors.purpleLight,
        onPrimary: AppColors.deepNavy,
        primaryContainer: AppColors.deepNavyLighter,
        onPrimaryContainer: AppColors.purpleLight,
        // Secondary
        secondary: AppColors.mint,
        onSecondary: AppColors.deepNavy,
        secondaryContainer: AppColors.deepNavyLighter,
        onSecondaryContainer: AppColors.mint,
        // Tertiary
        tertiary: AppColors.electricCyan,
        onTertiary: AppColors.deepNavy,
        tertiaryContainer: AppColors.deepNavyDarker,
        onTertiaryContainer: AppColors.electricCyan,
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
        outline: AppColors.navyBorder,
        outlineVariant: AppColors.deepNavyLighter,
        // Misc
        shadow: Colors.black,
        scrim: Colors.black87,
        inverseSurface: AppColors.lightSurface,
        onInverseSurface: AppColors.textPrimaryLight,
        inversePrimary: AppColors.royalBlue,
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
            isLight ? AppColors.lightScaffold : AppColors.deepNavy,
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
            ? const Color(0x0C0F172A)
            : Colors.black.withAlpha(80),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isLight
                ? const Color(0xFFF1F5F9)
                : AppColors.navyBorder.withAlpha(120),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ───────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isLight
              ? const Color(0xFFE2E8F0)
              : AppColors.navyBorder,
          disabledForegroundColor: isLight
              ? AppColors.textTertiaryLight
              : AppColors.textTertiaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Filled Button ────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.royalBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.royalBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isLight ? AppColors.royalBlue : AppColors.purpleLight,
          side: BorderSide(
            color: isLight ? AppColors.royalBlue : AppColors.purpleLight,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ─────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? const Color(0xFFF8FAFC)
            : AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isLight ? const Color(0xFFE2E8F0) : AppColors.navyBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isLight ? const Color(0xFFE2E8F0) : AppColors.navyBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.royalBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: isLight
            ? AppTypography.lightTextTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiaryLight,
              )
            : AppTypography.darkTextTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
        labelStyle: isLight
            ? AppTypography.lightTextTheme.bodyMedium
            : AppTypography.darkTextTheme.bodyMedium,
      ),

      // ── Chip ─────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isLight
            ? const Color(0xFFF1F5F9)
            : AppColors.darkSurfaceVariant,
        selectedColor: isLight ? AppColors.lavender : AppColors.deepNavyLighter,
        labelStyle: textTheme.labelMedium,
        side: BorderSide(
          color: isLight ? const Color(0xFFE2E8F0) : AppColors.navyBorder,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space6,
        ),
      ),

      // ── Divider ──────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isLight ? const Color(0xFFF1F5F9) : AppColors.navyBorder,
        thickness: 1,
        space: 1,
      ),

      // ── Navigation Bar ───────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isLight ? AppColors.lightSurface : AppColors.darkSurface,
        indicatorColor: isLight ? AppColors.lavender : AppColors.deepNavyLighter,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
                color: isLight ? AppColors.royalBlue : AppColors.purpleLight);
          }
          return IconThemeData(
            color: isLight
                ? AppColors.textSecondaryLight
                : AppColors.textSecondaryDark,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base =
              isLight ? AppTypography.lightTextTheme : AppTypography.darkTextTheme;
          if (states.contains(WidgetState.selected)) {
            return base.labelSmall?.copyWith(
                color: isLight ? AppColors.royalBlue : AppColors.purpleLight,
                fontWeight: FontWeight.w700);
          }
          return base.labelSmall;
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isLight ? AppColors.lightSurface : AppColors.darkSurface,
        selectedItemColor: isLight ? AppColors.royalBlue : AppColors.purpleLight,
        unselectedItemColor: isLight
            ? AppColors.textTertiaryLight
            : AppColors.textSecondaryDark,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Floating Action Button ────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:
            isLight ? AppColors.lightSurface : AppColors.darkSurface,
        elevation: 16,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isLight ? const Color(0xFFF1F5F9) : AppColors.navyBorder,
          ),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ── Bottom Sheet ─────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isLight ? AppColors.lightSurface : AppColors.darkSurface,
        elevation: 16,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
      ),
    );
  }
}
