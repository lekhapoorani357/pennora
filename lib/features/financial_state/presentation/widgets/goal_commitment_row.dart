import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../goals/models/goal_model.dart';
import '../../../goals/presentation/widgets/goal_progress_bar.dart';

/// Compact row showing a goal commitment inside Financial State page.
class GoalCommitmentRow extends StatelessWidget {
  final GoalModel goal;
  final bool isDark;

  const GoalCommitmentRow({super.key, required this.goal, required this.isDark});

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  letterSpacing: -0.2,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF8B5CF6).withAlpha(40)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF8B5CF6).withAlpha(80)
                      : const Color(0xFFC7D2FE),
                ),
              ),
              child: Text(
                goal.category.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space10),
        Row(
          children: [
            _AmountPill(
              label: 'Target',
              value: _fmt(goal.targetAmount),
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _AmountPill(
              label: 'Saved',
              value: _fmt(goal.currentAmount),
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _AmountPill(
              label: 'Remaining',
              value: _fmt(goal.remainingAmount),
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space10),
        GoalProgressBar(fraction: goal.progressFraction),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target: ${_formatDate(goal.targetDate)}',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            Text(
              goal.progressPercentage,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: goal.isCompleted
                    ? const Color(0xFF10B981)
                    : const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmountPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _AmountPill({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(isDark ? 60 : 40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
