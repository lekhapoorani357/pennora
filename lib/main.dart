import 'package:flutter/material.dart';
import 'core/core.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/auth/services/auth_service.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/onboarding/presentation/pages/role_questionnaire_page.dart';
import 'features/onboarding/presentation/pages/role_selection_page.dart';
import 'features/onboarding/services/financial_profile_service.dart';
import 'features/monetization/services/subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  // Pre-init profile service so role detection works synchronously at startup
  await FinancialProfileService.instance.init();
  await SubscriptionService.instance.init();
  runApp(const PennoraApp());
}

/// Root application widget for Pennora.
///
/// Wires the centralized [AppTheme] into [MaterialApp], supports Light/Dark/System
/// modes, and automatically routes based on authentication state:
/// - Unauthenticated  -> [WelcomePage]
/// - Authenticated, no role set -> [RoleSelectionPage]
/// - Authenticated, role + onboarding done -> [DashboardPage]
///
/// Financial Onboarding (including role questionnaire) is accessed after login.
class PennoraApp extends StatelessWidget {
  final Widget? home;

  const PennoraApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    final Widget initialScreen = _resolveInitialScreen();

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ── Root ───────────────────────────────────────────────
      home: home ?? initialScreen,
    );
  }

  Widget _resolveInitialScreen() {
    if (!AuthService.instance.isLoggedIn) {
      return const WelcomePage();
    }

    final userId = AuthService.instance.currentUser?.id ?? '';
    final profileService = FinancialProfileService.instance;

    final isOnboarded = profileService.isOnboardingCompleted(userId);
    final hasExplicitRole = profileService.hasExplicitRole(userId);

    // If onboarding is not completed, route through role selection / questionnaire
    if (!isOnboarded) {
      if (!hasExplicitRole) {
        return const RoleSelectionPage();
      }
      final role = profileService.getRole(userId);
      return RoleQuestionnairePage(role: role);
    }

    return const DashboardPage();
  }
}

/// Backwards compatibility alias for tests and existing references
typedef GoalSyncApp = PennoraApp;
