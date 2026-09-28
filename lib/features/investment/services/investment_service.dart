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
}
