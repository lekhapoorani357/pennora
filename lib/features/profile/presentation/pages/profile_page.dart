import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/services/auth_service.dart';
import '../../../ai_copilot/services/ai_insights_service.dart';
import '../../../onboarding/presentation/pages/role_selection_page.dart';
import '../../../onboarding/services/financial_profile_service.dart';
import '../../../investment/presentation/pages/money_growth_page.dart';
import '../../../monetization/presentation/pages/premium_page.dart';
import '../../../monetization/services/subscription_service.dart';

/// Profile Page showing verified account details, preferences, and session termination.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
    AuthService.instance.syncUserFromBackend();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of Pennora on this device?',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      await AuthService.instance.logout();
      AiInsightsService.instance.clear();
      if (!context.mounted) return;
      // Navigate to Login Page and clear all routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = AuthService.instance.currentUser;

    final userName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Pennora Member';
    final userEmail = user?.email.isNotEmpty == true ? user!.email : 'Not provided';
    final userPhone = user != null ? user.fullPhoneNumber : 'Not provided';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.space16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Profile Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF071A52),
                          Color(0xFF0D256D),
                          Color(0xFF1E1B4B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF071A52).withAlpha(100),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppDimensions.space24),
                    child: Column(
                      children: [
                        // Avatar Initials with outer gradient ring
                        Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF38BDF8),
                                Color(0xFF818CF8),
                                Color(0xFFC084FC),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF818CF8).withAlpha(100),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF0B1F5E),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(userName),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),

                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified_rounded, size: 13, color: Color(0xFF38BDF8)),
                              SizedBox(width: 5),
                              Text(
                                'Personal Account',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Account Information Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'ACCOUNT INFORMATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space10),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.navyBorder : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 8),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Full Name',
                          value: userName,
                          isDark: isDark,
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? AppColors.navyBorder : const Color(0xFFF1F5F9),
                        ),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFF10B981),
                          title: 'Phone Number',
                          value: userPhone,
                          isDark: isDark,
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? AppColors.navyBorder : const Color(0xFFF1F5F9),
                        ),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Email Address',
                          value: userEmail,
                          isDark: isDark,
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? AppColors.navyBorder : const Color(0xFFF1F5F9),
                        ),
                        _buildInfoTile(
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFF06B6D4),
                          title: 'Session Status',
                          value: 'Active (Secured)',
                          isDark: isDark,
                          trailingColor: AppColors.mint,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Financial Role Card
                  Builder(builder: (ctx) {
                    final uid = user?.id ?? '';
                    final role = FinancialProfileService.instance.getRole(uid);
                    return Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.navyBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              role == 'student'
                                  ? Icons.school_rounded
                                  : (role == 'working_married'
                                      ? Icons.family_restroom_rounded
                                      : Icons.work_rounded),
                              size: 20,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Financial Profile Role',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _roleLabel(role),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RoleSelectionPage(),
                              ),
                            ),
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: AppDimensions.space16),

                  // Pro Subscription Card
                  AnimatedBuilder(
                    animation: SubscriptionService.instance,
                    builder: (ctx, _) {
                      final isPro = SubscriptionService.instance.isPremium;
                      return Container(
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPro
                                ? [const Color(0xFF0F2B1D), const Color(0xFF0B1E14)]
                                : [const Color(0xFF1B2A4A), const Color(0xFF101B30)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPro ? AppColors.mint : AppColors.warning,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPro
                                  ? Icons.workspace_premium_rounded
                                  : Icons.star_border_rounded,
                              size: 28,
                              color: isPro ? AppColors.mint : AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPro ? 'Pennora Pro Active 🌟' : 'Pennora Free Plan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isPro ? AppColors.mint : AppColors.warning,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPro
                                        ? 'Unlimited goals & full simulator access'
                                        : 'Upgrade for ₹99/mo to unlock all tools',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withAlpha(200),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PremiumPage(),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPro ? AppColors.mint : AppColors.warning,
                                foregroundColor: AppColors.deepNavy,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Text(isPro ? 'Manage' : 'Upgrade'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppDimensions.space16),

                  // Growth & Admin Navigation Tiles
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.navyBorder : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: ListTile(
                            leading: const Icon(Icons.trending_up_rounded,
                                color: Color(0xFF3B82F6)),
                            title: const Text(
                              'Money Growth & Simulator',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Interactive SIP, FD, PPF & What-If Scenarios',
                              style: TextStyle(fontSize: 11),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MoneyGrowthPage(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // Preferences & System
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'PREFERENCES & SYSTEM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space10),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.navyBorder : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 8),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.currency_rupee_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Default Currency',
                          value: 'INR (₹)',
                          isDark: isDark,
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? AppColors.navyBorder : const Color(0xFFF1F5F9),
                        ),
                        _buildInfoTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFF64748B),
                          title: 'Application Version',
                          value: 'Pennora v1.0.0 (AI Edition)',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withAlpha(90),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: isDark
                          ? AppColors.error.withAlpha(15)
                          : AppColors.error.withAlpha(10),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
    Color? trailingColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(isDark ? 35 : 20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: AppDimensions.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: trailingColor ??
                        (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      final str = parts[0];
      return str.length >= 2 ? str.substring(0, 2).toUpperCase() : str.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'student':
        return 'College Student';
      case 'working_married':
        return 'Working Married / Family';
      default:
        return 'Working Professional';
    }
  }
}
