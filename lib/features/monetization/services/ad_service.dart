import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import 'subscription_service.dart';

class AdModel {
  final String id;
  final String title;
  final String sponsor;
  final String content;
  final String callToAction;
  final String targetUrl;
  final bool isDemo;
  final String label;

  const AdModel({
    required this.id,
    required this.title,
    required this.sponsor,
    required this.content,
    required this.callToAction,
    required this.targetUrl,
    required this.isDemo,
    required this.label,
  });

  factory AdModel.fromMap(Map<String, dynamic> map) {
    return AdModel(
      id: (map['id'] ?? map['_id'] ?? 'demo_ad').toString(),
      title: (map['title'] ?? 'Sponsored Financial Solution').toString(),
      sponsor: (map['sponsor'] ?? 'DEMO SPONSOR').toString(),
      content: (map['content'] ?? 'Explore verified financial products tailored to your stage.').toString(),
      callToAction: (map['callToAction'] ?? 'Learn More').toString(),
      targetUrl: (map['targetUrl'] ?? '').toString(),
      isDemo: map['isDemo'] == true,
      label: (map['label'] ?? 'DEMO / PROJECTED AD').toString(),
    );
  }
}

class AdService extends ChangeNotifier {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();

  AdService._();

  List<AdModel> _cachedAds = [
    const AdModel(
      id: 'ad_fd_rates',
      title: 'Compare High-Yield Fixed Deposits',
      sponsor: 'FinSecure Bank (DEMO)',
      content: 'Lock in guaranteed returns up to 7.8% p.a. on your emergency reserves.',
      callToAction: 'Explore Rates',
      targetUrl: 'https://pennora.demo/partner/finsecure-fd',
      isDemo: true,
      label: 'DEMO / PROJECTED AD',
    ),
    const AdModel(
      id: 'ad_health_cover',
      title: 'Protect Your Family Health Fund',
      sponsor: 'CareShield (DEMO)',
      content: 'Comprehensive family medical protection starting at ₹499/month.',
      callToAction: 'View Plans',
      targetUrl: 'https://pennora.demo/partner/careshield-health',
      isDemo: true,
      label: 'DEMO / PROJECTED AD',
    ),
  ];

  List<AdModel> get ads => SubscriptionService.instance.isPremium ? [] : _cachedAds;
  bool get hasAds => !SubscriptionService.instance.isPremium && _cachedAds.isNotEmpty;

  Future<void> fetchAds() async {
    if (SubscriptionService.instance.isPremium) {
      _cachedAds = [];
      notifyListeners();
      return;
    }

    if (ApiClient.instance.authToken == null) return;
    try {
      final res = await ApiClient.instance.get('/api/ads', requiresAuth: true);
      if (res is Map<String, dynamic>) {
        if (res['isAdFree'] == true) {
          _cachedAds = [];
        } else if (res['ads'] is List) {
          _cachedAds = (res['ads'] as List)
              .map((a) => AdModel.fromMap(a as Map<String, dynamic>))
              .toList();
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> recordImpression(String adId) async {
    if (SubscriptionService.instance.isPremium) return;
    if (ApiClient.instance.authToken == null) return;
    try {
      await ApiClient.instance.post(
        '/api/ads/event',
        body: {'adId': adId, 'eventType': 'impression'},
        requiresAuth: true,
      );
    } catch (_) {}
  }

  Future<void> recordClick(String adId) async {
    if (SubscriptionService.instance.isPremium) return;
    if (ApiClient.instance.authToken == null) return;
    try {
      await ApiClient.instance.post(
        '/api/ads/event',
        body: {'adId': adId, 'eventType': 'click'},
        requiresAuth: true,
      );
    } catch (_) {}
  }
}
