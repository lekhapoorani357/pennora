import '../../constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Represents one of the 5 Financial Growth Levels in Pennora/GoalSync.
class FinancialLevelModel {
  final int level; // 1 to 5
  final String title;
  final String badge;
  final String description;
  final List<String> focusAreas;
  final List<String> reasons;
  final List<String> nextLevelRequirements;
  final double score; // 0 to 100
  final Color accentColor;

  const FinancialLevelModel({
    required this.level,
    required this.title,
    required this.badge,
    required this.description,
    required this.focusAreas,
    required this.reasons,
    required this.nextLevelRequirements,
    required this.score,
    required this.accentColor,
  });

  static FinancialLevelModel calculate({
    required double monthlyIncome,
    required double totalExpenses,
    required double savings,
    required double monthlyLoanEmi,
    required int activeGoals,
    required bool hasGoalConflicts,
  }) {
    final double essential = totalExpenses * 0.7; // estimated essential floor
    final double surplus = monthlyIncome - totalExpenses;
    final double savingsRate = monthlyIncome > 0 ? (surplus / monthlyIncome) * 100.0 : 0.0;
    final double emergencyMonths = essential > 0 ? (savings / essential) : (savings > 0 ? 6.0 : 0.0);
    final double debtRatio = monthlyIncome > 0 ? (monthlyLoanEmi / monthlyIncome) : 0.0;

    // Deterministic factor evaluation
    int level = 1;
    final List<String> reasons = [];
    final List<String> nextReqs = [];
    double score = 20.0;

    if (monthlyIncome <= 0 || surplus <= 0 || emergencyMonths < 1.0) {
      level = 1;
      score = (emergencyMonths * 15.0).clamp(10.0, 35.0);
      reasons.add(surplus <= 0 ? 'Monthly outflow matches or exceeds incoming cashflow.' : 'Savings buffer covers less than 1 month of essential expenses.');
      reasons.add('Primary priority is establishing baseline liquidity and controlling core living costs.');
      nextReqs.add('Build an emergency cash buffer equal to at least 1-2 months of living costs.');
      nextReqs.add('Reduce non-essential monthly expenditures to establish a positive savings margin.');
    } else if (savingsRate < 15.0 || emergencyMonths < 3.0 || debtRatio > 0.45) {
      level = 2;
      score = 40.0 + (savingsRate * 0.8).clamp(0.0, 15.0);
      reasons.add('Income exceeds essential expenses with active savings of ${savingsRate.toStringAsFixed(1)}%.');
      reasons.add('Emergency reserve covers ${emergencyMonths.toStringAsFixed(1)} months of essential living expenses.');
      if (debtRatio > 0.35) {
        reasons.add('Debt repayment accounts for ${(debtRatio * 100).toStringAsFixed(0)}% of monthly earnings.');
      }
      nextReqs.add('Expand emergency fund to 3-6 full months of essential living expenses.');
      nextReqs.add('Target a regular savings rate of 15% to 20% of monthly income.');
      nextReqs.add('Eliminate high-cost revolving debt and maintain uncommitted surplus.');
    } else if (savingsRate < 25.0 || emergencyMonths < 6.0 || hasGoalConflicts) {
      level = 3;
      score = 60.0 + (savingsRate * 0.6).clamp(0.0, 15.0);
      reasons.add('Controlled spending pattern with healthy savings rate of ${savingsRate.toStringAsFixed(1)}%.');
      reasons.add('Emergency cushion covers ${emergencyMonths.toStringAsFixed(1)} months of obligations.');
      if (hasGoalConflicts) {
        reasons.add('Active goal target timelines compete for available monthly surplus.');
      }
      nextReqs.add('Resolve goal timeline conflicts by adjusting priorities or extending deadlines.');
      nextReqs.add('Build emergency reserve to 6 full months of living costs.');
      nextReqs.add('Begin exploring capital preservation and low-risk growth vehicles.');
    } else if (savingsRate < 35.0 || emergencyMonths < 9.0) {
      level = 4;
      score = 80.0 + (savingsRate * 0.3).clamp(0.0, 10.0);
      reasons.add('Strong savings capacity of ${savingsRate.toStringAsFixed(1)}% of total monthly income.');
      reasons.add('Substantial emergency reserve covering ${emergencyMonths.toStringAsFixed(1)} months.');
      reasons.add('Active financial goals are progressing without critical surplus deficits.');
      nextReqs.add('Diversify assets across disciplined fixed and market-linked instruments.');
      nextReqs.add('Establish structured protection with adequate term and health insurance.');
      nextReqs.add('Sustain a 30%+ savings rate over a rolling 12-month period.');
    } else {
      level = 5;
      score = 95.0;
      reasons.add('Advanced financial resilience with exceptional savings rate (${savingsRate.toStringAsFixed(1)}%).');
      reasons.add('Comprehensive safety cushion spanning ${emergencyMonths.toStringAsFixed(1)} months.');
      reasons.add('Low debt burden (${(debtRatio * 100).toStringAsFixed(0)}%) and mature multi-goal trajectory.');
      nextReqs.add('Review long-term wealth compounding and retirement replacement ratios.');
      nextReqs.add('Regularly balance asset allocation against macroeconomic risk shifts.');
    }

    switch (level) {
      case 1:
        return FinancialLevelModel(
          level: 1,
          title: 'Level 1 — Foundation',
          badge: 'Foundation',
          description: 'Stable basic financial position. Focus on establishing core cash buffers and controlling recurring essentials.',
          focusAreas: ['Essential living expenses', 'Basic savings discipline', 'Initial emergency buffer'],
          reasons: reasons,
          nextLevelRequirements: nextReqs,
          score: score,
          accentColor: const Color(0xFFF59E0B), // Amber
        );
      case 2:
        return FinancialLevelModel(
          level: 2,
          title: 'Level 2 — Stable',
          badge: 'Stable',
          description: 'Income and spending are controlled. Positive surplus generated reliably each month.',
          focusAreas: ['Consistent monthly savings', 'Discretionary cost reduction', 'Emergency fund progress'],
          reasons: reasons,
          nextLevelRequirements: nextReqs,
          score: score,
          accentColor: const Color(0xFF38BDF8), // Sky blue
        );
      case 3:
        return FinancialLevelModel(
          level: 3,
          title: 'Level 3 — Growing',
          badge: 'Growing',
          description: 'Stable savings plus active goal contributions and initial growth exploration.',
          focusAreas: ['Goal acceleration', 'Medium-term savings vehicles', 'Goal conflict resolution'],
          reasons: reasons,
          nextLevelRequirements: nextReqs,
          score: score,
          accentColor: AppColors.mint, // Mint green
        );
      case 4:
        return FinancialLevelModel(
          level: 4,
          title: 'Level 4 — Strong',
          badge: 'Strong',
          description: 'Goals are progressing consistently with high resilience and disciplined surplus allocation.',
          focusAreas: ['Higher savings capacity', 'Asset diversification', 'Long-term wealth planning'],
          reasons: reasons,
          nextLevelRequirements: nextReqs,
          score: score,
          accentColor: AppColors.electricCyan, // Electric cyan
        );
      case 5:
      default:
        return FinancialLevelModel(
          level: 5,
          title: 'Level 5 — Advanced',
          badge: 'Advanced',
          description: 'Comprehensive financial resilience, multiple automated goals, and long-term asset growth.',
          focusAreas: ['Multi-goal coordination', 'Long-term investments', 'Retirement readiness', 'Estate protection'],
          reasons: reasons,
          nextLevelRequirements: nextReqs,
          score: score,
          accentColor: const Color(0xFFA855F7), // Purple
        );
    }
  }
}
