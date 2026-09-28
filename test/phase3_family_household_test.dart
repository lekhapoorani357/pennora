import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalsync/features/monetization/presentation/pages/family_household_page.dart';
import 'package:goalsync/features/monetization/services/household_service.dart';
import 'package:goalsync/features/monetization/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    HouseholdService.resetForTesting();
    SubscriptionService.resetForTesting();
    await SubscriptionService.instance.init();
    await SubscriptionService.instance.cancelSubscription();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: FamilyHouseholdPage(),
    );
  }

  testWidgets('FamilyHouseholdPage renders Privacy Guarantee banner and empty state when no household',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Privacy Guarantee banner is visible
    expect(find.text('Strict Privacy Guarantee'), findsOneWidget);
    expect(
      find.textContaining('personal accounts, bank sync, transactions, and goals remain completely private'),
      findsOneWidget,
    );

    // Verify empty state when no household exists
    expect(find.text('No Active Family Household'), findsOneWidget);
    expect(find.text('View Family Plans'), findsOneWidget);
  });

  testWidgets('FamilyHouseholdPage shows Create Household button when user has Family subscription',
      (WidgetTester tester) async {
    // Activate family demo plan
    await SubscriptionService.instance.activateDemoPremium(planCode: 'family_monthly');

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Create Household'), findsOneWidget);
  });
}
