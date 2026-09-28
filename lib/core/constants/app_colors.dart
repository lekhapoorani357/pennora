import 'package:flutter/material.dart';

/// Pennora centralized color palette.
///
/// Brand identity: "Smart money + personal growth + modern lifestyle + AI"
/// Visual Direction: Deep Navy, Royal Blue, Violet, Purple, Pink, Lavender, Mint.
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────
  // Brand Core Colors (From Reference UI)
  // ─────────────────────────────────────────────────────────────

  /// Deep Navy – background for hero cards, profile, AI copilot
  static const Color deepNavy = Color(0xFF071A52);
  static const Color deepNavyDarker = Color(0xFF051238);
  static const Color deepNavyLighter = Color(0xFF0B1F5E);

  /// Royal Blue
  static const Color royalBlue = Color(0xFF2563EB);

  /// Violet & Purple
  static const Color violet = Color(0xFF7C3AED);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color lavender = Color(0xFFEEF2FF);
  static const Color lavenderBorder = Color(0xFFE0E7FF);

  /// Pink & Coral
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkLight = Color(0xFFFCE7F3);
  static const Color pinkAccent = Color(0xFFF472B6);

  /// Mint & Teal & Cyan
  static const Color mint = Color(0xFF14B8A6);
  static const Color mintLight = Color(0xFFCCFBF1);
  static const Color mintDark = Color(0xFF0D9488);
  static const Color electricCyan = Color(0xFF00D9FF);
  static const Color cyanGlow = Color(0x3300D9FF);
  static const Color cyanDark = Color(0xFF0891B2);

  // ─────────────────────────────────────────────────────────────
  // Brand Variants & Translucencies
  // ─────────────────────────────────────────────────────────────

  static const Color navyLight = Color(0xFF0D2640);
  static const Color navyMid = Color(0xFF102E4A);
  static const Color navyBorder = Color(0xFF1E3A8A);
  static const Color mintGlow = Color(0x3314B8A6);
  static const Color purpleGlow = Color(0x338B5CF6);

  // ─────────────────────────────────────────────────────────────
  // Light Theme Surfaces
  // ─────────────────────────────────────────────────────────────

  /// Clean soft background (from reference)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightScaffold = Color(0xFFF8FAFC);

  /// Clean white card surfaces
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightSurface2 = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // ─────────────────────────────────────────────────────────────
  // Dark Theme Surfaces
  // ─────────────────────────────────────────────────────────────

  static const Color darkBackground = Color(0xFF071A52);
  static const Color darkScaffold = Color(0xFF051238);
  static const Color darkSurface = Color(0xFF0B1F5E);
  static const Color darkSurfaceVariant = Color(0xFF132A75);
  static const Color darkSurface2 = Color(0xFF0E2366);

  // ─────────────────────────────────────────────────────────────
  // Text Colors
  // ─────────────────────────────────────────────────────────────

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // ─────────────────────────────────────────────────────────────
  // Semantic Colors
  // ─────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);

  // ─────────────────────────────────────────────────────────────
  // Gradients (from Reference Design)
  // ─────────────────────────────────────────────────────────────

  /// Deep navy card gradient (Total balance card & profile header)
  static const List<Color> gradientNavy = [
    Color(0xFF0B1F5E),
    Color(0xFF071A52),
  ];

  /// Deep navy gradient with vibrant accent
  static const List<Color> gradientNavyGlow = [
    Color(0xFF0F2B82),
    Color(0xFF071A52),
  ];

  /// Royal Blue → Violet gradient
  static const List<Color> gradientRoyalViolet = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
  ];

  /// Primary button CTA gradient (Purple → Blue)
  static const List<Color> gradientButton = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  /// Welcome page sunset dusk sky gradient
  static const List<Color> gradientWelcomeSky = [
    Color(0xFF0A1128),
    Color(0xFF1E2963),
    Color(0xFF4C3075),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFFFDBA74),
  ];

  /// Add Transaction header wavy gradient
  static const List<Color> gradientAddTransactionHeader = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
    Color(0xFFFED7AA),
  ];

  /// Soft peach motivational card gradient: "Better habits, Build bigger dreams"
  static const List<Color> gradientPeachBanner = [
    Color(0xFFFFF1EB),
    Color(0xFFFFE4DC),
  ];

  /// Soft sky motivational card gradient: "Dream Bigger, Plan Smarter, Achieve More"
  static const List<Color> gradientSkyBanner = [
    Color(0xFFE0F2FE),
    Color(0xFFEDE9FE),
  ];

  /// Soft mint motivational card gradient: "Good finance builds freedom"
  static const List<Color> gradientMintBanner = [
    Color(0xFFE6FFFA),
    Color(0xFFE0F2FE),
  ];

  /// Purple motivational quote card (Profile screen)
  static const List<Color> gradientPurpleQuote = [
    Color(0xFF4C1D95),
    Color(0xFF6D28D9),
  ];

  /// Accent gradient (Electric Cyan → Mint)
  static const List<Color> gradientAccent = [
    Color(0xFF00D9FF),
    Color(0xFF14B8A6),
  ];

  /// Light theme card subtle gradient
  static const List<Color> gradientCardLight = [
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
  ];

  /// Dark theme card subtle gradient
  static const List<Color> gradientCardDark = [
    Color(0xFF0B1F5E),
    Color(0xFF071A52),
  ];
}
