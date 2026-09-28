import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../models/goal_model.dart';
import 'goal_progress_bar.dart';

/// Professional Goal Card matching the financial planning design system.
///
/// Displays:
/// - Goal name & Priority badge (High/Medium/Low)
/// - Target amount, Saved amount, Remaining amount, Target date
/// - Clean Progress bar
/// - Estimated Monthly required contribution
/// - Status label: ON TRACK, AT RISK, SHORTFALL
class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onTap;

  const GoalCard({super.key, required this.goal, required this.onTap});

  Color _statusColor() {
    if (goal.isCompleted) return AppColors.success;
    if (goal.daysRemaining < 0) return AppColors.error;
    if (goal.daysRemaining <= 45) return AppColors.warning;
    return AppColors.primary;
  }

  String _statusLabel() {
    if (goal.isCompleted) return 'ON TRACK';
    if (goal.daysRemaining < 0) return 'SHORTFALL';
    if (goal.daysRemaining <= 45) return 'AT RISK';
    return 'ON TRACK';
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)} L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)} K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  double _monthlyRequired() {
    if (goal.isCompleted) return 0.0;
    final months = (goal.daysRemaining / 30.4).ceil();
    if (months <= 0) return goal.remainingAmount;
    return goal.remainingAmount / months;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor();
    final statusText = _statusLabel();
    final monthlyReq = _monthlyRequired();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.space12),
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x060F172A),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Name + Priority + Status
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.supporting,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _categoryIcon(goal.category),
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _priorityTag(goal.priority, isDark),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${_formatDate(goal.targetDate)} • ${goal.category.displayName}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space14),

            // Progress Bar
            GoalProgressBar(fraction: goal.progressFraction),
            const SizedBox(height: AppDimensions.space10),

            // Saved vs Target Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metricItem(
                  label: 'Saved',
                  value: _formatAmount(goal.currentAmount),
                  isDark: isDark,
                ),
                _metricItem(
                  label: 'Remaining',
                  value: goal.isCompleted ? 'Achieved' : _formatAmount(goal.remainingAmount),
                  isDark: isDark,
                ),
                _metricItem(
                  label: 'Target',
                  value: _formatAmount(goal.targetAmount),
                  isDark: isDark,
                  alignRight: true,
                ),
              ],
            ),

            if (!goal.isCompleted && monthlyReq > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Required',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_formatAmount(monthlyReq)} / mo',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _priorityTag(GoalPriority priority, bool isDark) {
    Color color;
    switch (priority) {
      case GoalPriority.essential:
        color = AppColors.error;
        break;
      case GoalPriority.important:
        color = AppColors.warning;
        break;
      case GoalPriority.flexible:
        color = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _metricItem({
    required String label,
    required String value,
    required bool isDark,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
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

  IconData _categoryIcon(GoalCategory category) {
    switch (category) {
      case GoalCategory.emergencyFund:
        return Icons.shield_outlined;
      case GoalCategory.home:
        return Icons.home_outlined;
      case GoalCategory.vehicle:
        return Icons.directions_car_outlined;
      case GoalCategory.travel:
        return Icons.flight_outlined;
      case GoalCategory.education:
        return Icons.school_outlined;
      case GoalCategory.investment:
        return Icons.trending_up_outlined;
      case GoalCategory.personal:
        return Icons.favorite_border_rounded;
      case GoalCategory.other:
        return Icons.flag_outlined;
    }
  }
}
