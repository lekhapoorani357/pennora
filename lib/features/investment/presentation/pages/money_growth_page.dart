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
        length: 3, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 2));
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Money Growth',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Plan how your savings can support your goals.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Investment Plan'),
            Tab(text: 'What-If'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSimTab(isDark),
          _buildWhatIfTab(isDark),
          _buildInsightsTab(isDark),
        ],
      ),
    );
  }

  // ─── TAB 1: INVESTMENT SIMULATOR ─────────────────────────────────────────

  Widget _buildSimTab(bool isDark) {
    final userId = AuthService.instance.currentUser?.id ?? '';
    final profile = FinancialProfileService.instance.getProfile(userId);
    final surplus = profile?.monthlySurplus ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.space20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Monthly Surplus Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 0 : 6),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.lightLavender,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.savings_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Monthly Surplus',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmt(surplus),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightLavender,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Suitable for horizon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

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
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.navyBorder : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.tune_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('SIMULATION PARAMETERS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight)),
        ]),
        const SizedBox(height: AppDimensions.space20),
        _sliderRow('Initial Lump Sum', _fmt(_principal), AppColors.primary, isDark),
        Slider(
          value: _principal,
          min: 0,
          max: 1000000,
          divisions: 100,
          activeColor: AppColors.primary,
          onChanged: (v) {
            setState(() => _principal = v);
            _runSim();
          },
        ),
        _sliderRow('Monthly SIP', _fmt(_monthlySip), AppColors.secondary, isDark),
        Slider(
          value: _monthlySip,
          min: 0,
          max: 50000,
          divisions: 50,
          activeColor: AppColors.secondary,
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
          activeColor: AppColors.accent,
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
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.warning_amber_outlined, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Text('Liquidity & Surplus Notice',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
        _chip('RD', 'Recurring Deposits', isDark),
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
        selectedColor: AppColors.lightLavender,
        checkmarkColor: AppColors.primary,
        backgroundColor:
            isDark ? AppColors.darkSurfaceVariant : AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: sel
                ? AppColors.primary
                : (isDark ? AppColors.navyBorder : AppColors.cardBorder),
          ),
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
          color: sel
              ? AppColors.primary
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
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 4),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              p.productName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.isGuaranteed
                  ? AppColors.success.withAlpha(20)
                  : AppColors.lightLavender,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              p.isGuaranteed ? 'Guaranteed' : 'Eligible Option',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: p.isGuaranteed ? AppColors.success : AppColors.primary,
              ),
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
                : AppColors.textSecondaryLight,
          ),
        ),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statCol(
            'INVESTED',
            _fmt(p.totalInvested),
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          _statCol(
            'EST. GAIN',
            '+${_fmt(p.estimatedGain)}',
            AppColors.success,
          ),
          _statCol(
            'PROJECTED',
            _fmt(p.estimatedFutureValue),
            AppColors.primary,
            large: true,
          ),
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
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded,
            size: 16, color: AppColors.primary),
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
                color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 0 : 6),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.auto_graph_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('CUSTOM WHAT-IF MODELER',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
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
                            fontWeight: FontWeight.w700,
                            color: _customDelta >= 0
                                ? AppColors.success
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
                      _customDelta >= 0 ? AppColors.primary : AppColors.error,
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
                    letterSpacing: 0.8,
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
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightLavender.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.flash_on_outlined,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
              child: Text(impact,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary))),
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
                  color: AppColors.success)),
        ]),
      ]),
    );
  }

  Widget _scenarioCard(WhatIfScenarioModel sc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 4),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
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
              color: AppColors.lightLavender,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(sc.tag,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.track_changes_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(sc.goalImpactText,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
                  color: AppColors.success)),
        ]),
      ]),
    );
  }

  // ─── TAB 3: INSIGHTS ──────────────────────────────────────────────────────

  Widget _buildInsightsTab(bool isDark) {
    final userId = AuthService.instance.currentUser?.id ?? '';
    final profile = FinancialProfileService.instance.getProfile(userId);
    final goals = GoalService.instance.getGoalsForUser(userId);
    final surplus = profile?.monthlySurplus ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.space20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Available Monthly Surplus Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.space20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 0 : 6),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE MONTHLY SURPLUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fmt(surplus),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Net surplus after essential expenses available for goal funding and disciplined growth.',
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
              const SizedBox(height: AppDimensions.space16),

              // Recommended Allocation Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.space20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 0 : 6),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECOMMENDED ALLOCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightLavender,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Balanced Horizon',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 30,
                            child: Container(
                              height: 8,
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            flex: 40,
                            child: Container(
                              height: 8,
                              color: AppColors.secondary,
                            ),
                          ),
                          Expanded(
                            flex: 30,
                            child: Container(
                              height: 8,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _allocationLegendRow(
                      color: AppColors.primary,
                      title: 'Emergency & Liquid Reserve (30%)',
                      amount: _fmt(surplus * 0.3),
                      desc: 'Fixed Deposits, Liquid Funds, High-yield Savings',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _allocationLegendRow(
                      color: AppColors.secondary,
                      title: 'Targeted Goals Funding (40%)',
                      amount: _fmt(surplus * 0.4),
                      desc: 'Recurring Deposits, Conservative Debt & Hybrid Funds',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _allocationLegendRow(
                      color: AppColors.accent,
                      title: 'Wealth Growth & Equity (30%)',
                      amount: _fmt(surplus * 0.3),
                      desc: 'Diversified Index Funds, Nifty 50, Long-term PPF',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Goal Impact Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.space20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 0 : 6),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GOAL IMPACT ANALYSIS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      goals.isEmpty
                          ? 'No active goals recorded. Create a goal to see how systematic contributions accelerate your milestones.'
                          : 'Allocating 40% of your surplus (${_fmt(surplus * 0.4)}/mo) directly to active goals will keep your timeline on track.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (goals.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...goals.map((g) {
                        final req = g.remainingAmount;
                        final alloc = surplus * 0.4;
                        final projectedMonths = alloc > 0 ? (req / alloc).ceil() : 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  g.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              Text(
                                projectedMonths > 0
                                    ? 'Est. ~$projectedMonths mo'
                                    : 'Funded',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _allocationLegendRow({
    required Color color,
    required String title,
    required String amount,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
