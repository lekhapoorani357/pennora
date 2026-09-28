import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';

class PartnerProductModel {
  final String id;
  final String partnerName;
  final String productName;
  final String category;
  final String description;
  final String referralUrl;
  final String disclosure;
  final bool isDemo;

  const PartnerProductModel({
    required this.id,
    required this.partnerName,
    required this.productName,
    required this.category,
    required this.description,
    required this.referralUrl,
    required this.disclosure,
    required this.isDemo,
  });

  factory PartnerProductModel.fromMap(Map<String, dynamic> map) {
    return PartnerProductModel(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      partnerName: (map['partnerName'] ?? 'DEMO PARTNER').toString(),
      productName: (map['productName'] ?? 'Financial Product').toString(),
      category: (map['category'] ?? 'SAVINGS').toString(),
      description: (map['description'] ?? '').toString(),
      referralUrl: (map['referralUrl'] ?? '').toString(),
      disclosure: (map['disclosure'] ?? 'DEMO PARTNER disclosure: GoalSync may receive compensation.').toString(),
      isDemo: map['isDemo'] == true,
    );
  }
}

class PartnerService extends ChangeNotifier {
  static PartnerService? _instance;
  static PartnerService get instance => _instance ??= PartnerService._();

  PartnerService._();

  List<PartnerProductModel> _partners = [
    const PartnerProductModel(
      id: 'demo_p1',
      partnerName: 'DEMO PARTNER — FinSecure Bank',
      productName: 'High-Yield Fixed Deposit 7.75%',
      category: 'FD',
      description: 'AAA-rated fixed return deposit suitable for emergency cushions and stable growth.',
      referralUrl: 'https://pennora.demo/partner/finsecure-fd',
      disclosure: 'DEMO PARTNER: For illustrative demonstration only.',
      isDemo: true,
    ),
    const PartnerProductModel(
      id: 'demo_p2',
      partnerName: 'DEMO PARTNER — IndexGrowth Direct',
      productName: 'Zero-Fee Index Fund Platform',
      category: 'MUTUAL_FUND',
      description: 'Direct low-cost index investing with automated monthly contribution options.',
      referralUrl: 'https://pennora.demo/partner/indexgrowth',
      disclosure: 'DEMO PARTNER: For illustrative demonstration only.',
      isDemo: true,
    ),
    const PartnerProductModel(
      id: 'demo_p3',
      partnerName: 'DEMO PARTNER — CareShield Life & Health',
      productName: 'Comprehensive Family Risk Protection',
      category: 'INSURANCE',
      description: 'Term and health protection shielding households from unforeseen income disruption.',
      referralUrl: 'https://pennora.demo/partner/careshield',
      disclosure: 'DEMO PARTNER: For illustrative demonstration only.',
      isDemo: true,
    ),
  ];

  List<PartnerProductModel> get partners => List.unmodifiable(_partners);

  Future<void> fetchPartners({String? category}) async {
    try {
      final endpoint = category != null && category.isNotEmpty
          ? '/api/partners?category=$category'
          : '/api/partners';
      final res = await ApiClient.instance.get(endpoint);
      if (res is Map<String, dynamic> && res['partners'] is List) {
        _partners = (res['partners'] as List)
            .map((p) => PartnerProductModel.fromMap(p as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> recordClick(PartnerProductModel product) async {
    if (ApiClient.instance.authToken == null) return;
    try {
      await ApiClient.instance.post(
        '/api/partners/click',
        body: {
          'partnerId': product.id,
          'productName': product.productName,
        },
        requiresAuth: true,
      );
    } catch (_) {}
  }
}
