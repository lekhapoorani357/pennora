import 'package:flutter_test/flutter_test.dart';
import 'package:goalsync/features/investment/services/investment_service.dart';

void main() {
  group('InvestmentClientService Unit & Fallback Tests', () {
    test('fetchEligibleOptions returns real-time verified investment options', () async {
      final options = await InvestmentClientService.instance.fetchEligibleOptions();
      expect(options, isNotEmpty);
      expect(options.length, greaterThanOrEqualTo(5));

      final productNames = options.map((o) => o.productName).toList();
      expect(productNames.any((n) => n.contains('SBI') || n.contains('Fixed Deposit')), isTrue);
      expect(productNames.any((n) => n.contains('Treasury Bill') || n.contains('T-Bill')), isTrue);
      expect(productNames.any((n) => n.contains('Public Provident Fund') || n.contains('PPF')), isTrue);
      expect(productNames.any((n) => n.contains('Nifty')), isTrue);

      for (final opt in options) {
        expect(opt.source, isNotEmpty);
        expect(opt.rateOrNavText, isNotEmpty);
        expect(opt.whyItMatches, isNotEmpty);
        expect(opt.risksAndLimitations, isNotEmpty);
      }
    });

    test('askCopilot answers monthly investment / SIP questions correctly', () async {
      final res = await InvestmentClientService.instance.askCopilot(
        message: 'What if I invest ₹5,000 monthly?',
        principal: 50000,
        monthlyContribution: 5000,
        durationYears: 5,
      );

      expect(res, isNotNull);
      final reply = res!['reply'] as String;
      expect(reply, isNotEmpty);
      expect(reply.contains('Invested') || reply.contains('Total Invested'), isTrue);
      expect(reply.contains('Projected') || reply.contains('Growth') || reply.contains('SBI'), isTrue);
    });

    test('askCopilot explains why matching options were shown', () async {
      final res = await InvestmentClientService.instance.askCopilot(
        message: 'Why did you show this option?',
      );

      expect(res, isNotNull);
      final reply = res!['reply'] as String;
      expect(reply, isNotEmpty);
      expect(reply.contains('deterministic') || reply.contains('verified') || reply.contains('Capital') || reply.contains('Why'), isTrue);
    });

    test('askCopilot answers lower risk comparison queries', () async {
      final res = await InvestmentClientService.instance.askCopilot(
        message: 'Which option has lower risk?',
      );

      expect(res, isNotNull);
      final reply = res!['reply'] as String;
      expect(reply, isNotEmpty);
      expect(reply.toLowerCase().contains('risk') || reply.toLowerCase().contains('lowest'), isTrue);
      expect(reply.contains('Treasury') || reply.contains('T-Bill') || reply.contains('FD') || reply.contains('PPF'), isTrue);
    });

    test('askCopilot answers what-if surplus changes', () async {
      final res = await InvestmentClientService.instance.askCopilot(
        message: 'What if my surplus decreases by ₹2,000?',
        whatIfMonthlyDelta: -2000,
      );

      expect(res, isNotNull);
      final reply = res!['reply'] as String;
      expect(reply, isNotEmpty);
      expect(reply.contains('surplus') || reply.contains('Surplus'), isTrue);
      expect(reply.contains('2,000') || reply.contains('2000'), isTrue);
    });

    test('askCopilot answers general financial guidance questions without failing', () async {
      final res = await InvestmentClientService.instance.askCopilot(
        message: 'How should I allocate my savings between FD and index funds?',
      );

      expect(res, isNotNull);
      final reply = res!['reply'] as String;
      expect(reply, isNotEmpty);
      expect(reply.length, greaterThan(30));
    });
  });
}
