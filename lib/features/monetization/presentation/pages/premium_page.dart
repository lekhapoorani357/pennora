import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../services/subscription_service.dart';
import 'family_household_page.dart';
import 'student_verification_page.dart';

/// Premium Upgrade Page showing Free vs Pro/Student/Family comparison and demo activation.
class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _isLoading = false;
  String _billingPeriod = 'monthly'; // 'monthly' | 'annual'
  String _selectedTier = 'premium'; // 'premium' | 'student' | 'family'

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.addListener(_onChanged);
    SubscriptionService.instance.fetchPlans();
    SubscriptionService.instance.fetchStatus();
    SubscriptionService.instance.fetchStudentStatus();
  }

  @override
  void dispose() {
    SubscriptionService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String get _currentPlanCode {
    return '${_selectedTier}_$_billingPeriod';
  }

  double get _currentPlanPrice {
    final plans = SubscriptionService.instance.availablePlans;
    final match = plans.where((p) => p.code == _currentPlanCode).firstOrNull;
    if (match != null) return match.price;

    // Fallbacks
    if (_selectedTier == 'student') {
      return _billingPeriod == 'annual' ? 490.0 : 49.0;
    } else if (_selectedTier == 'family') {
      return _billingPeriod == 'annual' ? 1990.0 : 199.0;
    }
    return _billingPeriod == 'annual' ? 990.0 : 99.0;
  }

  Future<void> _activate() async {
    setState(() => _isLoading = true);
    final ok = await SubscriptionService.instance.activateDemoPremium(planCode: _currentPlanCode);
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎉 Pennora ${_selectedTier.toUpperCase()} activated (DEMO)!'),
          backgroundColor: AppColors.mint,
        ));
      }
    }
  }

  Future<void> _activateTrial() async {
    setState(() => _isLoading = true);
    final ok = await SubscriptionService.instance.activateTrial(planCode: _currentPlanCode);
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 14-Day Free Trial activated!'),
          backgroundColor: AppColors.mint,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trial has already been activated once for this account.'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _cancel() async {
    setState(() => _isLoading = true);
    await SubscriptionService.instance.cancelSubscription();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = SubscriptionService.instance.isPremium;
    final activeTier = SubscriptionService.instance.tier;
    final inTrial = SubscriptionService.instance.inTrial;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Premium Plans',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH,
          vertical: AppDimensions.space16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Subtitle
                Text(
                  'Accelerate your financial freedom with goal intelligence and automated compounding.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Active Subscription Banner
                if (isPro) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withAlpha(100)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inTrial
                                    ? 'Active: ${SubscriptionService.instance.remainingTrialDays}-Day Trial (${activeTier.toUpperCase()})'
                                    : 'Active: Pennora ${activeTier.toUpperCase()} (DEMO)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                inTrial && activeTier == 'student'
                                    ? '${SubscriptionService.instance.remainingTrialDays} days remaining · Student subsidized plan'
                                    : 'All pro features unlocked. Ad-free browsing enabled.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              if (inTrial && activeTier == 'student') ...[  
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: (SubscriptionService.instance.remainingTrialDays /
                                            SubscriptionService.instance.studentTrialDays)
                                        .clamp(0.0, 1.0),
                                    backgroundColor: AppColors.success.withAlpha(30),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (activeTier.toLowerCase() == 'family')
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const FamilyHouseholdPage()),
                                  );
                                },
                                icon: const Icon(Icons.group_outlined, size: 14),
                                label: const Text('Manage Family', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            if (activeTier.toLowerCase() == 'student')
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const StudentVerificationPage()),
                                  );
                                },
                                icon: const Icon(Icons.school_outlined, size: 14),
                                label: const Text('Student Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            TextButton(
                              onPressed: _isLoading ? null : _cancel,
                              child: const Text('Cancel Plan', style: TextStyle(color: AppColors.error, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                ],

                // Billing Period Switcher (Monthly / Annual)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.navyBorder : AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _billingPeriod = 'monthly'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _billingPeriod == 'monthly'
                                  ? (isDark ? AppColors.darkSurfaceVariant : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _billingPeriod == 'monthly'
                                  ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Monthly Billing',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _billingPeriod == 'monthly' ? FontWeight.w700 : FontWeight.w500,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _billingPeriod = 'annual'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _billingPeriod == 'annual'
                                  ? (isDark ? AppColors.darkSurfaceVariant : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _billingPeriod == 'annual'
                                  ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Annual Billing',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _billingPeriod == 'annual' ? FontWeight.w700 : FontWeight.w500,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.mint.withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '2 Mo. Free',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Plan Tier Selection Cards
                Row(
                  children: [
                    _tierChoiceCard(
                      title: 'Individual Pro',
                      tier: 'premium',
                      subtitle: 'Full personal intelligence',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _tierChoiceCard(
                      title: 'Student Plan',
                      tier: 'student',
                      subtitle: 'Subsidized rate for learners',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _tierChoiceCard(
                      title: 'Family Plan',
                      tier: 'family',
                      subtitle: 'Up to 5 family members',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space20),

                // Selected Plan Pricing Box
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPro && activeTier == _selectedTier
                          ? AppColors.success
                          : (isDark ? AppColors.navyBorder : AppColors.cardBorder),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 0 : 8),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightLavender,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DEMO / PROJECTED PLAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            _selectedTier.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${_currentPlanPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            _billingPeriod == 'annual' ? ' / year' : ' / month',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedTier == 'family'
                            ? 'Complete intelligence for your entire household (up to 5 members with strict individual privacy).'
                            : _selectedTier == 'student'
                                ? 'Subsidized rate for students building disciplined early savings and career milestones.'
                                : 'Full access to advanced money simulator, multi-bank comparison, and verified AI copilot.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CTA Actions
                      if (_selectedTier == 'student')
                        _buildStudentInlineSection(isDark)
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _activateTrial,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Start 14-Day Trial', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _activate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Activate Demo Plan', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space24),

                // Feature Comparison Table
                _sectionLabel('PLAN COMPARISON', isDark),
                const SizedBox(height: AppDimensions.space12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.navyBorder : AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _cmpRow('Investment Simulator', 'Fixed deposits only', 'Full 6-Product Sourced Suite', isDark),
                      _divider(isDark),
                      _cmpRow('What-If Scenarios', '1 baseline scenario', 'Unlimited + Custom Modeler', isDark),
                      _divider(isDark),
                      _cmpRow('AI Copilot Explanations', 'Basic overview', 'Deep Verified Context Engine', isDark),
                      _divider(isDark),
                      _cmpRow('Household Members', 'Single user', 'Up to 5 (Family Plan)', isDark),
                      _divider(isDark),
                      _cmpRow('Advertisements', 'Demo sponsored banners', '100% Ad-Free Guarantee', isDark),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space20),

                // Demo Notice
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightLavender,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.navyBorder : AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'DEMO / PROJECTED. All subscription plans and demo payments are simulated for development and presentation. Real payments require store and accountant verification.',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Inline student section shown in the pricing box when Student tier is selected.
  Widget _buildStudentInlineSection(bool isDark) {
    final svc = SubscriptionService.instance;
    final verificationStatus = svc.studentVerificationStatus;
    final isEligible = svc.isStudentEligible;
    final isVerifiedEdu = verificationStatus == 'verified_edu';
    final isSelfDeclared = verificationStatus == 'self_declared_demo';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (isVerifiedEdu) {
      statusColor = AppColors.success;
      statusIcon = Icons.verified_rounded;
      statusLabel = 'Verified (.edu / .ac.in)';
    } else if (isSelfDeclared) {
      statusColor = AppColors.warning;
      statusIcon = Icons.info_rounded;
      statusLabel = 'Self-Declared Demo';
    } else {
      statusColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
      statusIcon = Icons.badge_outlined;
      statusLabel = 'Not Verified';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Eligibility status chip
        Row(
          children: [
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 6),
            Text(
              'Student Eligibility: $statusLabel',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Verify & Activate button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudentVerificationPage()),
            ),
            icon: Icon(
              isEligible ? Icons.school_rounded : Icons.verified_outlined,
              size: 17,
            ),
            label: Text(
              isEligible ? 'View Student Status & Trial' : 'Verify Eligibility & Activate Trial',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (isEligible)
          OutlinedButton(
            onPressed: _isLoading ? null : _activate,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Activate Demo Student Plan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            isEligible
                ? '30-day trial · ₹49/mo · Backend-enforced eligibility'
                : 'Requires .edu, .ac.in, or .edu.in email to access student pricing',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _tierChoiceCard({
    required String title,
    required String tier,
    required String subtitle,
    required bool isDark,
  }) {
    final isSelected = _selectedTier == tier;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTier = tier),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withAlpha(20)
                : (isDark ? AppColors.darkSurface : AppColors.cardBackground),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? AppColors.navyBorder : AppColors.cardBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
      ),
    );
  }

  Widget _cmpRow(String feature, String free, String pro, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              pro,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(height: 1, color: isDark ? AppColors.navyBorder : AppColors.cardBorder);
  }
}
