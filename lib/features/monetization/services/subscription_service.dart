import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';

/// Service managing user subscription status (Free vs Premium),
/// demo payment activation, and ad-free entitlement state.
class SubscriptionService extends ChangeNotifier {
  static SubscriptionService? _instance;
  static SubscriptionService get instance => _instance ??= SubscriptionService._();

  SubscriptionService._();

  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  static const String _keyIsPremium = 'goalsync_is_premium';
  static const String _keyTier = 'goalsync_sub_tier';

  bool _isPremium = false;
  String _tier = 'free';
  double _price = 99.0;
  bool _isDemo = true;
  List<String> _features = [
    'Manual transactions',
    'Basic categorization',
    'Basic dashboard',
    'Basic goals',
    'Basic financial analysis',
  ];

  bool get isPremium => _isPremium;
  bool get isAdFree => _isPremium;
  String get tier => _tier;
  double get price => _price;
  bool get isDemo => _isDemo;
  List<String> get features => List.unmodifiable(_features);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_keyIsPremium) ?? false;
    _tier = prefs.getString(_keyTier) ?? (_isPremium ? 'premium' : 'free');
    notifyListeners();
  }

  /// Sync subscription status with backend GET /api/subscription
  Future<void> fetchStatus() async {
    if (ApiClient.instance.authToken == null) return;
    try {
      final res = await ApiClient.instance.get('/api/subscription', requiresAuth: true);
      if (res is Map<String, dynamic>) {
        _isPremium = res['isPremium'] == true;
        _tier = (res['tier'] ?? 'free').toString();
        _price = (res['price'] as num?)?.toDouble() ?? 99.0;
        _isDemo = res['isDemo'] == true;
        if (res['features'] is List) {
          _features = List<String>.from(res['features'] as List);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsPremium, _isPremium);
        await prefs.setString(_keyTier, _tier);
        notifyListeners();
      }
    } catch (_) {
      // Local fallback
    }
  }

  /// Activate DEMO premium subscription via POST /api/subscription/demo-activate
  Future<bool> activateDemoPremium() async {
    _isPremium = true;
    _tier = 'premium';
    _isDemo = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, true);
    await prefs.setString(_keyTier, 'premium');
    notifyListeners();

    if (ApiClient.instance.authToken != null) {
      try {
        final res = await ApiClient.instance.post('/api/subscription/demo-activate', requiresAuth: true);
        if (res is Map<String, dynamic>) {
          _price = (res['price'] as num?)?.toDouble() ?? 99.0;
        }
      } catch (_) {}
    }
    return true;
  }

  /// Cancel subscription (for testing / switching back to free)
  Future<void> cancelSubscription() async {
    _isPremium = false;
    _tier = 'free';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, false);
    await prefs.setString(_keyTier, 'free');
    notifyListeners();

    if (ApiClient.instance.authToken != null) {
      try {
        await ApiClient.instance.post('/api/subscription/cancel', requiresAuth: true);
      } catch (_) {}
    }
  }
}
