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
import '../../../onboarding/services/financial_profile_service.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../transactions/models/transaction_model.dart';
import '../../../transactions/presentation/pages/transaction_detail_page.dart';
import '../../../transactions/presentation/pages/transactions_page.dart';
import '../../../transactions/services/transaction_service.dart';
import '../../../investment/presentation/pages/money_growth_page.dart';

/// Pennora Main Dashboard with 5-tab bottom navigation.
///
/// Refreshed to a professional SaaS finance interface:
/// - Crisp white surfaces, subtle slate borders (#E2E8F0)
/// - Deep Indigo primary accents (#4F46E5)
/// - Clear financial hierarchy & tabular metrics
/// - Clean outline iconography, zero childish/cartoon graphics
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
            onNavigateToMoneyGrowth: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MoneyGrowthPage()),
            ),
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
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                index: 0,
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                label: 'Home',
                isDark: isDark,
              ),
              _navItem(
                index: 1,
                icon: Icons.track_changes_outlined,
                activeIcon: Icons.track_changes_rounded,
                label: 'Goals',
                isDark: isDark,
              ),
              _navItem(
                index: 2,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Activity',
                isDark: isDark,
              ),
              _navItem(
                index: 3,
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'AI',
                isDark: isDark,
              ),
              _navItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
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
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurfaceVariant : AppColors.supporting)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondaryLight),
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
// Home Tab Body (Professional Financial Dashboard)
// ─────────────────────────────────────────────────────────────
class _HomeDashboardView extends StatelessWidget {
  final VoidCallback onNavigateToGoals;
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onNavigateToMoneyGrowth;
  final VoidCallback onNavigateToAi;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onQuickAddTransaction;
  final VoidCallback onQuickCreateGoal;

  const _HomeDashboardView({
    required this.onNavigateToGoals,
    required this.onNavigateToTransactions,
    required this.onNavigateToMoneyGrowth,
    required this.onNavigateToAi,
    required this.onNavigateToProfile,
    required this.onQuickAddTransaction,
    required this.onQuickCreateGoal,
  });

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)} K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService.instance.currentUser;
    final rawName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Explorer';
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

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

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
                // 1. Top Greeting Header (matches reference)
                _buildHeader(isDark, greeting, rawName, user, isOnboarded),
                const SizedBox(height: AppDimensions.space20),

                // Role Strategy Tag
                _RoleTipsBanner(role: role, isDark: isDark),
                const SizedBox(height: AppDimensions.space16),

                // 2. Financial Overview Hero Card
                _buildFinancialOverviewCard(
                  context: context,
                  isDark: isDark,
                  isOnboarded: isOnboarded,
                  profile: profile,
                ),
                const SizedBox(height: AppDimensions.space20),

                // 3. Quick Actions Row
                _buildQuickActions(context, isDark),
                const SizedBox(height: AppDimensions.space20),

                // 4. Financial Health Metrics
                _buildFinancialHealthGrid(isDark, profile, goals),
                const SizedBox(height: AppDimensions.space20),

                // 5. Goal Conflicts Alert (if any)
                if (hasConflict && conflicts.isNotEmpty) ...[
                  _buildConflictBanner(isDark, conflicts),
                  const SizedBox(height: AppDimensions.space20),
                ],

                // 6. Goals Progress Section
                _buildGoalsSection(context, isDark, goals),
                const SizedBox(height: AppDimensions.space20),

                // 7. Recent Transactions Section
                _buildRecentTransactionsSection(context, isDark, transactions),
                const SizedBox(height: AppDimensions.space32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header with Greeting & Avatar ──────────────────
  Widget _buildHeader(
      bool isDark, String greeting, String name, dynamic user, bool isOnboarded) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $name',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (isOnboarded && user?.email != null && (user!.email as String).isNotEmpty)
                    ? user.email
                    : "Here's your real-time financial overview.",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        // AI Copilot Quick Launch
        IconButton(
          onPressed: onNavigateToAi,
          tooltip: 'AI Copilot',
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // User Avatar
        GestureDetector(
          onTap: onNavigateToProfile,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lavenderBorder,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                user?.fullName.isNotEmpty == true
                    ? user!.fullName[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Financial Overview Hero Card ───────────────────────
  Widget _buildFinancialOverviewCard({
    required BuildContext context,
    required bool isDark,
    required bool isOnboarded,
    required FinancialProfile? profile,
  }) {
    if (!isOnboarded || profile == null) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.space20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.supporting,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FINANCIAL STATE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'No financial data connected yet.',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FinancialOnboardingPage(),
                  ),
                ),
                icon: const Icon(Icons.add_link_rounded, size: 18),
                label: const Text('Set Up Financial Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final income = profile.totalMonthlyIncome;
    final expenses = profile.totalMonthlyExpenses;
    final surplus = income - expenses;
    final isSurplus = surplus >= 0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FinancialStatePage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x060F172A),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Tag & Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FINANCIAL STATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Figure: Available Monthly Surplus
            Text(
              _fmt(surplus.abs()),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: isSurplus
                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSurplus ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isSurplus ? 'Available Monthly Surplus' : 'Monthly Deficit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Inflow / Outflow / Savings 3-column breakdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                      label: 'Income',
                      amount: _fmt(income),
                      color: AppColors.success,
                      icon: Icons.arrow_downward_rounded,
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  Expanded(
                    child: _metricColumn(
                      label: 'Outflow',
                      amount: _fmt(expenses),
                      color: AppColors.textSecondaryLight,
                      icon: Icons.arrow_upward_rounded,
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  Expanded(
                    child: _metricColumn(
                      label: 'Savings',
                      amount: _fmt(profile.currentSavings),
                      color: AppColors.primary,
                      icon: Icons.account_balance_wallet_outlined,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tap to view detailed financial state',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricColumn({
    required String label,
    required String amount,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
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
    );
  }

  // ── 3. Quick Actions Row (Goals, Transactions, Money Growth, Financial State)
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.flag_outlined,
            label: 'Track Goals',
            tintColor: AppColors.primary,
            bgColor: AppColors.supporting,
            isDark: isDark,
            onTap: onNavigateToGoals,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.receipt_long_outlined,
            label: 'Transactions',
            tintColor: AppColors.warning,
            bgColor: AppColors.warningLight,
            isDark: isDark,
            onTap: onNavigateToTransactions,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.trending_up_rounded,
            label: 'Money Growth',
            tintColor: AppColors.secondary,
            bgColor: AppColors.supporting,
            isDark: isDark,
            onTap: onNavigateToMoneyGrowth,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.pie_chart_outline_rounded,
            label: 'State',
            tintColor: AppColors.mintDark,
            bgColor: AppColors.mintLight,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FinancialStatePage()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color tintColor,
    required Color bgColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: tintColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Financial Health Metrics Grid ───────────────────────
  Widget _buildFinancialHealthGrid(
      bool isDark, FinancialProfile? profile, List<GoalModel> goals) {
    double savingsRate = 0.0;
    double emergencyMonths = 0.0;
    if (profile != null && profile.totalMonthlyIncome > 0) {
      final surplus = profile.totalMonthlyIncome - profile.totalMonthlyExpenses;
      savingsRate = (surplus / profile.totalMonthlyIncome) * 100;
      if (profile.totalMonthlyExpenses > 0) {
        emergencyMonths = profile.currentSavings / profile.totalMonthlyExpenses;
      }
    }

    final totalTarget = goals.fold<double>(0, (s, g) => s + g.targetAmount);
    final totalSaved = goals.fold<double>(0, (s, g) => s + g.currentAmount);
    final goalPercent = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FINANCIAL HEALTH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _healthMetricCard(
                title: 'Savings Rate',
                value: '${savingsRate.clamp(0, 100).toStringAsFixed(0)}%',
                subtitle: savingsRate >= 20 ? 'Target achieved' : 'Aim for 20%+',
                isPositive: savingsRate >= 20,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _healthMetricCard(
                title: 'Emergency Fund',
                value: '${emergencyMonths.toStringAsFixed(1)} mo',
                subtitle: emergencyMonths >= 3 ? 'Safe buffer' : 'Build to 3–6 mo',
                isPositive: emergencyMonths >= 3,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _healthMetricCard(
                title: 'Goal Progress',
                value: '${goalPercent.toStringAsFixed(0)}%',
                subtitle: '${goals.length} active goals',
                isPositive: goalPercent >= 50,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _healthMetricCard(
                title: 'Monthly Surplus',
                value: profile != null
                    ? _fmt(profile.totalMonthlyIncome - profile.totalMonthlyExpenses)
                    : '₹0',
                subtitle: 'Liquid monthly buffer',
                isPositive: (profile?.totalMonthlyIncome ?? 0) >= (profile?.totalMonthlyExpenses ?? 0),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _healthMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isPositive,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPositive ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5. Goal Conflict Alert ────────────────────────────────
  Widget _buildConflictBanner(
      bool isDark, List<Map<String, dynamic>> conflicts) {
    return GestureDetector(
      onTap: onNavigateToAi,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.warningLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withAlpha(120)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 20, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal Conflict Detected (${conflicts.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to view recommendations and rebalance milestone allocations.',
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
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.warning),
          ],
        ),
      ),
    );
  }

  // ── 6. Goal Progress Section ──────────────────────────────
  Widget _buildGoalsSection(
      BuildContext context, bool isDark, List<GoalModel> goals) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR GOALS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              GestureDetector(
                onTap: onNavigateToGoals,
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsPrompt(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.supporting,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.flag_outlined, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            child: const Text('Create Your First Goal'),
          ),
        ],
      ),
    );
  }

  // ── 7. Recent Transactions Section ────────────────────────
  Widget _buildRecentTransactionsSection(
      BuildContext context, bool isDark, List<TransactionModel> transactions) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT TRANSACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              GestureDetector(
                onTap: onNavigateToTransactions,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.supporting,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          'Transactions will appear here when your financial data is connected.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: onNavigateToTransactions,
                          child: const Text(
                            'View All Transactions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
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
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Clean Goal Card for Dashboard
// ─────────────────────────────────────────────────────────────
class _GoalDashboardRow extends StatelessWidget {
  final GoalModel goal;
  final bool isDark;

  const _GoalDashboardRow({required this.goal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = goal.isCompleted
        ? AppColors.success
        : (goal.daysRemaining < 0
            ? AppColors.error
            : (goal.daysRemaining <= 30 ? AppColors.warning : AppColors.primary));

    final statusText = goal.isCompleted
        ? 'ON TRACK'
        : (goal.daysRemaining < 0
            ? 'SHORTFALL'
            : (goal.daysRemaining <= 30 ? 'AT RISK' : 'ON TRACK'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
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
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progressFraction,
              backgroundColor: isDark
                  ? Colors.white.withAlpha(20)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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
// Clean Transaction Row Item
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Icon(
                isDebit ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                size: 16,
                color: isDebit ? AppColors.textPrimaryLight : AppColors.success,
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
                      fontWeight: FontWeight.w600,
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
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.signedFormattedAmount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDebit
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.formattedDate,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondaryLight,
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

// ─────────────────────────────────────────────────────────────
// Role Tips Banner
// ─────────────────────────────────────────────────────────────
class _RoleTipsBanner extends StatelessWidget {
  final String role;
  final bool isDark;

  const _RoleTipsBanner({required this.role, required this.isDark});

  @override
  Widget build(BuildContext context) {
    String tipTitle;
    String tipBody;
    IconData icon;

    switch (role) {
      case 'student':
        tipTitle = 'Student Financial Strategy';
        tipBody =
            'Prioritize essential academic living expenses and build a ₹5,000 emergency buffer before allocating funds to discretionary goals.';
        icon = Icons.school_outlined;
        break;
      case 'working_married':
        tipTitle = 'Family & Household Resilience';
        tipBody =
            'Ensure medical insurance coverage for all dependents. Maintain at least 6 months of combined living expenses in liquid reserves.';
        icon = Icons.family_restroom_outlined;
        break;
      case 'working_single':
      default:
        tipTitle = 'Professional Wealth Building';
        tipBody =
            'Target a minimum 20% monthly savings rate. Build 3–6 months of basic living costs in liquid reserves before accelerating long-term growth.';
        icon = Icons.trending_up_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.supporting,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lavenderBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tipBody,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
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
