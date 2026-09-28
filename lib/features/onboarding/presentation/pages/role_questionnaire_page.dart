import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'financial_onboarding_page.dart';

/// Thin wrapper around [FinancialOnboardingPage] that passes the pre-selected
/// [role] so the profile is saved with the correct financial role.
///
/// This is navigated to AFTER role selection and BEFORE the dashboard.
class RoleQuestionnairePage extends StatelessWidget {
  final String role;

  const RoleQuestionnairePage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return FinancialOnboardingPage(initialRole: role);
  }
}

/// Role-display helper used by widgets to show role label + color.
class RoleDisplay {
  static const Map<String, RoleInfo> _map = {
    'student': RoleInfo('Student', '🎓', Color(0xFF38BDF8)),
    'working_single': RoleInfo(
        'Working Professional', '💼', AppColors.electricCyan),
    'working_married': RoleInfo('Family', '👨‍👩‍👧', AppColors.mint),
  };

  static RoleInfo of(String role) =>
      _map[role] ??
      const RoleInfo('Professional', '💼', AppColors.electricCyan);
}

class RoleInfo {
  final String label;
  final String emoji;
  final Color color;

  const RoleInfo(this.label, this.emoji, this.color);
}
