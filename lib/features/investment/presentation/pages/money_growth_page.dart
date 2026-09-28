import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/intelligence/models/what_if_scenario_model.dart';
import '../../../auth/services/auth_service.dart';
import '../../../goals/services/goal_service.dart';
import '../../../onboarding/services/financial_profile_service.dart';
import '../../services/investment_service.dart';

/// Money Growth & Investment Simulator Page.
/// Two tabs: Investment Simulator (SIP/Lump-sum across products) and
/// What-If Scenario Modeler with deterministic arithmetic — no LLM math.
class MoneyGrowthPage extends StatefulWidget {
  final int initialTabIndex;
  const MoneyGrowthPage({super.key, this.initialTabIndex = 0});

  @override
  State<MoneyGrowthPage> createState() => _MoneyGrowthPageState();
}

class _MoneyGrowthPageState extends State<MoneyGrowthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Simulator state
  double _principal = 50000;
  double _monthlySip = 5000;
  double _durationYears = 5;
  String _selectedCategory = 'ALL';
  InvestmentSimulationOutput? _simOutput;

  // What-if state
  double _customDelta = 2000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _runSim();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)} K';
    return '₹${v.toStringAsFixed(0)}';
  }

  Future<void> _runSim() async {
    final userId = AuthService.instance.currentUser?.id ?? '';
    final profile = FinancialProfileService.instance.getProfile(userId);
    final out = await InvestmentClientService.instance.simulate(
      principal: _principal,
      monthlyContribution: _monthlySip,
      durationYears: _durationYears,
      currentSavings: profile?.savingsReserve ?? 0,
      monthlySurplus: profile?.monthlySurplus ?? 0,
      category: _selectedCategory,
    );
    if (mounted) setState(() => _simOutput = out);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Money Growth & Simulator',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.electricCyan,
          labelColor: AppColors.electricCyan,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Investment Simulator'),
            Tab(text: 'What-If Scenarios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSimTab(isDark), _buildWhatIfTab(isDark)],
      ),
    );
  }

  // ─── TAB 1: INVESTMENT SIMULATOR ─────────────────────────────────────────

  Widget _buildSimTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.space20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _inputCard(isDark),
              const SizedBox(height: AppDimensions.space16),
              if (_simOutput != null && _simOutput!.warnings.isNotEmpty)
                _warningBanner(isDark),
              _categoryChips(isDark),
              const SizedBox(height: AppDimensions.space16),
              if (_simOutput != null)
                ..._simOutput!.projections.map((p) => _productCard(p, isDark)),
              const SizedBox(height: AppDimensions.space16),
              _disclaimerCard(isDark),
              const SizedBox(height: AppDimensions.space32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
            color: isDark ? AppColors.navyBorder : const Color(0xFFD6E4F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.tune_rounded, size: 18, color: AppColors.electricCyan),
          const SizedBox(width: 8),
          Text('SIMULATION PARAMETERS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight)),
        ]),
        const SizedBox(height: AppDimensions.space20),
        _sliderRow('Initial Lump Sum', _fmt(_principal), AppColors.mint, isDark),
        Slider(
          value: _principal,
          min: 0,
          max: 1000000,
          divisions: 100,
          activeColor: AppColors.mint,
          onChanged: (v) {
            setState(() => _principal = v);
            _runSim();
          },
        ),
        _sliderRow('Monthly SIP', _fmt(_monthlySip), AppColors.electricCyan, isDark),
        Slider(
          value: _monthlySip,
          min: 0,
          max: 50000,
          divisions: 50,
          activeColor: AppColors.electricCyan,
          onChanged: (v) {
            setState(() => _monthlySip = v);
            _runSim();
          },
        ),
        _sliderRow(
          'Investment Horizon',
          '${_durationYears.toInt()} Yrs  (${(_durationYears * 12).toInt()} mo)',
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          isDark,
        ),
        Slider(
          value: _durationYears,
          min: 1,
          max: 25,
          divisions: 24,
          activeColor: AppColors.warning,
          onChanged: (v) {
            setState(() => _durationYears = v);
            _runSim();
          },
        ),
      ]),
    );
  }

  Widget _sliderRow(String label, String value, Color valueColor, bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight)),
      Text(value,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
    ]);
  }

  Widget _warningBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      margin: const EdgeInsets.only(bottom: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.warning.withAlpha(100)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Text('Liquidity & Surplus Notice',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning)),
        ]),
        const SizedBox(height: 6),
        ..._simOutput!.warnings.map((w) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('• $w',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
            )),
      ]),
    );
  }

  Widget _categoryChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _chip('ALL', 'All Options', isDark),
        _chip('FD', 'Fixed Deposits', isDark),
        _chip('RD', 'Recurring', isDark),
        _chip('PPF', 'PPF', isDark),
        _chip('INDEX_FUNDS', 'Index Funds', isDark),
        _chip('EQUITY', 'Equity Funds', isDark),
      ]),
    );
  }

  Widget _chip(String code, String label, bool isDark) {
    final sel = _selectedCategory == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) {
          setState(() => _selectedCategory = code);
          _runSim();
        },
        selectedColor: AppColors.electricCyan.withAlpha(50),
        checkmarkColor: AppColors.electricCyan,
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
          color: sel
              ? AppColors.electricCyan
              : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        ),
      ),
    );
  }

  Widget _productCard(ProductSimulationResult p, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
            color: isDark ? AppColors.navyBorder : const Color(0xFFD6E4F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(p.productName,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.isGuaranteed
                  ? AppColors.mint.withAlpha(30)
                  : AppColors.electricCyan.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              p.isGuaranteed ? 'Guaranteed' : 'Market-Linked',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color:
                      p.isGuaranteed ? AppColors.mint : AppColors.electricCyan),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          '${p.rateRangeText} • Risk: ${p.risk} • ${p.liquidity}',
          style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        ),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statCol('INVESTED', _fmt(p.totalInvested),
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          _statCol('EST. GAIN', '+${_fmt(p.estimatedGain)}', AppColors.mint),
          _statCol('PROJECTED', _fmt(p.estimatedFutureValue),
              AppColors.electricCyan, large: true),
        ]),
        if (p.conservativeValue != null && p.optimisticValue != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bear: ${_fmt(p.conservativeValue!)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)),
                  Text('Bull: ${_fmt(p.optimisticValue!)}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight)),
                ]),
          ),
        ],
        if (p.taxNotes != null) ...[
          const SizedBox(height: 6),
          Text('Tax: ${p.taxNotes!}',
              style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight)),
        ],
      ]),
    );
  }

  Widget _statCol(String label, String value, Color color,
      {bool large = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              fontSize: large ? 17 : 14,
              fontWeight: FontWeight.w800,
              color: color)),
    ]);
  }

  Widget _disclaimerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded,
            size: 16, color: AppColors.electricCyan),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
          'Educational Simulator: Uses compound interest arithmetic with illustrative benchmarks. Not guaranteed returns. Market-linked products carry risk.',
          style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        )),
      ]),
    );
  }

  // ─── TAB 2: WHAT-IF SCENARIOS ─────────────────────────────────────────────

  Widget _buildWhatIfTab(bool isDark) {
    final userId = AuthService.instance.currentUser?.id ?? '';
    final profile = FinancialProfileService.instance.getProfile(userId);
    final goals = GoalService.instance.getGoalsForUser(userId);
    final primaryGoal = goals.isNotEmpty ? goals.first : null;
    final primaryRemaining = primaryGoal?.remainingAmount ?? 0.0;
    final primaryMonths = primaryGoal != null
        ? (primaryGoal.daysRemaining / 30).ceil().clamp(1, 9999)
        : 12;
    final surplus = profile?.monthlySurplus ?? 0.0;
    final reserve = profile?.savingsReserve ?? 0.0;
    final essential = profile?.essentialExpenses ?? 0.0;

    final scenarios = WhatIfScenarioModel.generateScenarios(
      currentMonthlySavings: surplus,
      currentTotalSavings: reserve,
      essentialExpenses: essential,
      primaryGoalRemaining: primaryRemaining,
      primaryGoalMonths: primaryMonths,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.space20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Custom interactive modeler
            Container(
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF0F2338), Color(0xFF081420)]
                      : const [Color(0xFFE8F6FB), Color(0xFFF1F8FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                border: Border.all(color: AppColors.electricCyan.withAlpha(80)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.auto_graph_rounded,
                      size: 20, color: AppColors.electricCyan),
                  const SizedBox(width: 8),
                  Text('CUSTOM WHAT-IF MODELER',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight)),
                ]),
                const SizedBox(height: 12),
                Text('Adjust your monthly savings surplus by:',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _customDelta >= 0
                            ? '+${_fmt(_customDelta)}/mo'
                            : '-${_fmt(_customDelta.abs())}/mo',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _customDelta >= 0
                                ? AppColors.mint
                                : AppColors.error),
                      ),
                      Text(
                        'New: ${_fmt((surplus + _customDelta).clamp(0, 9999999))}/mo',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ]),
                Slider(
                  value: _customDelta,
                  min: -15000,
                  max: 25000,
                  divisions: 80,
                  activeColor:
                      _customDelta >= 0 ? AppColors.mint : AppColors.error,
                  onChanged: (v) => setState(() => _customDelta = v),
                ),
                const SizedBox(height: 8),
                _customImpact(surplus, reserve, primaryRemaining, primaryMonths, isDark),
              ]),
            ),

            const SizedBox(height: AppDimensions.space24),
            Text('PRE-COMPUTED STRATEGIC SCENARIOS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)),
            const SizedBox(height: AppDimensions.space12),
            ...scenarios.map((sc) => _scenarioCard(sc, isDark)),
            const SizedBox(height: AppDimensions.space32),
          ]),
        ),
      ),
    );
  }

  Widget _customImpact(double surplus, double reserve, double primaryRemaining,
      int primaryMonths, bool isDark) {
    final newSurplus = (surplus + _customDelta).clamp(0.0, 9999999.0);
    final yr1 = reserve + newSurplus * 12;
    final yr3 = reserve + newSurplus * 36;

    String impact;
    if (primaryRemaining > 0 && newSurplus > 0) {
      final months = (primaryRemaining / newSurplus).ceil();
      final diff = primaryMonths - months;
      impact = diff > 0
          ? 'Reach primary goal $diff months earlier (~$months mo)'
          : diff < 0
              ? 'Primary goal delayed by ~${-diff} months'
              : 'On track to meet primary goal on schedule';
    } else {
      impact = 'Consistent contributions accelerate financial freedom.';
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.flash_on_rounded,
              size: 16, color: AppColors.electricCyan),
          const SizedBox(width: 6),
          Expanded(
              child: Text(impact,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.electricCyan))),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('1-Yr Reserve: ${_fmt(yr1)}',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
          Text('3-Yr: ${_fmt(yr3)}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mint)),
        ]),
      ]),
    );
  }

  Widget _scenarioCard(WhatIfScenarioModel sc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
            color: isDark ? AppColors.navyBorder : const Color(0xFFD6E4F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(sc.title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.electricCyan.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(sc.tag,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.electricCyan)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(sc.subtitle,
            style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Row(children: [
            const Icon(Icons.track_changes_rounded,
                size: 16, color: AppColors.mint),
            const SizedBox(width: 8),
            Expanded(
                child: Text(sc.goalImpactText,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight))),
          ]),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('1-Yr: ${_fmt(sc.projected1YrSavings)}',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
          Text('3-Yr: ${_fmt(sc.projected3YrSavings)}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mint)),
        ]),
      ]),
    );
  }
}
