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
                      color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 0 : 8),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppDimensions.space20),
                    child: Column(
                      children: [
                        // Avatar Initials
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lightLavender,
                            border: Border.all(
                              color: AppColors.primary.withAlpha(40),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(userName),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightLavender,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_outlined, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Verified Member',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Account Information Section
                  _sectionLabel('ACCOUNT & PROFILE', isDark),
                  const SizedBox(height: AppDimensions.space10),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSettingRow(
                          icon: Icons.person_outline,
                          title: 'Full Name',
                          value: userName,
                          isDark: isDark,
                        ),
                        _divider(isDark),
                        _buildSettingRow(
                          icon: Icons.phone_outlined,
                          title: 'Phone Number',
                          value: userPhone,
                          isDark: isDark,
                        ),
                        _divider(isDark),
                        _buildSettingRow(
                          icon: Icons.mail_outline,
                          title: 'Email Address',
                          value: userEmail,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Financial & Risk Profile Section
                  _sectionLabel('FINANCIAL & RISK PROFILE', isDark),
                  const SizedBox(height: AppDimensions.space10),

                  Builder(builder: (ctx) {
                    final uid = user?.id ?? '';
                    final role = FinancialProfileService.instance.getRole(uid);
                    final profile = FinancialProfileService.instance.getProfile(uid);
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildSettingRow(
                            icon: Icons.badge_outlined,
                            title: 'Financial Profile Role',
                            value: _roleLabel(role),
                            isDark: isDark,
                            trailing: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RoleSelectionPage(),
                                ),
                              ),
                              child: const Text('Change'),
                            ),
                          ),
                          _divider(isDark),
                          _buildSettingRow(
                            icon: Icons.assessment_outlined,
                            title: 'Risk Profile',
                            value: profile != null && profile.monthlySurplus > 20000
                                ? 'Moderate Growth (Balanced)'
                                : 'Conservative (Capital Preservation)',
                            isDark: isDark,
                          ),
                          _divider(isDark),
                          _buildSettingRow(
                            icon: Icons.trending_up_outlined,
                            title: 'Money Growth Strategy',
                            value: 'Interactive Simulator',
                            isDark: isDark,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MoneyGrowthPage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppDimensions.space20),

                  // Subscription Section
                  _sectionLabel('SUBSCRIPTION & ACCESS', isDark),
                  const SizedBox(height: AppDimensions.space10),

                  AnimatedBuilder(
                    animation: SubscriptionService.instance,
                    builder: (ctx, _) {
                      final isPro = SubscriptionService.instance.isPremium;
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                          ),
                        ),
                        child: _buildSettingRow(
                          icon: Icons.workspace_premium_outlined,
                          title: isPro ? 'Pennora Pro (Demo)' : 'Free Tier',
                          value: isPro ? 'Unlimited goals & full simulator' : 'Standard features',
                          isDark: isDark,
                          trailing: ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PremiumPage(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(isPro ? 'Manage' : 'Upgrade'),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Preferences, Notifications & Security
                  _sectionLabel('PREFERENCES & SECURITY', isDark),
                  const SizedBox(height: AppDimensions.space10),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSettingRow(
                          icon: Icons.notifications_none_outlined,
                          title: 'Notifications',
                          value: 'Drift alerts & milestones enabled',
                          isDark: isDark,
                        ),
                        _divider(isDark),
                        _buildSettingRow(
                          icon: Icons.currency_rupee_outlined,
                          title: 'Default Currency',
                          value: 'INR (₹)',
                          isDark: isDark,
                        ),
                        _divider(isDark),
                        _buildSettingRow(
                          icon: Icons.lock_outline,
                          title: 'Security & Encryption',
                          value: 'Protected with Supabase Auth',
                          isDark: isDark,
                        ),
                        _divider(isDark),
                        _buildSettingRow(
                          icon: Icons.info_outline,
                          title: 'App Version',
                          value: 'Pennora v1.0.0',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space28),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout_outlined, size: 18),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightLavender,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.primary,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.secondaryText,
              ),
          ],
        ),
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
