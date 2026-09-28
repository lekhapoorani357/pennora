import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../ai_copilot/presentation/pages/ai_copilot_page.dart';
import '../../../ai_copilot/services/ai_insights_service.dart';
import '../../../auth/services/auth_service.dart';
import '../../../financial_state/presentation/pages/financial_state_page.dart';
import '../../../goals/models/goal_model.dart';
import '../../../goals/presentation/pages/create_goal_page.dart';
import '../../../goals/presentation/pages/goals_page.dart';
import '../../../goals/services/goal_service.dart';
import '../../../onboarding/models/financial_profile_model.dart';
import '../../../onboarding/presentation/pages/financial_onboarding_page.dart';
import '../../../onboarding/presentation/pages/role_selection_page.dart';
import '../../../onboarding/services/financial_profile_service.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../transactions/models/transaction_model.dart';
import '../../../transactions/presentation/pages/transaction_detail_page.dart';
import '../../../transactions/presentation/pages/transactions_page.dart';
import '../../../transactions/services/transaction_service.dart';
import '../../../investment/presentation/pages/money_growth_page.dart';

/// Pennora Main Dashboard with 5-tab bottom navigation.
///
/// Designed to reflect the Pennora brand identity:
/// "Smart money + personal growth + modern lifestyle + AI"
/// Deep Navy, Royal Blue, Violet, Mint, and soft lavender surfaces.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    GoalService.instance.init();
    FinancialProfileService.instance.init();
    TransactionService.instance.init();
    GoalService.instance.addListener(_refresh);
    FinancialProfileService.instance.addListener(_refresh);
    TransactionService.instance.addListener(_refresh);
    AiInsightsService.instance.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = AuthService.instance.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        GoalService.instance.fetchGoalsFromBackend(userId);
        FinancialProfileService.instance.fetchProfileFromBackend(userId);
        TransactionService.instance.fetchTransactionsFromBackend(userId);
        AiInsightsService.instance.refresh();
      }
    });
  }

  @override
  void dispose() {
    GoalService.instance.removeListener(_refresh);
    FinancialProfileService.instance.removeListener(_refresh);
    TransactionService.instance.removeListener(_refresh);
    AiInsightsService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _openAddTransactionModal(String userId) {
    showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditTransactionModal(userId: userId),
    );
  }

  void _openCreateGoal() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateGoalPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = AuthService.instance.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeDashboardView(
            onNavigateToGoals: () => setState(() => _currentIndex = 1),
            onNavigateToTransactions: () => setState(() => _currentIndex = 2),
            onNavigateToAi: () => setState(() => _currentIndex = 3),
            onNavigateToProfile: () => setState(() => _currentIndex = 4),
            onQuickAddTransaction: () => _openAddTransactionModal(userId),
            onQuickCreateGoal: _openCreateGoal,
          ),
          const GoalsPage(),
          const TransactionsPage(),
          const AiCopilotPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildModernBottomNav(isDark),
    );
  }

  Widget _buildModernBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.navyBorder.withAlpha(120)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(60)
                : const Color(0xFF0F172A).withAlpha(12),
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                index: 0,
                icon: Icons.grid_view_rounded,
                label: 'Home',
                isDark: isDark,
              ),
              _navItem(
                index: 1,
                icon: Icons.track_changes_rounded,
                label: 'Goals',
                isDark: isDark,
              ),
              _navItem(
                index: 2,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Activity',
                isDark: isDark,
              ),
              _navItem(
                index: 3,
                icon: Icons.auto_awesome_rounded,
                label: 'AI Copilot',
                isDark: isDark,
                hasGlow: true,
              ),
              _navItem(
                index: 4,
                icon: Icons.person_rounded,
                label: 'Profile',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
    bool hasGlow = false,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = hasGlow ? AppColors.electricCyan : AppColors.royalBlue;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (hasGlow
                  ? AppColors.electricCyan.withAlpha(25)
                  : AppColors.royalBlue.withAlpha(20))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? activeColor
                  : (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? activeColor
                    : (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Home Tab Body
// ─────────────────────────────────────────────────────────────
class _HomeDashboardView extends StatelessWidget {
  final VoidCallback onNavigateToGoals;
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onNavigateToAi;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onQuickAddTransaction;
  final VoidCallback onQuickCreateGoal;

  const _HomeDashboardView({
    required this.onNavigateToGoals,
    required this.onNavigateToTransactions,
    required this.onNavigateToAi,
    required this.onNavigateToProfile,
    required this.onQuickAddTransaction,
    required this.onQuickCreateGoal,
  });

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService.instance.currentUser;
    final userName =
        user?.fullName.isNotEmpty == true ? user!.fullName : 'Explorer';
    final userId = user?.id ?? '';
    final goals = GoalService.instance.getGoalsForUser(userId);
    final profile = FinancialProfileService.instance.getProfile(userId);
    final isOnboarded =
        FinancialProfileService.instance.isOnboardingCompleted(userId);
    final transactions =
        TransactionService.instance.getTransactionsForUser(userId);
    final insight = AiInsightsService.instance.latestInsight;
    final hasConflict = insight?.hasConflict ?? false;
    final conflicts = insight?.conflicts ?? [];
    final role = FinancialProfileService.instance.getRole(userId);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH,
          vertical: AppDimensions.space16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Brand Header
                _buildHeader(isDark, user),
                const SizedBox(height: AppDimensions.space20),

                // 2. Personal Greeting & Role Badge
                _buildGreetingSection(isDark, userName, user, role),
                const SizedBox(height: AppDimensions.space16),

                // Role-specific tips banner
                _RoleTipsBanner(role: role, isDark: isDark),
                const SizedBox(height: AppDimensions.space20),

                // 3. Main Financial Summary Hero Card
                _buildMainFinancialCard(
                  context: context,
                  isDark: isDark,
                  isOnboarded: isOnboarded,
                  profile: profile,
                ),
                const SizedBox(height: AppDimensions.space16),

                // 4. Motivational Banner
                _buildMotivationalBanner(isDark),
                const SizedBox(height: AppDimensions.space20),

                // 5. Quick Actions Row
                _buildQuickActions(context, isDark, isOnboarded),
                const SizedBox(height: AppDimensions.space20),

                // MONEY GROWTH & SIMULATOR
                _buildMoneyGrowthCard(
                  context: context,
                  isDark: isDark,
                ),
                const SizedBox(height: AppDimensions.space20),

                // 6. AI Insights Summary (if available)
                if (insight != null && insight.available) ...[
                  _buildAiInsightCard(isDark, insight),
                  const SizedBox(height: AppDimensions.space20),
                ],

                // 7. Goal Conflicts Alert (if any)
                if (hasConflict && conflicts.isNotEmpty) ...[
                  _buildConflictBanner(isDark, conflicts),
                  const SizedBox(height: AppDimensions.space20),
                ],

                // 8. Goals & Progress Section
                _buildGoalsSection(context, isDark, goals),
                const SizedBox(height: AppDimensions.space20),

                // 9. Recent Activity / Transactions Section
                _buildRecentTransactionsSection(context, isDark, transactions),
                const SizedBox(height: AppDimensions.space32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header with Logo & Status ─────────────────────────────
  Widget _buildHeader(bool isDark, dynamic user) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.hub_rounded, size: 22, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PENNORA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mint,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SMART MONEY & AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.mint,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onNavigateToProfile,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user?.fullName.isNotEmpty == true
                    ? user!.fullName[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Greeting & Profile Badges ─────────────────────────────
  Widget _buildGreetingSection(bool isDark, String userName, dynamic user, String role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hello, $userName 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            _RoleBadge(role: role),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Track your priorities, grow your wealth, and reach goals faster.',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  // ── Hero Main Financial Card ──────────────────────────────
  Widget _buildMainFinancialCard({
    required BuildContext context,
    required bool isDark,
    required bool isOnboarded,
    required FinancialProfile? profile,
  }) {
    if (!isOnboarded || profile == null) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.space24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF071A52), Color(0xFF0B1F5E), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF071A52).withAlpha(120),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14, color: AppColors.electricCyan),
                      SizedBox(width: 6),
                      Text(
                        'PENNORA VAULT',
                        style: TextStyle(
                          color: AppColors.electricCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.lock_outline_rounded,
                    color: Colors.white54, size: 18),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Connect your financial data to activate real-time intelligence.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const FinancialOnboardingPage()),
              ),
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: const Text('Set Up Financial Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricCyan,
                foregroundColor: AppColors.deepNavy,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    final surplus = profile.totalMonthlyIncome - profile.totalMonthlyExpenses;
    final isSurplus = surplus >= 0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FinancialStatePage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF071A52),
              Color(0xFF0F2B82),
              Color(0xFF1E1B4B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2B82).withAlpha(100),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top tag
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_graph_rounded,
                          size: 14, color: AppColors.electricCyan),
                      SizedBox(width: 6),
                      Text(
                        'TOTAL SAVINGS & NET WORTH',
                        style: TextStyle(
                          color: AppColors.electricCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.white54),
              ],
            ),
            const SizedBox(height: 14),

            // Giant Balance
            Text(
              _fmt(profile.currentSavings),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 18),

            // Inflow / Outflow Split Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.mint.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_downward_rounded,
                              size: 16, color: AppColors.mint),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withAlpha(180),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _fmt(profile.totalMonthlyIncome),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withAlpha(30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.pink.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_upward_rounded,
                              size: 16, color: AppColors.pink),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outflow',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withAlpha(180),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _fmt(profile.totalMonthlyExpenses),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Surplus Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSurplus
                    ? AppColors.mint.withAlpha(30)
                    : AppColors.warning.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSurplus
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    size: 14,
                    color: isSurplus ? AppColors.mint : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${isSurplus ? "Monthly Surplus:" : "Monthly Deficit:"} ${isSurplus ? "+" : "-"}${_fmt(surplus.abs())}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSurplus ? AppColors.mint : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Motivational Quote Banner ─────────────────────────────
  Widget _buildMotivationalBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF2E1065)]
              : [const Color(0xFFEEF2FF), const Color(0xFFFCE7F3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF4338CA).withAlpha(80)
              : const Color(0xFFE0E7FF),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded,
                size: 20, color: AppColors.violet),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dream Bigger, Plan Smarter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'Good financial habits build true personal freedom.',
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
    );
  }

  // ── Quick Actions Grid ────────────────────────────────────
  Widget _buildQuickActions(
      BuildContext context, bool isDark, bool isOnboarded) {
    return Row(
      children: [
        Expanded(
          child: _quickActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add Money',
            color: AppColors.royalBlue,
            isDark: isDark,
            onTap: onQuickAddTransaction,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionButton(
            icon: Icons.flag_rounded,
            label: 'New Goal',
            color: AppColors.violet,
            isDark: isDark,
            onTap: onQuickCreateGoal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionButton(
            icon: Icons.auto_awesome_rounded,
            label: 'AI Copilot',
            color: AppColors.electricCyan,
            isDark: isDark,
            onTap: onNavigateToAi,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionButton(
            icon: Icons.insights_rounded,
            label: 'Analytics',
            color: AppColors.mint,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FinancialStatePage()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.navyBorder.withAlpha(100)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(20)
                  : const Color(0xFF0F172A).withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Insights Card ──────────────────────────────────────
  Widget _buildAiInsightCard(bool isDark, dynamic insight) {
    final headline = insight.headline as String? ?? 'Analysis complete';

    return GestureDetector(
      onTap: onNavigateToAi,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0B1F5E),
                    const Color(0xFF1E1B4B),
                  ]
                : [
                    const Color(0xFFEEF2FF),
                    const Color(0xFFF3E8FF),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withAlpha(80),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.royalBlue, AppColors.purple],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withAlpha(60),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 22, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PENNORA AI INSIGHT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    headline,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.purple),
          ],
        ),
      ),
    );
  }

  // ── Goal Conflicts Alert ──────────────────────────────────
  Widget _buildConflictBanner(
      bool isDark, List<Map<String, dynamic>> conflicts) {
    return GestureDetector(
      onTap: onNavigateToAi,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(isDark ? 30 : 20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.warning.withAlpha(100)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 24, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal Conflict Detected (${conflicts.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to view recommendations and balance target allocations.',
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
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.warning),
          ],
        ),
      ),
    );
  }

  // ── Goals Section ─────────────────────────────────────────
  Widget _buildGoalsSection(
      BuildContext context, bool isDark, List<GoalModel> goals) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? AppColors.navyBorder.withAlpha(100)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(30)
                : const Color(0xFF0F172A).withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'YOUR GOALS JOURNEY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.violet,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onNavigateToGoals,
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),

          if (goals.isEmpty)
            _buildEmptyGoalsPrompt(context, isDark)
          else ...[
            ...goals.take(3).map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoalDashboardRow(goal: goal, isDark: isDark),
                  ),
                ),
            if (goals.length > 3)
              GestureDetector(
                onTap: onNavigateToGoals,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${goals.length - 3} more goals',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.royalBlue,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsPrompt(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.navyMid.withAlpha(80)
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag_outlined,
                size: 22, color: AppColors.violet),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No goals created yet',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'Set a goal to unlock predictive conflict analysis.',
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
          ElevatedButton(
            onPressed: onQuickCreateGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Recent Activity / Transactions Section ────────────────
  Widget _buildRecentTransactionsSection(
      BuildContext context, bool isDark, List<TransactionModel> transactions) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? AppColors.navyBorder.withAlpha(100)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(30)
                : const Color(0xFF0F172A).withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.royalBlue,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RECENT ACTIVITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.royalBlue,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onNavigateToTransactions,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),

          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.navyMid.withAlpha(80)
                    : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 22, color: AppColors.royalBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'Tap + Add Money above to record your first transaction.',
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
            )
          else ...[
            ...transactions.take(4).map(
                  (tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TransactionRowItem(
                      transaction: tx,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TransactionDetailPage(transaction: tx),
                        ),
                      ),
                    ),
                  ),
                ),
            if (transactions.length > 4)
              GestureDetector(
                onTap: onNavigateToTransactions,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${transactions.length - 4} more transactions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.royalBlue,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoneyGrowthCard({
    required BuildContext context,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MoneyGrowthPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.navyBorder : const Color(0xFFD6E4F0),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(30)
                  : Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientAccent,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                size: 24,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Money Growth & Simulator',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.mint.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SIP/Lump-sum projections & What-If scenarios',
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
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Goal Row Item for Dashboard
// ─────────────────────────────────────────────────────────────
class _GoalDashboardRow extends StatelessWidget {
  final GoalModel goal;
  final bool isDark;

  const _GoalDashboardRow({required this.goal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant.withAlpha(120)
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: goal.isCompleted
                      ? AppColors.mint.withAlpha(30)
                      : AppColors.royalBlue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.progressPercentage,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color:
                        goal.isCompleted ? AppColors.mint : AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progressFraction,
              backgroundColor: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(15),
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? AppColors.mint : AppColors.violet,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved: ₹${goal.currentAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                'Target: ₹${goal.targetAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Transaction Row Item for Dashboard
// ─────────────────────────────────────────────────────────────
class _TransactionRowItem extends StatelessWidget {
  final TransactionModel transaction;
  final bool isDark;
  final VoidCallback onTap;

  const _TransactionRowItem({
    required this.transaction,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.isDebit;
    final badgeColor = isDebit ? AppColors.pink : AppColors.mint;
    final badgeBg = isDebit
        ? AppColors.pink.withAlpha(20)
        : AppColors.mint.withAlpha(20);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDebit
                    ? Icons.arrow_outward_rounded
                    : Icons.arrow_downward_rounded,
                size: 18,
                color: badgeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchantName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.category} • ${transaction.paymentMethod.displayName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    transaction.signedFormattedAmount,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.formattedDate,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    String emoji;
    String label;
    Color accentColor;

    switch (role) {
      case 'student':
        emoji = '🎓';
        label = 'Student';
        accentColor = const Color(0xFF38BDF8);
        break;
      case 'working_married':
        emoji = '👨‍👩‍👧';
        label = 'Family';
        accentColor = AppColors.mint;
        break;
      case 'working_single':
      default:
        emoji = '💼';
        label = 'Professional';
        accentColor = AppColors.electricCyan;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withAlpha(25),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: accentColor.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 12, color: accentColor),
          ],
        ),
      ),
    );
  }
}

class _RoleTipsBanner extends StatelessWidget {
  final String role;
  final bool isDark;

  const _RoleTipsBanner({required this.role, required this.isDark});

  @override
  Widget build(BuildContext context) {
    String tipTitle;
    String tipBody;
    IconData icon;
    Color color;

    switch (role) {
      case 'student':
        tipTitle = 'Student Financial Strategy';
        tipBody =
            'Prioritize your essential campus expenses and build a ₹5,000 emergency buffer before allocating funds to gadgets or discretionary trips.';
        icon = Icons.school_rounded;
        color = const Color(0xFF38BDF8);
        break;
      case 'working_married':
        tipTitle = 'Family & Household Resilience';
        tipBody =
            'Ensure household medical & term insurance coverage for all dependents. Maintain at least 6 months of combined family living expenses in emergency reserves.';
        icon = Icons.family_restroom_rounded;
        color = AppColors.mint;
        break;
      case 'working_single':
      default:
        tipTitle = 'Professional Wealth Building';
        tipBody =
            'Target a minimum 20% monthly savings rate. Build 3–6 months of basic living costs in high-liquidity reserves before accelerating long-term growth.';
        icon = Icons.trending_up_rounded;
        color = AppColors.electricCyan;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tipBody,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
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
}
