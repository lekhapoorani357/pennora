import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

/// Redesigned professional fintech Welcome Page for Pennora.
///
/// Layout:
/// - Compact top bar with logo + "Sign In" action
/// - Two-column hero (desktop) / stacked (tablet/mobile)
/// - Trust / value strip: Understand · Plan · Grow
/// - Product statement section
/// - Minimal footer
///
/// Preserves existing navigation (→ SignUpPage, → LoginPage),
/// all AppColors tokens, and dark mode via Theme.of(context).
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: AppDimensions.durationVerySlow,
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= AppDimensions.breakpointTablet;
    final isTablet = size.width >= AppDimensions.breakpointMobile &&
        size.width < AppDimensions.breakpointTablet;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top Bar ──────────────────────────────────────────
                  _TopBar(
                    isDark: isDark,
                    onSignIn: _navigateToLogin,
                  ),

                  // ── Hero Section ─────────────────────────────────────
                  _HeroSection(
                    isDesktop: isDesktop,
                    isTablet: isTablet,
                    isDark: isDark,
                    onGetStarted: _navigateToSignUp,
                    onSignIn: _navigateToLogin,
                  ),

                  // ── Value Strip ──────────────────────────────────────
                  _ValueStrip(isDark: isDark),

                  // ── Product Statement ────────────────────────────────
                  _ProductStatement(isDark: isDark),

                  // ── Footer ───────────────────────────────────────────
                  _Footer(isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onSignIn;

  const _TopBar({required this.isDark, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space24,
        vertical: AppDimensions.space16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          _PennoraLogo(isDark: isDark),
          const Spacer(),
          // Sign In
          _SignInButton(isDark: isDark, onTap: onSignIn),
        ],
      ),
    );
  }
}

class _PennoraLogo extends StatelessWidget {
  final bool isDark;
  const _PennoraLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.supporting,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.lavenderBorder),
          ),
          padding: const EdgeInsets.all(7),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _dot(AppColors.primary),
              _dot(AppColors.accent),
              _dot(AppColors.secondary),
              _dot(AppColors.primary),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.space10),
        Text(
          'Pennora',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _SignInButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _SignInButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: const BorderSide(color: AppColors.lavenderBorder),
        ),
        backgroundColor: AppColors.supporting,
      ),
      child: const Text(
        'Sign In',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final bool isDark;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _HeroSection({
    required this.isDesktop,
    required this.isTablet,
    required this.isDark,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPad = isDesktop ? 80.0 : AppDimensions.space24;
    final verticalPad = isDesktop ? 80.0 : AppDimensions.space40;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
      child: isDesktop
          ? _DesktopHero(
              isDark: isDark,
              onGetStarted: onGetStarted,
              onSignIn: onSignIn,
            )
          : _MobileHero(
              isDark: isDark,
              onGetStarted: onGetStarted,
              onSignIn: onSignIn,
            ),
    );
  }
}

class _DesktopHero extends StatelessWidget {
  final bool isDark;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _DesktopHero({
    required this.isDark,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: _HeroCopy(
            isDark: isDark,
            onGetStarted: onGetStarted,
            onSignIn: onSignIn,
          ),
        ),
        const SizedBox(width: AppDimensions.space64),
        Expanded(
          flex: 5,
          child: _HeroVisual(isDark: isDark),
        ),
      ],
    );
  }
}

class _MobileHero extends StatelessWidget {
  final bool isDark;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _MobileHero({
    required this.isDark,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCopy(
          isDark: isDark,
          onGetStarted: onGetStarted,
          onSignIn: onSignIn,
        ),
        const SizedBox(height: AppDimensions.space32),
        _HeroVisual(isDark: isDark),
      ],
    );
  }
}

// ── Left: Copy ────────────────────────────────────────────────────────────────

class _HeroCopy extends StatelessWidget {
  final bool isDark;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _HeroCopy({
    required this.isDark,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space12,
            vertical: AppDimensions.space4,
          ),
          decoration: BoxDecoration(
            color: AppColors.supporting,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(color: AppColors.lavenderBorder),
          ),
          child: const Text(
            'PERSONAL FINANCIAL INTELLIGENCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.space20),

        // Headline
        Text(
          'Make every financial\ndecision with clarity.',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -1.0,
            color: textPrimary,
          ),
        ),

        const SizedBox(height: AppDimensions.space16),

        // Supporting text
        Text(
          'Understand your money, track your goals, and make smarter financial decisions — all from one place.',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
        ),

        const SizedBox(height: AppDimensions.space32),

        // CTA buttons
        Row(
          children: [
            // Primary
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space24,
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(width: AppDimensions.space8),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(width: AppDimensions.space12),

            // Secondary
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onSignIn,
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space24,
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Right: Financial Visual ───────────────────────────────────────────────────

class _HeroVisual extends StatelessWidget {
  final bool isDark;
  const _HeroVisual({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightBackground;

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card 1: Net Worth summary ─────────────────────────
          _VisualCard(
            surface: surface,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconChip(
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                      bg: AppColors.supporting,
                    ),
                    const SizedBox(width: AppDimensions.space10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Overview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            'September 2026',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '+4.2%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),
                // Stat row
                Row(
                  children: [
                    _StatChip(
                      label: 'Monthly Income',
                      value: '₹65,000',
                      isDark: isDark,
                      accent: AppColors.success,
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    _StatChip(
                      label: 'Monthly Spend',
                      value: '₹38,200',
                      isDark: isDark,
                      accent: AppColors.warning,
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    _StatChip(
                      label: 'Surplus',
                      value: '₹26,800',
                      isDark: isDark,
                      accent: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),
                // Mini chart bars
                _MiniBarChart(isDark: isDark),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space12),

          // ── Card 2 + Card 3 side by side ─────────────────────
          Row(
            children: [
              Expanded(
                child: _VisualCard(
                  surface: surface,
                  border: border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconChip(
                        icon: Icons.flag_outlined,
                        color: AppColors.secondary,
                        bg: AppColors.lightLavender,
                      ),
                      const SizedBox(height: AppDimensions.space10),
                      Text(
                        'Emergency Fund',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹1,20,000 / ₹2,00,000',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      _GoalProgressBar(
                        value: 0.60,
                        color: AppColors.secondary,
                        bg: bg,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '60% complete',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: _VisualCard(
                  surface: surface,
                  border: border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconChip(
                        icon: Icons.trending_up_rounded,
                        color: AppColors.mint,
                        bg: AppColors.mintLight,
                      ),
                      const SizedBox(height: AppDimensions.space10),
                      Text(
                        'Vacation Goal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹45,000 / ₹75,000',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      _GoalProgressBar(
                        value: 0.60,
                        color: AppColors.mint,
                        bg: bg,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'On track',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.space12),

          // ── Card 3: AI Pipeline ───────────────────────────────
          _VisualCard(
            surface: surface,
            border: border,
            child: Row(
              children: [
                _IconChip(
                  icon: Icons.insights_rounded,
                  color: AppColors.primary,
                  bg: AppColors.supporting,
                ),
                const SizedBox(width: AppDimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pennora Intelligence',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          'Income',
                          'Transactions',
                          'Goals',
                          'Scenarios',
                        ]
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: border),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED VISUAL COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _VisualCard extends StatelessWidget {
  final Widget child;
  final Color surface;
  final Color border;

  const _VisualCard({
    required this.child,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;

  const _IconChip({
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color accent;

  const _StatChip({
    required this.label,
    required this.value,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GoalProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color bg;

  const _GoalProgressBar({
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => Container(
        height: 5,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final bool isDark;
  const _MiniBarChart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const heights = [0.45, 0.65, 0.50, 0.78, 0.60, 0.82, 0.70];
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightBackground;

    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(heights.length, (i) {
          final isLast = i == heights.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < heights.length - 1 ? 3 : 0),
              child: Container(
                height: 40 * heights[i],
                decoration: BoxDecoration(
                  color: isLast ? AppColors.primary : bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                  border: isLast
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 1,
                        ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VALUE STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _ValueStrip extends StatelessWidget {
  final bool isDark;
  const _ValueStrip({required this.isDark});

  static const _items = [
    (
      icon: Icons.bar_chart_outlined,
      title: 'Understand',
      desc: 'Understand your current\nfinancial state.',
    ),
    (
      icon: Icons.route_outlined,
      title: 'Plan',
      desc: 'Connect your money\nwith your goals.',
    ),
    (
      icon: Icons.show_chart_rounded,
      title: 'Grow',
      desc: 'Explore scenarios for\nyour financial future.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final topBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= AppDimensions.breakpointTablet;
    final hPad = isDesktop ? 80.0 : AppDimensions.space24;

    return Container(
      decoration: BoxDecoration(
        color: topBg,
        border: Border(
          top: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: AppDimensions.space32,
      ),
      child: isDesktop
          ? Row(
              children: _items
                  .map(
                    (item) => Expanded(
                      child: _ValueItem(
                        icon: item.icon,
                        title: item.title,
                        desc: item.desc,
                        isDark: isDark,
                      ),
                    ),
                  )
                  .toList(),
            )
          : Column(
              children: _items
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: EdgeInsets.only(
                          bottom: e.key < _items.length - 1
                              ? AppDimensions.space20
                              : 0),
                      child: _ValueItem(
                        icon: e.value.icon,
                        title: e.value.title,
                        desc: e.value.desc,
                        isDark: isDark,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ValueItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool isDark;

  const _ValueItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.supporting,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.lavenderBorder),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppDimensions.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT STATEMENT
// ─────────────────────────────────────────────────────────────────────────────

class _ProductStatement extends StatelessWidget {
  final bool isDark;
  const _ProductStatement({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= AppDimensions.breakpointTablet;
    final hPad = isDesktop ? 80.0 : AppDimensions.space24;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: AppDimensions.space48,
      ),
      child: Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Your financial life changes every day.\nPennora helps you understand what those changes mean for your goals.',
              textAlign: isDesktop ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontSize: isDesktop ? 22 : 18,
                fontWeight: FontWeight.w600,
                height: 1.5,
                letterSpacing: -0.3,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool isDark;
  const _Footer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= AppDimensions.breakpointTablet;
    final hPad = isDesktop ? 80.0 : AppDimensions.space24;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: AppDimensions.space20,
      ),
      child: Row(
        children: [
          Text(
            'Pennora',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          _FooterLink(label: 'Privacy', color: textColor),
          const SizedBox(width: AppDimensions.space20),
          _FooterLink(label: 'Terms', color: textColor),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final Color color;
  const _FooterLink({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}
