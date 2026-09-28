import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Progress header showing current step index, progress bar, and clickable step tabs.
class OnboardingProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final ValueChanged<int> onStepTapped;

  const OnboardingProgressHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    required this.onStepTapped,
  });

  static const List<_StepInfo> _steps = [
    _StepInfo(title: 'About You', icon: Icons.person_outline_rounded),
    _StepInfo(title: 'Income', icon: Icons.trending_up_rounded),
    _StepInfo(title: 'Position', icon: Icons.account_balance_wallet_outlined),
    _StepInfo(title: 'Review', icon: Icons.checklist_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (currentStep + 1) / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Step counter & percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF8B5CF6).withAlpha(40)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF8B5CF6).withAlpha(90)
                      : const Color(0xFFC7D2FE),
                ),
              ),
              child: Text(
                'STEP ${currentStep + 1} OF $totalSteps',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF4F46E5),
                ),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}% completed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space10),

        // Animated linear progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 6,
                color: isDark
                    ? AppColors.navyBorder
                    : const Color(0xFFE2E8F0),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF5A58EE),
                        Color(0xFF835CF6),
                        Color(0xFFA855F7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Step tabs
        Row(
          children: [
            for (int i = 0; i < totalSteps; i++) ...[
              Expanded(
                child: _buildStepTab(
                  index: i,
                  step: _steps[i],
                  isDark: isDark,
                ),
              ),
              if (i < totalSteps - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.navyBorder
                        : const Color(0xFFCBD5E1),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStepTab({
    required int index,
    required _StepInfo step,
    required bool isDark,
  }) {
    final isActive = index == currentStep;
    final isDone = index < currentStep;

    Color fgColor;
    Color bgColor;
    BorderSide border;

    if (isActive) {
      fgColor = Colors.white;
      bgColor = const Color(0xFF6366F1);
      border = BorderSide.none;
    } else if (isDone) {
      fgColor = const Color(0xFF10B981);
      bgColor = isDark ? const Color(0xFF064E3B).withAlpha(80) : const Color(0xFFECFDF5);
      border = BorderSide(color: const Color(0xFF10B981).withAlpha(90));
    } else {
      fgColor = isDark
          ? AppColors.textTertiaryDark
          : AppColors.textTertiaryLight;
      bgColor = isDark
          ? AppColors.darkSurfaceVariant.withAlpha(120)
          : AppColors.lightSurfaceVariant.withAlpha(120);
      border = BorderSide(
        color: isDark ? AppColors.navyBorder : const Color(0xFFE2E8F0),
      );
    }

    return InkWell(
      onTap: isDone ? () => onStepTapped(index) : null,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.fromBorderSide(border),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : step.icon,
              size: 16,
              color: fgColor,
            ),
            const SizedBox(height: 2),
            Text(
              step.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepInfo {
  final String title;
  final IconData icon;

  const _StepInfo({required this.title, required this.icon});
}
