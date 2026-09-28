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
                              'Goals Journey',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dream bigger, plan smarter, and achieve more.',
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
                        GestureDetector(
                          onTap: _openCreateGoal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5A58EE),
                                  Color(0xFF835CF6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withAlpha(80),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'New Goal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // ── Financial Journey Hero Banner ───────────────────────
                  if (allGoals.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF071A52),
                            Color(0xFF0F2B82),
                            Color(0xFF2E1065),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2B82).withAlpha(100),
                            blurRadius: 18,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'JOURNEY OVERVIEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.electricCyan,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${allGoals.where((g) => g.isCompleted).length}/${allGoals.length} Achieved',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Saved',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withAlpha(180),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _fmt(totalSaved),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.mint,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Target',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withAlpha(180),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _fmt(totalTarget),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Another Goal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.violet,
                          side: const BorderSide(color: AppColors.violet),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
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
              ? AppColors.violet
              : (isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.violet
                : (isDark
                    ? AppColors.navyBorder.withAlpha(80)
                    : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

    return Column(
      children: [
        const SizedBox(height: AppDimensions.space32),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withAlpha(80),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.flag_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        Text(
          'Start Your Financial Journey',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppDimensions.space10),
        Text(
          "Goals are the foundation of Pennora's intelligence engine. Create a goal to track your milestone targets and keep your future aligned.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppDimensions.space28),
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5A58EE),
                Color(0xFF835CF6),
                Color(0xFFA855F7),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withAlpha(90),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: onCreateGoal,
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Create Your First Goal',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space40),
      ],
    );
  }
}
