/// Models for deterministic "What If" financial projections.
class WhatIfScenarioModel {
  final String id;
  final String title;
  final String subtitle;
  final double monthlyDelta; // adjustment to monthly savings
  final double monthlySavings;
  final double projected1YrSavings;
  final double projected3YrSavings;
  final double emergencyFundMonthsIn1Yr;
  final String goalImpactText;
  final String tag;

  const WhatIfScenarioModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.monthlyDelta,
    required this.monthlySavings,
    required this.projected1YrSavings,
    required this.projected3YrSavings,
    required this.emergencyFundMonthsIn1Yr,
    required this.goalImpactText,
    required this.tag,
  });

  static List<WhatIfScenarioModel> generateScenarios({
    required double currentMonthlySavings,
    required double currentTotalSavings,
    required double essentialExpenses,
    required double primaryGoalRemaining,
    required int primaryGoalMonths,
  }) {
    final baseSavings = currentMonthlySavings > 0 ? currentMonthlySavings : 0.0;

    // Helper for projected savings timeline for primary goal
    String goalTimeline(double rate) {
      if (primaryGoalRemaining <= 0) return 'Primary goal already funded.';
      if (rate <= 0) return 'Savings surplus needed to fund active goals.';
      final months = (primaryGoalRemaining / rate).ceil();
      if (primaryGoalMonths > 0) {
        final diff = primaryGoalMonths - months;
        if (diff > 0) {
          return 'Achieve primary goal $diff months earlier (in ~$months months).';
        } else if (diff < 0) {
          return 'Primary goal projected in ~$months months (~${-diff} months beyond target).';
        }
      }
      return 'Target reached in ~$months months with consistent contributions.';
    }

    double calcEmergencyMonths(double totalSav) {
      if (essentialExpenses <= 0) return totalSav > 0 ? 12.0 : 0.0;
      return (totalSav / essentialExpenses);
    }

    // Scenario A: Current Trend
    final rateA = baseSavings;
    final savA1 = currentTotalSavings + (rateA * 12);
    final savA3 = currentTotalSavings + (rateA * 36);

    // Scenario B: Higher Saving (+₹2,000/mo)
    final rateB = baseSavings + 2000.0;
    final savB1 = currentTotalSavings + (rateB * 12);
    final savB3 = currentTotalSavings + (rateB * 36);

    // Scenario C: Reduce Discretionary (-₹1,500/mo spending -> +₹1,500 saving)
    final rateC = baseSavings + 1500.0;
    final savC1 = currentTotalSavings + (rateC * 12);
    final savC3 = currentTotalSavings + (rateC * 36);

    // Scenario D: Additional Income (+₹5,000/mo)
    final rateD = baseSavings + 5000.0;
    final savD1 = currentTotalSavings + (rateD * 12);
    final savD3 = currentTotalSavings + (rateD * 36);

    return [
      WhatIfScenarioModel(
        id: 'scenario_current',
        title: 'Current Trend',
        subtitle: 'Continue saving ₹${rateA.toStringAsFixed(0)}/month',
        monthlyDelta: 0.0,
        monthlySavings: rateA,
        projected1YrSavings: savA1,
        projected3YrSavings: savA3,
        emergencyFundMonthsIn1Yr: calcEmergencyMonths(savA1),
        goalImpactText: goalTimeline(rateA),
        tag: 'BASELINE',
      ),
      WhatIfScenarioModel(
        id: 'scenario_boost',
        title: 'Boost Savings by ₹2,000/mo',
        subtitle: 'Save an extra ₹2,000 each month',
        monthlyDelta: 2000.0,
        monthlySavings: rateB,
        projected1YrSavings: savB1,
        projected3YrSavings: savB3,
        emergencyFundMonthsIn1Yr: calcEmergencyMonths(savB1),
        goalImpactText: goalTimeline(rateB),
        tag: 'ACCELERATOR',
      ),
      WhatIfScenarioModel(
        id: 'scenario_trim',
        title: 'Trim Discretionary by ₹1,500/mo',
        subtitle: 'Cut non-essential expenses by ₹1,500',
        monthlyDelta: 1500.0,
        monthlySavings: rateC,
        projected1YrSavings: savC1,
        projected3YrSavings: savC3,
        emergencyFundMonthsIn1Yr: calcEmergencyMonths(savC1),
        goalImpactText: goalTimeline(rateC),
        tag: 'OPTIMIZATION',
      ),
      WhatIfScenarioModel(
        id: 'scenario_income',
        title: 'Side Income (+₹5,000/mo)',
        subtitle: 'Freelance, bonus or side project',
        monthlyDelta: 5000.0,
        monthlySavings: rateD,
        projected1YrSavings: savD1,
        projected3YrSavings: savD3,
        emergencyFundMonthsIn1Yr: calcEmergencyMonths(savD1),
        goalImpactText: goalTimeline(rateD),
        tag: 'GROWTH',
      ),
    ];
  }
}
