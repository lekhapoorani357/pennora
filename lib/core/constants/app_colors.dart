import 'package:flutter/material.dart';

/// Pennora centralized color palette.
///
/// Refreshed to match a modern, professional SaaS financial application:
/// - Primary: Deep Indigo / Royal Purple (#4F46E5)
/// - Secondary: Violet (#6366F1)
/// - Accent: Soft Lavender (#8B8CF6)
/// - Supporting: Light Lavender (#EEF2FF)
/// - Success: Professional Green (#16A34A)
/// - Warning: Amber (#D97706)
/// - Error: Professional Red (#DC2626)
/// - Clean white & neutral light surfaces with subtle borders (#E2E8F0)
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────
  // Core Brand Palette (Professional Fintech / SaaS)
  // ─────────────────────────────────────────────────────────────

  /// Deep Indigo / Royal Purple – Primary brand color (#4F46E5)
  static const Color primary = Color(0xFF4F46E5);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color royalBlue = Color(0xFF4F46E5);

  /// Secondary Violet (#6366F1)
  static const Color secondary = Color(0xFF6366F1);
  static const Color violet = Color(0xFF6366F1);
  static const Color purple = Color(0xFF6366F1);
  static const Color purpleLight = Color(0xFF8B8CF6);

  /// Accent Soft Lavender (#8B8CF6)
  static const Color accent = Color(0xFF8B8CF6);
  static const Color softLavender = Color(0xFF8B8CF6);

  /// Supporting Light Lavender & Tinted Surfaces (#EEF2FF)
  static const Color supporting = Color(0xFFEEF2FF);
  static const Color lavender = Color(0xFFEEF2FF);
  static const Color lavenderBorder = Color(0xFFE0E7FF);
  static const Color lightLavender = Color(0xFFEEF2FF);

  /// Deep Navy – used for dark hero cards and dark surfaces
  static const Color deepNavy = Color(0xFF1E1B4B); // Deep indigo-navy
  static const Color deepNavyDarker = Color(0xFF0F172A);
  static const Color deepNavyLighter = Color(0xFF312E81);
  static const Color navyLight = Color(0xFF312E81);
  static const Color navyMid = Color(0xFF1E1B4B);
  static const Color navyBorder = Color(0xFF334155);

  /// Controlled Accent Colors (restrained for icons / tags)
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkLight = Color(0xFFFDF2F8);
  static const Color pinkAccent = Color(0xFFF472B6);

  static const Color mint = Color(0xFF10B981);
  static const Color mintLight = Color(0xFFECFDF5);
  static const Color mintDark = Color(0xFF047857);

  static const Color electricCyan = Color(0xFF4F46E5); // Mapped to primary indigo
  static const Color cyanGlow = Color(0x1A4F46E5);
  static const Color cyanDark = Color(0xFF4338CA);
  static const Color mintGlow = Color(0x1A10B981);
  static const Color purpleGlow = Color(0x1A6366F1);

  // ─────────────────────────────────────────────────────────────
  // Light Theme Surfaces (Clean White & Slate)
  // ─────────────────────────────────────────────────────────────

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightScaffold = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightSurface2 = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);

  /// Card & Border Aliases
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color primaryText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF64748B);

  // ─────────────────────────────────────────────────────────────
  // Dark Theme Surfaces (Sleek Slate)
  // ─────────────────────────────────────────────────────────────

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkScaffold = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkSurface2 = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // ─────────────────────────────────────────────────────────────
  // Typography Hierarchy
  // ─────────────────────────────────────────────────────────────

  static const Color textPrimaryLight = Color(0xFF111827); // Very dark slate
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate gray
  static const Color textTertiaryLight = Color(0xFF94A3B8); // Light slate

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // ─────────────────────────────────────────────────────────────
  // Status & Financial Indicators
  // ─────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF16A34A); // Professional green
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626); // Professional red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF4F46E5);

  // ─────────────────────────────────────────────────────────────
  // Subtle & Professional Gradients
  // ─────────────────────────────────────────────────────────────

  /// Deep Indigo card gradient (for select hero banners)
  static const List<Color> gradientNavy = [
    Color(0xFF1E1B4B),
    Color(0xFF312E81),
  ];

  static const List<Color> gradientNavyGlow = [
    Color(0xFF312E81),
    Color(0xFF1E1B4B),
  ];

  /// Royal Blue / Indigo -> Violet
  static const List<Color> gradientRoyalViolet = [
    Color(0xFF4F46E5),
    Color(0xFF6366F1),
  ];

  /// Primary CTA button gradient
  static const List<Color> gradientButton = [
    Color(0xFF4F46E5),
    Color(0xFF6366F1),
  ];

  /// Minimal clean header gradient
  static const List<Color> gradientWelcomeSky = [
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
  ];

  static const List<Color> gradientAddTransactionHeader = [
    Color(0xFF4F46E5),
    Color(0xFF6366F1),
  ];

  /// Subtle tint card backgrounds
  static const List<Color> gradientPeachBanner = [
    Color(0xFFFFFBEB),
    Color(0xFFFEF3C7),
  ];

  static const List<Color> gradientSkyBanner = [
    Color(0xFFEEF2FF),
    Color(0xFFE0E7FF),
  ];

  static const List<Color> gradientMintBanner = [
    Color(0xFFECFDF5),
    Color(0xFFD1FAE5),
  ];

  static const List<Color> gradientPurpleQuote = [
    Color(0xFF312E81),
    Color(0xFF4338CA),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFF4F46E5),
    Color(0xFF6366F1),
  ];

  static const List<Color> gradientCardLight = [
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
  ];

  static const List<Color> gradientCardDark = [
    Color(0xFF1E293B),
    Color(0xFF1E293B),
  ];
}
