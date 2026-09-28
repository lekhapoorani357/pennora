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
        title: const Text('Pennora Pro',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.space20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D253F), Color(0xFF163E66)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(color: AppColors.warning.withAlpha(120)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.warning.withAlpha(40),
                          blurRadius: 20,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(40),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.workspace_premium_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(isPro ? 'PRO ACTIVE' : 'UPGRADE TO PRO',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppColors.warning)),
                      ]),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    const Text('Unlock Full Financial Freedom',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      'Unlimited goals, full investment simulator, custom what-if scenarios, and LangGraph AI Copilot.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(200),
                          height: 1.4),
                    ),
                    const SizedBox(height: AppDimensions.space20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('₹99',
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.warning)),
                          Text(' / month',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(180))),
                        ]),
                  ]),
                ),

                const SizedBox(height: AppDimensions.space24),

                // Feature Comparison
                _sectionLabel('PLAN COMPARISON', isDark),
                const SizedBox(height: AppDimensions.space12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(
                        color: isDark
                            ? AppColors.navyBorder
                            : const Color(0xFFD6E4F0)),
                  ),
                  child: Column(children: [
                    _cmpRow('Goals Limit', 'Up to 3 goals', 'Unlimited', isDark),
                    _divider(isDark),
                    _cmpRow('Investment Simulator', 'Basic Fixed Returns', 'Full 5-Product Suite', isDark),
                    _divider(isDark),
                    _cmpRow('What-If Scenarios', '1 Scenario', 'Unlimited + Custom', isDark),
                    _divider(isDark),
                    _cmpRow('AI Copilot', 'Rule-based', 'LangGraph Reasoning', isDark),
                    _divider(isDark),
                    _cmpRow('Ad-Free', 'Sponsored Partners', '100% Ad-Free', isDark),
                  ]),
                ),

                const SizedBox(height: AppDimensions.space20),

                // Demo notice
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.electricCyan.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.electricCyan.withAlpha(80)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.electricCyan),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                      'DEMO MODE: No real payment is charged. Tapping "Activate Pro" simulates premium access instantly.',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    )),
                  ]),
                ),

                const SizedBox(height: AppDimensions.space24),

                // Action Button
                if (!isPro)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _activate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.deepNavy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.deepNavy))
                        : const Text('Activate Pennora Pro (Demo)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                  )
                else
                  Column(children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withAlpha(25),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: AppColors.mint.withAlpha(100)),
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.mint),
                            SizedBox(width: 8),
                            Text('You are on Pennora Pro!',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mint)),
                          ]),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd)),
                      ),
                      child: const Center(
                          child: Text('Cancel Subscription',
                              style: TextStyle(fontWeight: FontWeight.w700))),
                    ),
                  ]),

                const SizedBox(height: AppDimensions.space32),
              ],
            ),
          ),
        ),
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
              const Icon(Icons.check_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(pro,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning))),
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
