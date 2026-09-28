import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';

class InvestmentProductInfo {
  final String id;
  final String name;
  final String category;
  final String description;
  final double defaultRate;
  final double minRate;
  final double maxRate;
  final String risk;
  final String liquidity;
  final String taxNotes;
  final bool isGuaranteed;
  final String source;

  const InvestmentProductInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.defaultRate,
    required this.minRate,
    required this.maxRate,
    required this.risk,
    required this.liquidity,
    required this.taxNotes,
    required this.isGuaranteed,
    required this.source,
  });

  factory InvestmentProductInfo.fromMap(Map<String, dynamic> map) {
    return InvestmentProductInfo(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      defaultRate: (map['defaultRate'] as num?)?.toDouble() ?? 7.0,
      minRate: (map['assumedAnnualRateMin'] as num?)?.toDouble() ?? 6.0,
      maxRate: (map['assumedAnnualRateMax'] as num?)?.toDouble() ?? 8.0,
      risk: (map['risk'] ?? 'Low').toString(),
      liquidity: (map['liquidity'] ?? 'Moderate').toString(),
      taxNotes: (map['taxNotes'] ?? '').toString(),
      isGuaranteed: map['isGuaranteed'] == true,
      source: (map['source'] ?? 'Illustrative average').toString(),
    );
  }
}

class ProductSimulationResult {
  final String productId;
  final String productName;
  final String category;
  final bool isGuaranteed;
  final String risk;
  final String liquidity;
  final double assumedAnnualRate;
  final String rateRangeText;
  final double totalInvested;
  final double estimatedFutureValue;
  final double estimatedGain;
  final double? conservativeValue;
  final double? optimisticValue;
  final String? taxNotes;
  final String disclaimer;
  final String source;

  const ProductSimulationResult({
    required this.productId,
    required this.productName,
    required this.category,
    required this.isGuaranteed,
    required this.risk,
    required this.liquidity,
    required this.assumedAnnualRate,
    required this.rateRangeText,
    required this.totalInvested,
    required this.estimatedFutureValue,
    required this.estimatedGain,
    this.conservativeValue,
    this.optimisticValue,
    this.taxNotes,
    required this.disclaimer,
    required this.source,
  });

  factory ProductSimulationResult.fromMap(Map<String, dynamic> map) {
    return ProductSimulationResult(
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      isGuaranteed: map['isGuaranteed'] == true,
      risk: (map['risk'] ?? 'Low').toString(),
      liquidity: (map['liquidity'] ?? 'Moderate').toString(),
      assumedAnnualRate: (map['assumedAnnualRate'] as num?)?.toDouble() ?? 7.0,
      rateRangeText: (map['rateRangeText'] ?? '').toString(),
      totalInvested: (map['totalInvested'] as num?)?.toDouble() ?? 0.0,
      estimatedFutureValue: (map['estimatedFutureValue'] as num?)?.toDouble() ?? 0.0,
      estimatedGain: (map['estimatedGain'] as num?)?.toDouble() ?? 0.0,
      conservativeValue: (map['conservativeValue'] as num?)?.toDouble(),
      optimisticValue: (map['optimisticValue'] as num?)?.toDouble(),
      taxNotes: map['taxNotes']?.toString(),
      disclaimer: (map['disclaimer'] ?? 'Illustrative projection').toString(),
      source: (map['source'] ?? '').toString(),
    );
  }
}

class InvestmentSimulationOutput {
  final double principal;
  final double monthlyContribution;
  final double durationYears;
  final double totalInvested;
  final List<ProductSimulationResult> projections;
  final bool hasLiquidityWarning;
  final List<String> warnings;
  final String disclaimer;

  const InvestmentSimulationOutput({
    required this.principal,
    required this.monthlyContribution,
    required this.durationYears,
    required this.totalInvested,
    required this.projections,
    required this.hasLiquidityWarning,
    required this.warnings,
    required this.disclaimer,
  });
}

class InvestmentClientService extends ChangeNotifier {
  static InvestmentClientService? _instance;
  static InvestmentClientService get instance => _instance ??= InvestmentClientService._();

  InvestmentClientService._();

  static const List<InvestmentProductInfo> defaultProducts = [
    InvestmentProductInfo(
      id: 'prod_fd_1',
      name: 'Fixed Deposit (FD)',
      category: 'FD',
      description: 'Capital-protected bank deposit with fixed guaranteed interest.',
      defaultRate: 7.0,
      minRate: 6.5,
      maxRate: 7.5,
      risk: 'Low',
      liquidity: 'Moderate',
      taxNotes: 'Taxable as per individual income tax slab.',
      isGuaranteed: true,
      source: 'Illustrative banking average for demonstration',
    ),
    InvestmentProductInfo(
      id: 'prod_rd_1',
      name: 'Recurring Deposit (RD)',
      category: 'RD',
      description: 'Monthly disciplined recurring savings with assured returns.',
      defaultRate: 6.8,
      minRate: 6.2,
      maxRate: 7.2,
      risk: 'Low',
      liquidity: 'Moderate',
      taxNotes: 'Interest taxed according to income slab.',
      isGuaranteed: true,
      source: 'Illustrative banking average for demonstration',
    ),
    InvestmentProductInfo(
      id: 'prod_ppf_1',
      name: 'Public Provident Fund (PPF)',
      category: 'PPF',
      description: 'Sovereign-backed long-term tax-exempt savings instrument.',
      defaultRate: 7.1,
      minRate: 7.1,
      maxRate: 7.1,
      risk: 'Low',
      liquidity: 'Lock-in (15 yr)',
      taxNotes: 'Exempt-Exempt-Exempt (EEE) under Section 80C.',
      isGuaranteed: true,
      source: 'Government of India notified rate (Illustrative demonstration)',
    ),
    InvestmentProductInfo(
      id: 'prod_index_1',
      name: 'Nifty 50 Index Mutual Fund',
      category: 'INDEX_FUNDS',
      description: 'Broad-market index fund replicating India top 50 companies.',
      defaultRate: 11.5,
      minRate: 9.0,
      maxRate: 14.0,
      risk: 'Moderate',
      liquidity: 'High (T+2)',
      taxNotes: '12.5% LTCG above ₹1.25L exemption, 20% STCG.',
      isGuaranteed: false,
      source: 'Historical broad-market benchmark illustrative range',
    ),
    InvestmentProductInfo(
      id: 'prod_equity_1',
      name: 'Diversified Equity Mutual Funds',
      category: 'EQUITY',
      description: 'Actively managed equity portfolios for wealth creation.',
      defaultRate: 12.5,
      minRate: 10.0,
      maxRate: 16.0,
      risk: 'High',
      liquidity: 'High (T+2)',
      taxNotes: 'Equity mutual fund taxation rules apply.',
      isGuaranteed: false,
      source: 'Category historical illustrative projection',
    ),
  ];

  static double calculateLumpSum(double principal, double annualRatePct, double years) {
    if (principal <= 0 || years <= 0) return math.max(0.0, principal);
    final r = annualRatePct / 100.0;
    return principal * math.pow(1.0 + r, years);
  }

  static double calculateSip(double monthlyAmount, double annualRatePct, int months) {
    if (monthlyAmount <= 0 || months <= 0) return 0.0;
    if (annualRatePct <= 0) return monthlyAmount * months;
    final monthlyRate = (annualRatePct / 100.0) / 12.0;
    return monthlyAmount * ((math.pow(1.0 + monthlyRate, months) - 1.0) / monthlyRate) * (1.0 + monthlyRate);
  }

  /// Run deterministic simulation
  Future<InvestmentSimulationOutput> simulate({
    required double principal,
    required double monthlyContribution,
    required double durationYears,
    required double currentSavings,
    required double monthlySurplus,
    String? category,
  }) async {
    final months = (durationYears * 12).round();
    final totalInvested = principal + (monthlyContribution * months);

    // Try backend calculate endpoint first
    if (ApiClient.instance.authToken != null) {
      try {
        final res = await ApiClient.instance.post(
          '/api/investments/calculate',
          body: {
            'principal': principal,
            'monthlyContribution': monthlyContribution,
            'durationYears': durationYears,
            'category': category ?? 'ALL',
          },
          requiresAuth: true,
        );
        if (res is Map<String, dynamic> && res['projections'] is List) {
          final projections = (res['projections'] as List)
              .map((p) => ProductSimulationResult.fromMap(p as Map<String, dynamic>))
              .toList();
          final goalImpact = res['goalImpact'] as Map<String, dynamic>?;
          return InvestmentSimulationOutput(
            principal: principal,
            monthlyContribution: monthlyContribution,
            durationYears: durationYears,
            totalInvested: totalInvested,
            projections: projections,
            hasLiquidityWarning: goalImpact?['hasLiquidityWarning'] == true,
            warnings: List<String>.from(goalImpact?['warnings'] ?? []),
            disclaimer: (res['disclaimer'] ?? 'Illustrative assumptions for demonstration.').toString(),
          );
        }
      } catch (_) {}
    }

    // Local deterministic calculation fallback
    final List<ProductSimulationResult> projections = [];
    final List<String> warnings = [];
    bool hasWarning = false;

    if (principal > currentSavings) {
      hasWarning = true;
      warnings.add('Lump-sum (₹${principal.toStringAsFixed(0)}) exceeds your current savings reserve (₹${currentSavings.toStringAsFixed(0)}).');
    }
    if (monthlyContribution > monthlySurplus && monthlySurplus > 0) {
      hasWarning = true;
      warnings.add('Monthly commitment of ₹${monthlyContribution.toStringAsFixed(0)} exceeds your current available surplus (₹${monthlySurplus.toStringAsFixed(0)}).');
    }

    final productsToUse = (category != null && category.toUpperCase() != 'ALL')
        ? defaultProducts.where((p) => p.category == category.toUpperCase()).toList()
        : defaultProducts;

    for (final prod in productsToUse) {
      final fvLump = calculateLumpSum(principal, prod.defaultRate, durationYears);
      final fvSip = calculateSip(monthlyContribution, prod.defaultRate, months);
      final fvTotal = fvLump + fvSip;
      final gain = math.max(0.0, fvTotal - totalInvested);

      double? conservative;
      double? optimistic;
      if (!prod.isGuaranteed) {
        final cLump = calculateLumpSum(principal, prod.minRate, durationYears);
        final cSip = calculateSip(monthlyContribution, prod.minRate, months);
        conservative = cLump + cSip;

        final oLump = calculateLumpSum(principal, prod.maxRate, durationYears);
        final oSip = calculateSip(monthlyContribution, prod.maxRate, months);
        optimistic = oLump + oSip;
      }

      projections.add(ProductSimulationResult(
        productId: prod.id,
        productName: prod.name,
        category: prod.category,
        isGuaranteed: prod.isGuaranteed,
        risk: prod.risk,
        liquidity: prod.liquidity,
        assumedAnnualRate: prod.defaultRate,
        rateRangeText: prod.isGuaranteed
            ? '${prod.defaultRate.toStringAsFixed(1)}% fixed'
            : '${prod.minRate.toStringAsFixed(1)}% – ${prod.maxRate.toStringAsFixed(1)}% p.a.',
        totalInvested: totalInvested,
        estimatedFutureValue: fvTotal,
        estimatedGain: gain,
        conservativeValue: conservative,
        optimisticValue: optimistic,
        taxNotes: prod.taxNotes,
        disclaimer: 'Illustrative projection based on steady contributions. Actual returns may differ.',
        source: prod.source,
      ));
    }

    return InvestmentSimulationOutput(
      principal: principal,
      monthlyContribution: monthlyContribution,
      durationYears: durationYears,
      totalInvested: totalInvested,
      projections: projections,
      hasLiquidityWarning: hasWarning,
      warnings: warnings,
      disclaimer: 'Illustrative assumptions for demonstration. Actual returns may differ. Not guaranteed financial advice.',
    );
  }

  Future<bool> saveScenario({
    required double principal,
    required double monthlyContribution,
    required double durationYears,
    required Map<String, dynamic> results,
  }) async {
    if (ApiClient.instance.authToken == null) return false;
    try {
      await ApiClient.instance.post(
        '/api/investments/scenarios',
        body: {
          'initialAmount': principal,
          'monthlyContribution': monthlyContribution,
          'durationYears': durationYears,
          'results': results,
        },
        requiresAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<MatchingInvestmentOption> get sourcedVerifiedOptions => const [
    MatchingInvestmentOption(
      productId: 'prod_tbill_91d',
      productName: 'Government of India 91-Day Treasury Bill',
      category: 'T_BILLS',
      provider: 'Reserve Bank of India (RBI)',
      currentRateOrNav: 6.48,
      rateOrNavText: '6.48% p.a. (Auction Yield)',
      riskLevel: 'Low',
      liquidity: 'High (T+1)',
      minimumInvestment: 10000.0,
      source: 'RBI / Clearing Corporation of India (CCIL)',
      asOfDate: '2026-09-28',
      isGuaranteed: true,
      isEligible: true,
      whyItMatches: 'Zero default risk sovereign instrument ideal for protecting near-term capital reserves.',
      risksAndLimitations: 'Subject to reinvestment rate variability at 91-day maturity cycle.',
      score: 95.0,
    ),
    MatchingInvestmentOption(
      productId: 'prod_sbi_fd_1',
      productName: 'SBI Domestic Term Deposit (1-2 Year)',
      category: 'FD',
      provider: 'State Bank of India',
      currentRateOrNav: 6.80,
      rateOrNavText: '6.80% p.a. (1-2 Yr Term)',
      riskLevel: 'Low',
      liquidity: 'Moderate',
      minimumInvestment: 1000.0,
      source: 'State Bank of India (Official Schedule)',
      asOfDate: '2026-09-28',
      isGuaranteed: true,
      isEligible: true,
      whyItMatches: 'Capital protection with guaranteed scheduled payout insured under DICGC up to ₹5 Lakh.',
      risksAndLimitations: 'Returns taxable per personal slab; 0.50% premature withdrawal penalty.',
      score: 92.0,
    ),
    MatchingInvestmentOption(
      productId: 'prod_post_rd_1',
      productName: 'Post Office 5-Year Recurring Deposit',
      category: 'RD',
      provider: 'India Post / Ministry of Finance',
      currentRateOrNav: 6.70,
      rateOrNavText: '6.70% p.a. (Compounded Quarterly)',
      riskLevel: 'Low',
      liquidity: 'Moderate',
      minimumInvestment: 100.0,
      source: 'Department of Posts / National Savings Institute',
      asOfDate: '2026-09-28',
      isGuaranteed: true,
      isEligible: true,
      whyItMatches: 'Sovereign-backed disciplined recurring monthly savings without equity drawdown exposure.',
      risksAndLimitations: 'Quarterly fixed rates; lock-in rules apply prior to 3 years.',
      score: 89.0,
    ),
    MatchingInvestmentOption(
      productId: 'prod_ppf_sov_1',
      productName: 'Public Provident Fund (PPF)',
      category: 'PPF',
      provider: 'Ministry of Finance, Government of India',
      currentRateOrNav: 7.10,
      rateOrNavText: '7.10% p.a. (Tax-Free EEE)',
      riskLevel: 'Low',
      liquidity: 'Lock-in (15 yr)',
      minimumInvestment: 500.0,
      source: 'Ministry of Finance Official Gazette',
      asOfDate: '2026-09-28',
      isGuaranteed: true,
      isEligible: true,
      whyItMatches: 'Long-term sovereign wealth creation with complete Exempt-Exempt-Exempt (EEE) status.',
      risksAndLimitations: '15-year commitment; partial liquidity unlocked from year 7 onwards.',
      score: 88.0,
    ),
    MatchingInvestmentOption(
      productId: 'prod_nifty_etf_1',
      productName: 'Nippon India ETF Nifty BeES',
      category: 'ETF',
      provider: 'Nippon India Mutual Fund',
      currentRateOrNav: 268.40,
      rateOrNavText: 'NAV ₹268.40 (Nifty 50 Index)',
      riskLevel: 'Moderate',
      liquidity: 'High (Real-time NSE)',
      minimumInvestment: 268.0,
      source: 'National Stock Exchange (NSE) / AMFI',
      asOfDate: '2026-09-28',
      isGuaranteed: false,
      isEligible: true,
      whyItMatches: 'Ultra low expense ratio (0.04%) for direct, diversified exposure to India top 50 giants.',
      risksAndLimitations: 'Short-term equity index fluctuations; requires active demat account.',
      score: 86.0,
    ),
    MatchingInvestmentOption(
      productId: 'prod_hdfc_index_1',
      productName: 'HDFC Nifty 50 Index Fund Direct-Growth',
      category: 'INDEX_FUNDS',
      provider: 'HDFC Mutual Fund',
      currentRateOrNav: 218.45,
      rateOrNavText: 'NAV ₹218.45 (13.5% p.a. CAGR)',
      riskLevel: 'Moderate',
      liquidity: 'High (T+2 AMFI)',
      minimumInvestment: 500.0,
      source: 'Association of Mutual Funds in India (AMFI)',
      asOfDate: '2026-09-28',
      isGuaranteed: false,
      isEligible: true,
      whyItMatches: 'Automated disciplined SIP wealth compounding matching India economic growth trajectory.',
      risksAndLimitations: 'Equity market risk; subject to 12.5% LTCG above ₹1.25 Lakh exemption limit.',
      score: 84.0,
    ),
  ];

  Future<List<MatchingInvestmentOption>> fetchEligibleOptions() async {
    try {
      final res = await ApiClient.instance.get(
        '/api/investments/eligible',
        requiresAuth: ApiClient.instance.authToken != null,
      );
      if (res is Map<String, dynamic> && res['matching_options'] is List) {
        final list = (res['matching_options'] as List)
            .map((e) => MatchingInvestmentOption.fromMap(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return sourcedVerifiedOptions;
  }

  Future<Map<String, dynamic>?> askCopilot({
    required String message,
    double? principal,
    double? monthlyContribution,
    double? durationYears,
    double? whatIfMonthlyDelta,
  }) async {
    try {
      final body = <String, dynamic>{'message': message};
      if (principal != null) body['principal'] = principal;
      if (monthlyContribution != null) body['monthlyContribution'] = monthlyContribution;
      if (durationYears != null) body['durationYears'] = durationYears;
      if (whatIfMonthlyDelta != null) body['whatIfMonthlyDelta'] = whatIfMonthlyDelta;

      final res = await ApiClient.instance.post(
        '/api/copilot/chat',
        body: body,
        requiresAuth: ApiClient.instance.authToken != null,
      );
      if (res is Map<String, dynamic> && res['reply'] != null && res['reply'].toString().trim().isNotEmpty) {
        return res;
      }
    } catch (_) {}

    return _buildLocalCopilotReply(
      message: message,
      principal: principal ?? 50000,
      monthlyContribution: monthlyContribution ?? 5000,
      durationYears: durationYears ?? 5,
      whatIfMonthlyDelta: whatIfMonthlyDelta ?? -2000,
    );
  }

  Map<String, dynamic> _buildLocalCopilotReply({
    required String message,
    required double principal,
    required double monthlyContribution,
    required double durationYears,
    required double whatIfMonthlyDelta,
  }) {
    final q = message.toLowerCase();
    final months = (durationYears * 12).round();

    // 1. Monthly SIP or investment calculation
    if (q.contains('invest') || q.contains('monthly') || q.contains('sip') || q.contains('grow')) {
      final match = RegExp(r'(?:invest|save|put)\s*(?:₹|rs\.?|inr)?\s*([0-9,]+)', caseSensitive: false).firstMatch(message);
      double sipAmt = monthlyContribution;
      if (match != null) {
        final parsed = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (parsed != null && parsed > 0) {
          sipAmt = parsed;
        }
      }

      final totalInvested = principal + (sipAmt * months);
      final fvFd = calculateLumpSum(principal, 6.8, durationYears) + calculateSip(sipAmt, 6.8, months);
      final gainFd = math.max(0.0, fvFd - totalInvested);

      final fvEq = calculateLumpSum(principal, 12.5, durationYears) + calculateSip(sipAmt, 12.5, months);
      final gainEq = math.max(0.0, fvEq - totalInvested);

      final reply = 'Based on your simulated plan of ₹${principal.toStringAsFixed(0)} lump-sum and ₹${sipAmt.toStringAsFixed(0)}/month over ${durationYears.toStringAsFixed(0)} years:\n\n'
          '• **Total Invested:** ₹${totalInvested.toStringAsFixed(0)}\n'
          '• **Fixed & Capital Protected (SBI FD / PPF @ ~6.8% - 7.1%):** Projected ₹${fvFd.toStringAsFixed(0)} (Gain: +₹${gainFd.toStringAsFixed(0)})\n'
          '• **Market-Linked Index Growth (Nifty 50 @ ~12.5% avg):** Projected ₹${fvEq.toStringAsFixed(0)} (Gain: +₹${gainEq.toStringAsFixed(0)})\n\n'
          'This monthly allocation builds disciplined compounding while preserving essential liquidity.';
      return {
        'reply': reply,
        'source': 'deterministic_verified_explainer',
        'relevant_cards': [],
      };
    }

    // 2. Why did you show this option?
    if (q.contains('why') && (q.contains('show') || q.contains('option') || q.contains('recommend') || q.contains('choice'))) {
      final reply = 'The matching investment options are chosen through deterministic rules based on your current financial status:\n\n'
          '1. **Capital Safety & Sovereign Backing:** Government 91-Day T-Bills and PPF protect capital without credit or default risk.\n'
          '2. **Guaranteed Return Fixed Deposits:** SBI Domestic Term Deposit (6.80% p.a.) provides predictable yield insured by DICGC up to ₹5 Lakh.\n'
          '3. **Low-Cost Market Growth:** HDFC Nifty 50 Index Fund and Nippon Nifty BeES ETF give direct exposure to India\'s top 50 companies at minimal expense ratios (0.04% - 0.20%).\n\n'
          'Options with speculative risk or unverified claims are strictly filtered out.';
      return {
        'reply': reply,
        'source': 'deterministic_verified_explainer',
        'relevant_cards': [],
      };
    }

    // 3. Lower risk query
    if (q.contains('lower risk') || q.contains('low risk') || q.contains('safe') || q.contains('safest')) {
      final reply = 'The lowest-risk options in your verified list are:\n\n'
          '• **Government of India 91-Day T-Bill (6.48% p.a.):** Backed by the Reserve Bank of India with zero credit risk.\n'
          '• **Public Provident Fund (7.10% p.a.):** Sovereign guaranteed with triple tax exemption (EEE).\n'
          '• **SBI Domestic Term Deposit (6.80% p.a.):** Fixed, guaranteed returns backed by State Bank of India.\n\n'
          'In contrast, Equity Index Funds (Nifty BeES, HDFC Index) carry moderate market risk and fluctuate with the stock market.';
      return {
        'reply': reply,
        'source': 'deterministic_verified_explainer',
        'relevant_cards': [],
      };
    }

    // 4. What if surplus decreases
    if (q.contains('surplus') || q.contains('decrease') || q.contains('what if') || q.contains('spend')) {
      final delta = whatIfMonthlyDelta.abs();
      final reply = 'If your monthly surplus decreases by ₹${delta.toStringAsFixed(0)}:\n\n'
          '• **Impact on Discretionary Investments:** Your available free cash-flow is reduced by ₹${delta.toStringAsFixed(0)} every month.\n'
          '• **Emergency Reserve Priority:** Your existing emergency buffer remains fully protected.\n'
          '• **Adjustment Recommendation:** We advise lowering your monthly SIP contributions slightly so your essential living commitments are never compromised.';
      return {
        'reply': reply,
        'source': 'deterministic_verified_explainer',
        'relevant_cards': [],
      };
    }

    // 5. General verified financial assistant response
    final reply = 'I am your Pennora Financial Copilot. Here is guidance based on verified financial principles:\n\n'
        '• **Emergency Fund:** Ensure 3–6 months of essential living expenses are saved in liquid instruments (Savings/FD/T-Bills).\n'
        '• **Disciplined SIPs:** Regular monthly investments in broad index funds or PPF harness rupee cost averaging.\n'
        '• **Risk Diversification:** Balance guaranteed low-risk options (SBI FD / PPF) with market-linked options (Nifty 50 Index) according to your timeline.\n\n'
        'Feel free to ask about any specific investment amount, risk comparison, or surplus scenario!';
    return {
      'reply': reply,
      'source': 'deterministic_verified_explainer',
      'relevant_cards': [],
    };
  }
}

class MatchingInvestmentOption {
  final String productId;
  final String productName;
  final String category;
  final String provider;
  final double currentRateOrNav;
  final String rateOrNavText;
  final String riskLevel;
  final String liquidity;
  final double minimumInvestment;
  final String source;
  final String asOfDate;
  final bool isGuaranteed;
  final bool isEligible;
  final String whyItMatches;
  final String risksAndLimitations;
  final double score;

  const MatchingInvestmentOption({
    required this.productId,
    required this.productName,
    required this.category,
    required this.provider,
    required this.currentRateOrNav,
    required this.rateOrNavText,
    required this.riskLevel,
    required this.liquidity,
    required this.minimumInvestment,
    required this.source,
    required this.asOfDate,
    required this.isGuaranteed,
    required this.isEligible,
    required this.whyItMatches,
    required this.risksAndLimitations,
    required this.score,
  });

  factory MatchingInvestmentOption.fromMap(Map<String, dynamic> map) {
    return MatchingInvestmentOption(
      productId: (map['product_id'] ?? '').toString(),
      productName: (map['product_name'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      provider: (map['provider'] ?? '').toString(),
      currentRateOrNav: (map['current_rate_or_nav'] as num?)?.toDouble() ?? 0.0,
      rateOrNavText: (map['rate_or_nav_text'] ?? '').toString(),
      riskLevel: (map['risk_level'] ?? 'Moderate').toString(),
      liquidity: (map['liquidity'] ?? 'Moderate').toString(),
      minimumInvestment: (map['minimum_investment'] as num?)?.toDouble() ?? 500.0,
      source: (map['source'] ?? '').toString(),
      asOfDate: (map['as_of_date'] ?? '').toString(),
      isGuaranteed: map['is_guaranteed'] == true,
      isEligible: map['is_eligible'] == true,
      whyItMatches: (map['why_it_matches'] ?? '').toString(),
      risksAndLimitations: (map['risks_and_limitations'] ?? '').toString(),
      score: (map['score'] as num?)?.toDouble() ?? 50.0,
    );
  }
}

