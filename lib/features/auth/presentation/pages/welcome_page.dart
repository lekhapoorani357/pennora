import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

/// Clean, professional Welcome Page matching Screen 1 of the Design Reference.
///
/// Features:
/// - Crisp white background with subtle modern SaaS layout
/// - Geometric 4-dot Pennora brand mark
/// - Bold typography: "Your Money, Organized in One Place"
/// - Informative subtitle
/// - Clean financial preview card illustration
/// - Deep Indigo pill button: "Get Started →"
/// - Professional secondary link: "Already have an account? Log In"
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 460 : double.infinity),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimensions.space20),

                    // ── Top Brand Emblem (Geometric 4-dot grid) + "Pennora" ───────────
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.supporting,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.lavenderBorder),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 3,
                            mainAxisSpacing: 3,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Pennora',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.space20),

                    // ── Title & Subtitle ──────────────────────────────────
                    const Text(
                      'Your money changes.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const Text(
                      'Your goals should adapt.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space10),

                    const Text(
                      'Track your goals, plan your savings, and see your financial progress — all in one modern, intelligent dashboard.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space20),

                    // ── Minimal Financial Mockup Card ───────────────────────
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.lightBorder),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withAlpha(8),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.supporting,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.insights_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pennora Intelligence',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimaryLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Adaptive Surplus Engine',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondaryLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Financial Intelligence Pipeline Badges (tested in widget_test)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                'Income',
                                'Transactions',
                                'Financial State',
                                'Goals',
                                'Conflicts',
                                'Scenarios',
                              ].map((step) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.lightBorder),
                                  ),
                                  child: Text(
                                    step,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space24),

                    // ── Primary Action Button ("Get Started") ─────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space10),

                    // ── Secondary Log In Link ("I already have an account") ───
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondaryLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'I already have an account',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
