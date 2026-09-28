import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/services/auth_service.dart';
import '../../models/goal_model.dart';
import '../../services/goal_service.dart';
import '../widgets/goal_card.dart';
import 'create_goal_page.dart';
import 'goal_detail_page.dart';

/// Full Goals tab page redesigned as a visual "Financial Journey".
///
/// Retains all existing service bindings, creation, and detail flows.
class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  String _selectedFilter = 'All'; // 'All', 'Active', 'Completed'

  @override
  void initState() {
    super.initState();
    GoalService.instance.addListener(_onGoalsChanged);
    final userId = AuthService.instance.currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      GoalService.instance.fetchGoalsFromBackend(userId);
    }
  }

  @override
  void dispose() {
    GoalService.instance.removeListener(_onGoalsChanged);
    super.dispose();
  }

  void _onGoalsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openCreateGoal() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateGoalPage()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openGoalDetail(GoalModel goal) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalDetailPage(goal: goal)),
    );
    if (mounted) setState(() {});
  }

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = AuthService.instance.currentUser?.id ?? '';
    final allGoals = GoalService.instance.getGoalsForUser(userId);

    final filteredGoals = allGoals.where((g) {
      if (_selectedFilter == 'Active') return !g.isCompleted;
      if (_selectedFilter == 'Completed') return g.isCompleted;
      return true;
    }).toList();

    final totalSaved = allGoals.fold<double>(0, (sum, g) => sum + g.currentAmount);
    final totalTarget = allGoals.fold<double>(0, (sum, g) => sum + g.targetAmount);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
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
                  // ── Top Bar ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Goals',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your milestone targets and savings progress.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (allGoals.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _openCreateGoal,
                          icon: const Icon(Icons.add_outlined, size: 18),
                          label: const Text('New Goal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // ── Financial Overview Card ──────────────────────────────
                  if (allGoals.isNotEmpty) ...[
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
                            color: Colors.black.withAlpha(isDark ? 0 : 8),
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
                                'OVERALL GOAL PROGRESS',
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightLavender,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${allGoals.where((g) => g.isCompleted).length} of ${allGoals.length} Achieved',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Target',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fmt(totalTarget),
                                      style: TextStyle(
                                        fontSize: 20,
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
                                width: 1,
                                height: 36,
                                color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Saved',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fmt(totalSaved),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Progress',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      totalTarget > 0
                                          ? '${((totalSaved / totalTarget) * 100).clamp(0, 100).toStringAsFixed(0)}%'
                                          : '0%',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: totalTarget > 0
                                  ? (totalSaved / totalTarget).clamp(0.0, 1.0)
                                  : 0.0,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.lightLavender.withAlpha(120),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space20),

                    // ── Filter Pills ─────────────────────────────────────
                    Row(
                      children: [
                        _filterPill('All (${allGoals.length})', 'All', isDark),
                        const SizedBox(width: 8),
                        _filterPill(
                            'Active (${allGoals.where((g) => !g.isCompleted).length})',
                            'Active',
                            isDark),
                        const SizedBox(width: 8),
                        _filterPill(
                            'Completed (${allGoals.where((g) => g.isCompleted).length})',
                            'Completed',
                            isDark),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),
                  ],

                  // ── Content ────────────────────────────────────────────
                  if (allGoals.isEmpty)
                    _EmptyGoalsState(onCreateGoal: _openCreateGoal)
                  else if (filteredGoals.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No $_selectedFilter goals found.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    ...filteredGoals.map(
                      (g) => GoalCard(
                        goal: g,
                        onTap: () => _openGoalDetail(g),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openCreateGoal,
                        icon: const Icon(Icons.add_outlined, size: 18),
                        label: const Text('Add Another Goal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterPill(String title, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurfaceVariant : AppColors.cardBackground),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.navyBorder : AppColors.cardBorder),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  final VoidCallback onCreateGoal;
  const _EmptyGoalsState({required this.onCreateGoal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.lightLavender,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_outlined,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          Text(
            'No Goals Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Create your first savings goal to track your milestone targets and let Pennora optimize your monthly surplus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          ElevatedButton.icon(
            onPressed: onCreateGoal,
            icon: const Icon(Icons.add_outlined, size: 18),
            label: const Text('Create Your First Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
