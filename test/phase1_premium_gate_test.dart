import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalsync/features/monetization/services/subscription_service.dart';
import 'package:goalsync/features/monetization/presentation/widgets/premium_gate.dart';
import 'package:goalsync/features/monetization/presentation/pages/premium_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SubscriptionService.resetForTesting();
    await SubscriptionService.instance.init();
    await SubscriptionService.instance.cancelSubscription();
  });

  group('Phase 1: Flutter Premium Gate & Subscription Tests', () {
    testWidgets('PremiumGate blocks free user and renders upgrade banner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumGate(
              featureName: 'Advanced Market Simulator',
              child: Text('SECRET_PREMIUM_CONTENT'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Free user must NOT see the child content
      expect(find.text('SECRET_PREMIUM_CONTENT'), findsNothing);
      expect(find.text('Advanced Market Simulator'), findsOneWidget);
      expect(find.text('Explore Plans (Demo / 14-Day Trial)'), findsOneWidget);
    });

    testWidgets('PremiumGate unlocks and displays child when user is premium', (tester) async {
      await SubscriptionService.instance.activateDemoPremium(planCode: 'premium_monthly');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumGate(
              featureName: 'Advanced Market Simulator',
              child: Text('SECRET_PREMIUM_CONTENT'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Premium user sees child content
      expect(find.text('SECRET_PREMIUM_CONTENT'), findsOneWidget);
      expect(find.text('Explore Plans (Demo / 14-Day Trial)'), findsNothing);
    });

    testWidgets('PremiumPage renders plan options, billing switcher, and demo labeling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PremiumPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Premium Plans'), findsOneWidget);
      expect(find.text('Monthly Billing'), findsOneWidget);
      expect(find.text('Annual Billing'), findsOneWidget);
      expect(find.text('Individual Pro'), findsOneWidget);
      expect(find.text('Student Plan'), findsOneWidget);
      expect(find.text('Family Plan'), findsOneWidget);
      expect(find.text('DEMO / PROJECTED PLAN'), findsOneWidget);
      expect(find.text('Start 14-Day Trial'), findsOneWidget);
      expect(find.text('Activate Demo Plan'), findsOneWidget);
    });
  });
}
