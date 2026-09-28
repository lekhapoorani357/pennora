import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Visual breakdown of expense categories using proportional bars.
class ExpenseBreakdownChart extends StatefulWidget {
  final double fixedExpenses;
  final double variableExpenses;
  final double loanEmi;
  final bool isDark;

  const ExpenseBreakdownChart({
    super.key,
    required this.fixedExpenses,
    required this.variableExpenses,
    required this.loanEmi,
    required this.isDark,
  });

  @override
  State<ExpenseBreakdownChart> createState() => _ExpenseBreakdownChartState();
}

class _ExpenseBreakdownChartState extends State<ExpenseBreakdownChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const Color fixedColor = Color(0xFF3B82F6);
  static const Color variableColor = Color(0xFFF59E0B);
  static const Color loanColor = Color(0xFFF43F5E);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total =
        widget.fixedExpenses + widget.variableExpenses + widget.loanEmi;

    if (total <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
        child: Text(
          'No expense data recorded.',
          style: TextStyle(
            fontSize: 13,
            color: widget.isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    final fixedFrac = widget.fixedExpenses / total;
    final varFrac = widget.variableExpenses / total;
    final loanFrac = widget.loanEmi / total;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animated = _animation.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    if (fixedFrac > 0)
                      Flexible(
                        flex: (fixedFrac * animated * 1000).round().clamp(1, 100000),
                        child: Container(color: fixedColor),
                      ),
                    if (varFrac > 0)
                      Flexible(
                        flex: (varFrac * animated * 1000).round().clamp(1, 100000),
                        child: Container(color: variableColor),
                      ),
                    if (loanFrac > 0)
                      Flexible(
                        flex: (loanFrac * animated * 1000).round().clamp(1, 100000),
                        child: Container(color: loanColor),
                      ),
                    if (animated < 1.0)
                      Flexible(
                        flex: ((1 - animated) * 1000).round().clamp(1, 100000),
                        child: Container(
                          color: widget.isDark
                              ? AppColors.navyMid
                              : const Color(0xFFF1F5F9),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendItem(
                  color: fixedColor,
                  label: 'Fixed (${(fixedFrac * 100).toStringAsFixed(0)}%)',
                ),
                _LegendItem(
                  color: variableColor,
                  label: 'Variable (${(varFrac * 100).toStringAsFixed(0)}%)',
                ),
                _LegendItem(
                  color: loanColor,
                  label: 'Loan/EMI (${(loanFrac * 100).toStringAsFixed(0)}%)',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
