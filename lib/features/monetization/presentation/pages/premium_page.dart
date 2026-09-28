import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../services/subscription_service.dart';

/// Premium Upgrade Page showing Free vs Pro comparison and demo activation.
class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    SubscriptionService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _activate() async {
    setState(() => _isLoading = true);
    await SubscriptionService.instance.activateDemoPremium();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🎉 Pennora Pro activated (Demo)!'),
        backgroundColor: AppColors.mint,
      ));
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

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Premium',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.space16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Subtitle
                Text(
                  'Turn your savings into a goal-based money growth plan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Pricing Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPro
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightLavender,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DEMO PREMIUM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (isPro)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 14, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
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
                            '₹99',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            ' / month',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Instant full access to advanced allocation and multi-product simulations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!isPro)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _activate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Activate Demo Premium'),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _cancel,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel Demo Access',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space24),

                // Feature Cards
                _sectionLabel('PREMIUM FEATURES', isDark),
                const SizedBox(height: AppDimensions.space12),

                _featureCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Goal-based allocation',
                  description:
                      'Intelligently map your surplus to fixed and market-linked instruments based on milestone horizons.',
                  isDark: isDark,
                ),
                _featureCard(
                  icon: Icons.explore_outlined,
                  title: 'Investment discovery',
                  description:
                      'Simulate recurring deposits, PPF, index funds, and sovereign benchmarks side by side.',
                  isDark: isDark,
                ),
                _featureCard(
                  icon: Icons.trending_down_outlined,
                  title: 'Historical downside',
                  description:
                      'Review stress-tested downside models to protect liquid reserves against drawdown shocks.',
                  isDark: isDark,
                ),
                _featureCard(
                  icon: Icons.tune_outlined,
                  title: 'What-if analysis',
                  description:
                      'Test changes to your monthly surplus and evaluate accelerated completion dates in real time.',
                  isDark: isDark,
                ),
                _featureCard(
                  icon: Icons.notifications_active_outlined,
                  title: 'Monthly monitoring',
                  description:
                      'Continuous surplus recalculation with proactive alerts when your plan falls off schedule.',
                  isDark: isDark,
                ),
                _featureCard(
                  icon: Icons.description_outlined,
                  title: 'Plan reports',
                  description:
                      'Generate audit-grade financial summary reports and export complete allocation roadmaps.',
                  isDark: isDark,
                ),

                const SizedBox(height: AppDimensions.space24),

                // Feature Comparison Table
                _sectionLabel('PLAN COMPARISON', isDark),
                const SizedBox(height: AppDimensions.space12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                    ),
                  ),
                  child: Column(children: [
                    _cmpRow('Goals Limit', 'Up to 3 goals', 'Unlimited', isDark),
                    _divider(isDark),
                    _cmpRow('Investment Simulator', 'Fixed deposits only', 'Full 5-Product Suite', isDark),
                    _divider(isDark),
                    _cmpRow('What-If Scenarios', '1 scenario', 'Unlimited + Custom Modeler', isDark),
                    _divider(isDark),
                    _cmpRow('AI Copilot', 'Basic rules', 'LangGraph Intelligence', isDark),
                    _divider(isDark),
                    _cmpRow('Ad-Free', 'Partner banners', '100% Ad-Free', isDark),
                  ]),
                ),

                const SizedBox(height: AppDimensions.space20),

                // Demo Notice
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightLavender,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DEMO PREMIUM: This is a risk-free demonstration environment. No charges occur.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: AppDimensions.space32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.lightLavender,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  description,
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
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Text(text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight));
  }

  Widget _cmpRow(String title, String free, String pro, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
      child: Row(children: [
        Expanded(
            flex: 4,
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight))),
        Expanded(
            flex: 3,
            child: Text(free,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight))),
        Expanded(
            flex: 3,
            child: Row(children: [
              const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(pro,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary))),
            ])),
      ]),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
        height: 1,
        color: isDark ? AppColors.navyBorder : const Color(0xFFE6EEF5));
  }
}
