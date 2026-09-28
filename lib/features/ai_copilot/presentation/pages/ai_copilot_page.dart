import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/services/auth_service.dart';
import '../../../onboarding/services/financial_profile_service.dart';
import '../../../investment/services/investment_service.dart';
import '../../models/pipeline_insight_model.dart';
import '../../services/ai_insights_service.dart';

/// Unified AI Copilot Workspace for Pennora.
///
/// Houses:
/// 1. Current Financial Snapshot (surplus, emergency reserve, savings rate)
/// 2. Money Simulator (deterministic SIP, lump-sum, wealth projection across products)
/// 3. What-If Scenarios (surplus adjustments & goal timeline impacts)
/// 4. Sourced Matching Investment Options (filtered & ranked deterministically)
/// 5. Ask Pennora (AI Financial Chatbot powered by Llama 3.2 via verified context)
/// 6. Multi-Agent Pipeline Status & Execution History
class AiCopilotPage extends StatefulWidget {
  const AiCopilotPage({super.key});

  @override
  State<AiCopilotPage> createState() => _AiCopilotPageState();
}

class _AiCopilotPageState extends State<AiCopilotPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Simulator State
  double _principal = 50000;
  double _monthlySip = 5000;
  double _durationYears = 5;
  final String _selectedCategory = 'ALL';
  InvestmentSimulationOutput? _simOutput;
  bool _isLoadingSim = false;


  // What-If State
  double _customDelta = -2000;

  // Sourced Eligible Options State
  List<MatchingInvestmentOption> _eligibleOptions = [];
  bool _isLoadingOptions = false;

  // Chatbot State
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<_ChatMessage> _chatMessages = [];
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AiInsightsService.instance.addListener(_onInsightUpdate);
    AiInsightsService.instance.refresh();

    _loadSim();
    _loadEligibleOptions();
    _initChatGreetings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    AiInsightsService.instance.removeListener(_onInsightUpdate);
    super.dispose();
  }

  void _onInsightUpdate() {
    if (mounted) setState(() {});
  }

  void _initChatGreetings() {
    _chatMessages.add(
      _ChatMessage(
        text:
            "Hello! I am your Pennora Financial Copilot. I analyze your current financial surplus, active goals, and verified investment options. How can I assist you today?",
        isUser: false,
        source: "Pennora Copilot",
        timestamp: DateTime.now(),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)} K';
    return '₹${v.toStringAsFixed(0)}';
  }

  Future<void> _loadSim() async {
    setState(() => _isLoadingSim = true);
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
    if (mounted) {
      setState(() {
        _simOutput = out;
        _isLoadingSim = false;
      });
    }
  }

  Future<void> _loadEligibleOptions() async {
    setState(() => _isLoadingOptions = true);
    final opts = await InvestmentClientService.instance.fetchEligibleOptions();
    if (mounted) {
      setState(() {
        _eligibleOptions = opts;
        _isLoadingOptions = false;
      });
    }
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _chatController.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _chatController.clear();
    }

    setState(() {
      _chatMessages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isChatLoading = true;
    });

    _scrollChatToBottom();

    // Call backend copilot chat
    final res = await InvestmentClientService.instance.askCopilot(
      message: text,
      principal: _principal,
      monthlyContribution: _monthlySip,
      durationYears: _durationYears,
      whatIfMonthlyDelta: _customDelta,
    );

    if (mounted) {
      setState(() {
        _isChatLoading = false;
        if (res != null && res['reply'] != null) {
          _chatMessages.add(
            _ChatMessage(
              text: res['reply'].toString(),
              isUser: false,
              source: res['source']?.toString() ?? "llama3.2_verified",
              relevantCards: res['relevant_cards'] as List<dynamic>?,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          _chatMessages.add(
            _ChatMessage(
              text:
                  "Based on your verified financial profile, regular disciplined contributions aligned with your current surplus and maintaining 3–6 months of essential reserves provides the strongest foundation for long-term growth.",
              isUser: false,
              source: "Pennora Copilot",
              timestamp: DateTime.now(),
            ),
          );
        }
      });
      _scrollChatToBottom();
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svc = AiInsightsService.instance;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Copilot',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Multi-Agent Financial Intelligence Workspace',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Intelligence',
            onPressed: () {
              svc.refresh(force: true);
              _loadSim();
              _loadEligibleOptions();
            },
          ),
        ],
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
            Tab(text: 'Intelligence & Simulator'),
            Tab(text: 'Multi-Agent Pipeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkspaceView(isDark),
          _buildPipelineView(isDark, svc),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: FINANCIAL INTELLIGENCE & SIMULATOR WORKSPACE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWorkspaceView(bool isDark) {
    final userId = AuthService.instance.currentUser?.id ?? '';
    final profile = FinancialProfileService.instance.getProfile(userId);
    final surplus = profile?.monthlySurplus ?? 0.0;
    final savings = profile?.savingsReserve ?? 0.0;
    final essential = (profile?.monthlyFixedExpenses ?? 0.0) +
        ((profile?.monthlyVariableExpenses ?? 0.0) * 0.5) +
        (profile?.existingLoanEmi ?? 0.0);

    final emergencyMonths =
        essential > 0 ? (savings / essential) : (savings > 0 ? 6.0 : 0.0);
    final savingsRate = (profile?.monthlyIncome ?? 0.0) > 0
        ? (surplus / profile!.monthlyIncome * 100.0).clamp(0.0, 100.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.space16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Current Financial Snapshot Card
              _buildFinancialSnapshotCard(
                isDark,
                surplus: surplus,
                savings: savings,
                emergencyMonths: emergencyMonths,
                savingsRate: savingsRate,
              ),
              const SizedBox(height: AppDimensions.space20),

              // 2. Money Simulator Card
              _buildSimulatorCard(isDark, surplus: surplus),
              const SizedBox(height: AppDimensions.space20),

              // 3. What-If Scenario Card
              _buildWhatIfCard(isDark, surplus: surplus),
              const SizedBox(height: AppDimensions.space20),

              // 4. Sourced Matching Investment Options
              _buildMatchingOptionsCard(isDark),
              const SizedBox(height: AppDimensions.space20),

              // 5. Ask Pennora (AI Financial Chatbot)
              _buildChatbotCard(isDark),
              const SizedBox(height: AppDimensions.space32),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Financial Snapshot ──────────────────────────────────────────────────

  Widget _buildFinancialSnapshotCard(
    bool isDark, {
    required double surplus,
    required double savings,
    required double emergencyMonths,
    required double savingsRate,
  }) {
    return Container(
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.lightLavender,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Financial Snapshot',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Live baseline powering deterministic simulations',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'VERIFIED STATE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  isDark,
                  label: 'Monthly Surplus',
                  value: _fmt(surplus),
                  subtext: 'Available for goals',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  isDark,
                  label: 'Emergency Fund',
                  value: '${emergencyMonths.toStringAsFixed(1)} mo',
                  subtext: emergencyMonths >= 3 ? 'Safe buffer' : 'Buffer needed',
                  color: emergencyMonths >= 3
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  isDark,
                  label: 'Savings Rate',
                  value: '${savingsRate.toStringAsFixed(0)}%',
                  subtext: 'Of total income',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    bool isDark, {
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Money Simulator ─────────────────────────────────────────────────────

  Widget _buildSimulatorCard(bool isDark, {required double surplus}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.lightLavender,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Money Simulator',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Deterministic projection across lump-sum and recurring SIP',
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
              if (_isLoadingSim)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),

          // Sliders
          _buildSliderRow(
            isDark,
            label: 'Initial Lump-Sum Investment',
            valueText: _fmt(_principal),
            min: 0,
            max: 500000,
            divisions: 50,
            value: _principal,
            onChanged: (v) {
              setState(() => _principal = v);
              _loadSim();
            },
          ),
          const SizedBox(height: 10),
          _buildSliderRow(
            isDark,
            label: 'Monthly SIP Commitment',
            valueText: '${_fmt(_monthlySip)}/mo',
            min: 500,
            max: 100000,
            divisions: 99,
            value: _monthlySip,
            onChanged: (v) {
              setState(() => _monthlySip = v);
              _loadSim();
            },
          ),
          const SizedBox(height: 10),
          _buildSliderRow(
            isDark,
            label: 'Investment Duration',
            valueText: '${_durationYears.toStringAsFixed(0)} Years',
            min: 1,
            max: 30,
            divisions: 29,
            value: _durationYears,
            onChanged: (v) {
              setState(() => _durationYears = v);
              _loadSim();
            },
          ),
          const SizedBox(height: AppDimensions.space16),

          // Results Preview Box
          if (_simOutput != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Principal Invested',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmt(_simOutput!.totalInvested),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Top Projected Value',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _simOutput!.projections.isNotEmpty
                                ? _fmt(_simOutput!.projections.first.estimatedFutureValue)
                                : '—',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_simOutput!.hasLiquidityWarning) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _simOutput!.warnings.isNotEmpty
                                  ? _simOutput!.warnings.first
                                  : 'Liquidity warning: Ensure essential emergency reserves are kept safe.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    bool isDark, {
    required String label,
    required String valueText,
    required double min,
    required double max,
    required int divisions,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              valueText,
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: isDark ? AppColors.navyBorder : const Color(0xFFE2E8F0),
            thumbColor: AppColors.primary,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ── 3. What-If Scenario ────────────────────────────────────────────────────

  Widget _buildWhatIfCard(bool isDark, {required double surplus}) {
    final adjSurplus = math.max(0.0, surplus + _customDelta);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.lightLavender,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What-If Scenario Modeler',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Test changes to monthly surplus on investment growth and goal feasibility',
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
          ),
          const SizedBox(height: AppDimensions.space16),
          Text(
            'Adjust Monthly Surplus: ${_customDelta >= 0 ? '+' : ''}${_fmt(_customDelta)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _customDelta >= 0 ? AppColors.success : AppColors.warning,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:
                  _customDelta >= 0 ? AppColors.success : AppColors.warning,
              inactiveTrackColor: isDark ? AppColors.navyBorder : const Color(0xFFE2E8F0),
              thumbColor:
                  _customDelta >= 0 ? AppColors.success : AppColors.warning,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _customDelta,
              min: -10000,
              max: 10000,
              divisions: 20,
              onChanged: (v) => setState(() => _customDelta = v),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Surplus',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      _fmt(surplus),
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
                const Icon(Icons.arrow_forward_rounded, size: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Simulated Surplus',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      _fmt(adjSurplus),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _customDelta >= 0
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Sourced Matching Options ────────────────────────────────────────────

  Widget _buildMatchingOptionsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.lightLavender,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Matching Investment Options',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Filtered & ranked deterministically from AMFI, NSE, SBI, and MoF',
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
              if (_isLoadingOptions)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),

          if (_eligibleOptions.isEmpty && !_isLoadingOptions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Options are being evaluated based on your latest financial commitments.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            )
          else
            ..._eligibleOptions.map((opt) => _buildOptionRow(isDark, opt)),
        ],
      ),
    );
  }

  Widget _buildOptionRow(bool isDark, MatchingInvestmentOption opt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.productName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${opt.provider} • Sourced from ${opt.source}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  opt.rateOrNavText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            opt.whyItMatches,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Risk: ${opt.riskLevel}',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Liquidity: ${opt.liquidity}',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Text(
                'Min: ₹${opt.minimumInvestment.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5. Ask Pennora (AI Chatbot) ────────────────────────────────────────────

  Widget _buildChatbotCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.lightLavender,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask Pennora Copilot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Conversational explanations backed by strictly verified context',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LLAMA 3.2',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _buildPromptChip("What if I invest ₹5,000 monthly?", isDark),
                _buildPromptChip("Why did you show this option?", isDark),
                _buildPromptChip("Which option has lower risk?", isDark),
                _buildPromptChip("What if my surplus decreases by ₹2,000?", isDark),
                _buildPromptChip("Explain this result simply.", isDark),
              ],
            ),
          ),

          // Chat Messages Box
          Container(
            height: 280,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
            child: ListView.builder(
              controller: _chatScrollController,
              itemCount: _chatMessages.length,
              itemBuilder: (context, idx) {
                final msg = _chatMessages[idx];
                return _buildMessageBubble(isDark, msg);
              },
            ),
          ),

          if (_isChatLoading)
            LinearProgressIndicator(
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 2,
            ),

          // Text Input Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask about your savings, options, or simulation...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : const Color(0xFFF8FAFC),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isChatLoading ? null : () => _sendMessage(),
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        backgroundColor:
            isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEEF2FF),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: isDark ? AppColors.navyBorder : AppColors.primary.withAlpha(40),
        ),
        onPressed: () => _sendMessage(text),
      ),
    );
  }

  Widget _buildMessageBubble(bool isDark, _ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 580),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: msg.isUser
              ? null
              : Border.all(
                  color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: msg.isUser
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
            if (!msg.isUser && msg.source != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 10, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Verified Context',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: MULTI-AGENT PIPELINE (PRESERVED LANGGRAPH RESULTS)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPipelineView(bool isDark, AiInsightsService svc) {
    if (!svc.hasInsight) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hub_outlined, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'No Transaction Analysis Yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'As SMS or manual transactions are recorded, the 6-agent LangGraph pipeline processes them and surfaces automated insights here.',
                textAlign: TextAlign.center,
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
      );
    }

    final insight = svc.latestInsight!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.space16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pipeline Status Card
              _buildPipelineStatusCard(insight, isDark),
              const SizedBox(height: AppDimensions.space16),

              // Headline Card
              _buildHeadlineCard(insight, isDark),
              const SizedBox(height: AppDimensions.space16),

              // Financial State
              if (insight.financialState != null)
                _buildFinancialStateCard(insight, isDark),
              if (insight.financialState != null)
                const SizedBox(height: AppDimensions.space16),

              // Goal Impact
              if (insight.goals != null && insight.goals!.isNotEmpty)
                _buildGoalImpactCard(insight, isDark),
              if (insight.goals != null && insight.goals!.isNotEmpty)
                const SizedBox(height: AppDimensions.space16),

              // Conflicts
              _buildConflictCard(insight, isDark),
              const SizedBox(height: AppDimensions.space16),

              // Scenarios
              if (insight.hasScenarios) _buildScenariosCard(insight, isDark),
              const SizedBox(height: AppDimensions.space24),

              // History
              _buildHistorySection(svc.history, isDark),
              const SizedBox(height: AppDimensions.space32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Existing Pipeline Cards ────────────────────────────────────────────────

  Widget _buildPipelineStatusCard(PipelineInsight insight, bool isDark) {
    const allAgents = [
      ('transaction_agent', 'Transaction Agent', AppColors.primary),
      ('financial_state_agent', 'Financial State Agent', AppColors.success),
      ('goal_agent', 'Goal Agent', Color(0xFF64B5F6)),
      ('conflict_agent', 'Conflict Agent', AppColors.warning),
      ('scenario_agent', 'Scenario Agent', Color(0xFFBA68C8)),
      ('explanation_agent', 'Explanation Agent', AppColors.secondary),
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'PIPELINE EXECUTION STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...allAgents.map((agent) {
            final isDone = insight.completedStages.contains(agent.$1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 14,
                    color: isDone ? agent.$3 : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    agent.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  if (isDone)
                    Text(
                      'COMPLETE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: agent.$3,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeadlineCard(PipelineInsight insight, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.headline,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          if (insight.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              insight.summary,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialStateCard(PipelineInsight insight, bool isDark) {
    final fs = insight.financialState!;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINANCIAL STATE INSIGHT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            fs['recommendation']?.toString() ??
                'Financial parameters updated from recent transactions.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalImpactCard(PipelineInsight insight, bool isDark) {
    final goals = insight.goals!;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GOAL IMPACT EVALUATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          ...goals.take(3).map((g) {
            final name = (g['goal_name'] as String?) ?? 'Goal';
            final status = (g['goal_status'] as String?) ?? 'On Track';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConflictCard(PipelineInsight insight, bool isDark) {
    final hasConflict = insight.hasConflict;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasConflict ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            size: 18,
            color: hasConflict ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasConflict
                  ? 'Goal conflict identified from recent cashflow run-rate.'
                  : 'No goal conflicts detected across active deadlines.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
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

  Widget _buildScenariosCard(PipelineInsight insight, bool isDark) {
    final scenarios = insight.scenarios;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AGENT SCENARIO PROJECTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          ...scenarios.take(2).map((s) {
            final title = (s['scenario_name'] as String?) ?? 'Scenario';
            final desc = (s['description'] as String?) ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  if (desc.isNotEmpty)
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List<InsightHistoryItem> history, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALYSIS HISTORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Text(
            'No prior transaction pipeline runs recorded.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          )
        else
          ...history.take(5).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        item.isProcessed
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 14,
                        color: item.isProcessed
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.headline ?? 'Pipeline execution complete',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? source;
  final List<dynamic>? relevantCards;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.source,
    this.relevantCards,
    required this.timestamp,
  });
}
