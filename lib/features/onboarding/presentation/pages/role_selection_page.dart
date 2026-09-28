import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../services/financial_profile_service.dart';
import '../../../auth/services/auth_service.dart';
import 'role_questionnaire_page.dart';

/// Premium role selection screen shown AFTER login and BEFORE the main dashboard.
class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  bool _isNavigating = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_selectedRole == null || _isNavigating) return;
    setState(() => _isNavigating = true);

    final userId = AuthService.instance.currentUser?.id ?? '';
    await FinancialProfileService.instance.saveRole(userId, _selectedRole!);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RoleQuestionnairePage(role: _selectedRole!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
              vertical: AppDimensions.space24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Pennora Brand Header ─────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.gradientAccent,
                            ),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: const Icon(Icons.hub_rounded,
                              size: 20, color: AppColors.deepNavy),
                        ),
                        const SizedBox(width: AppDimensions.space10),
                        Text(
                          'Pennora',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space32),

                    // ── Headline ─────────────────────────────────────────
                    Text(
                      'Tell us about\nyour financial life',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.2,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space10),
                    Text(
                      'GoalSync will personalize your financial plan based on your situation.',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space28),

                    // ── Role Cards ───────────────────────────────────────
                    _RoleCard(
                      role: 'student',
                      emoji: '🎓',
                      title: 'Student',
                      subtitle: 'Managing pocket money, scholarships,\ninternships & student goals',
                      gradientColors: const [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                      accentColor: const Color(0xFF38BDF8),
                      isSelected: _selectedRole == 'student',
                      onTap: () => setState(() => _selectedRole = 'student'),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    _RoleCard(
                      role: 'working_single',
                      emoji: '💼',
                      title: 'Working Professional',
                      subtitle: 'Salary, savings, investments\n& personal career goals',
                      gradientColors: const [Color(0xFF0F2027), Color(0xFF1A3344)],
                      accentColor: AppColors.electricCyan,
                      isSelected: _selectedRole == 'working_single',
                      onTap: () =>
                          setState(() => _selectedRole = 'working_single'),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    _RoleCard(
                      role: 'working_married',
                      emoji: '👨‍👩‍👧',
                      title: 'Married / Family',
                      subtitle: 'Household income, family expenses,\nloans & long-term family goals',
                      gradientColors: const [Color(0xFF0D1B2A), Color(0xFF1F3329)],
                      accentColor: AppColors.mint,
                      isSelected: _selectedRole == 'working_married',
                      onTap: () =>
                          setState(() => _selectedRole = 'working_married'),
                    ),
                    const SizedBox(height: AppDimensions.space32),

                    // ── Continue Button ──────────────────────────────────
                    AnimatedOpacity(
                      opacity: _selectedRole != null ? 1.0 : 0.45,
                      duration: const Duration(milliseconds: 250),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientAccent,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusLg),
                          boxShadow: _selectedRole != null
                              ? [
                                  BoxShadow(
                                    color: AppColors.electricCyan.withAlpha(90),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: ElevatedButton(
                          onPressed: _selectedRole != null && !_isNavigating
                              ? _onContinue
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusLg),
                            ),
                          ),
                          child: _isNavigating
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.deepNavy),
                                  ),
                                )
                              : const Text(
                                  'Continue →',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepNavy,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space20),
                    Text(
                      'Your answers are used only to personalize your financial plan and are never shared.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
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

class _RoleCard extends StatelessWidget {
  final String role;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isSelected ? accentColor : accentColor.withAlpha(50),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withAlpha(70),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withAlpha(80)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : const Color(0xFF475569),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: AppColors.deepNavy)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
