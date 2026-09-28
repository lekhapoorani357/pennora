import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';

class SubscriptionPlanModel {
  final String code;
  final String name;
  final String tier;
  final String billingPeriod;
  final double price;
  final String currency;
  final bool active;
  final int trialDays;
  final List<String> features;

  const SubscriptionPlanModel({
    required this.code,
    required this.name,
    required this.tier,
    required this.billingPeriod,
    required this.price,
    required this.currency,
    required this.active,
    required this.trialDays,
    required this.features,
  });

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlanModel(
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      tier: (map['tier'] ?? 'free').toString(),
      billingPeriod: (map['billingPeriod'] ?? 'monthly').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] ?? 'INR').toString(),
      active: map['active'] == true,
      trialDays: (map['trialDays'] as num?)?.toInt() ?? 0,
      features: map['features'] is List
          ? List<String>.from(map['features'] as List)
          : [],
    );
  }
}

/// Service managing user subscription status (Free vs Premium/Student/Family),
/// plan catalogs, free trials, and backend entitlement sync.
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
  static const String _keyPlanId = 'goalsync_sub_plan_id';

  bool _isPremium = false;
  String _tier = 'free';
  String? _planId = 'free';
  double _price = 0.0;
  String _billingCycle = 'monthly';
  bool _isDemo = true;
  bool _inTrial = false;
  DateTime? _trialEndsAt;
  List<SubscriptionPlanModel> _availablePlans = [];
  List<String> _features = [
    'Manual transactions',
    'Basic categorization',
    'Basic dashboard',
    'Basic goals',
    'Basic financial analysis',
  ];

  bool _isStudentEligible = false;
  String _studentVerificationStatus = 'unverified';
  String? _studentInstitution;
  int _studentTrialDays = 30;

  bool get isPremium => _isPremium;
  bool get isAdFree => _isPremium;
  String get tier => _tier;
  String? get planId => _planId;
  double get price => _price;
  String get billingCycle => _billingCycle;
  bool get isDemo => _isDemo;
  bool get inTrial => _inTrial;
  DateTime? get trialEndsAt => _trialEndsAt;
  bool get isStudentEligible => _isStudentEligible;
  String get studentVerificationStatus => _studentVerificationStatus;
  String? get studentInstitution => _studentInstitution;
  int get studentTrialDays => _studentTrialDays;

  int get remainingTrialDays {
    if (!_inTrial || _trialEndsAt == null) return 0;
    final diff = _trialEndsAt!.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff : 0;
  }

  List<SubscriptionPlanModel> get availablePlans => List.unmodifiable(_availablePlans);
  List<String> get features => List.unmodifiable(_features);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_keyIsPremium) ?? false;
    _tier = prefs.getString(_keyTier) ?? (_isPremium ? 'premium' : 'free');
    _planId = prefs.getString(_keyPlanId) ?? (_isPremium ? 'premium_monthly' : 'free');
    notifyListeners();
  }

  /// Fetch all available plans from backend GET /api/subscription/plans
  Future<List<SubscriptionPlanModel>> fetchPlans() async {
    try {
      final res = await ApiClient.instance.get(
        '/api/subscription/plans',
        requiresAuth: ApiClient.instance.authToken != null,
      );
      if (res is List) {
        _availablePlans = res
            .map((e) => SubscriptionPlanModel.fromMap(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _availablePlans;
      }
    } catch (_) {}
    return _availablePlans;
  }

  /// Sync subscription status with backend GET /api/subscription
  Future<void> fetchStatus() async {
    try {
      final res = await ApiClient.instance.get(
        '/api/subscription',
        requiresAuth: ApiClient.instance.authToken != null,
      );
      if (res is Map<String, dynamic>) {
        _isPremium = res['isPremium'] == true;
        _tier = (res['tier'] ?? 'free').toString();
        _planId = res['planId']?.toString();
        _price = (res['price'] as num?)?.toDouble() ?? 0.0;
        _billingCycle = (res['billingCycle'] ?? 'monthly').toString();
        _isDemo = res['isDemo'] == true;
        _inTrial = res['inTrial'] == true;

        if (res['trialEndsAt'] != null) {
          try {
            _trialEndsAt = DateTime.parse(res['trialEndsAt'].toString());
          } catch (_) {}
        } else {
          _trialEndsAt = null;
        }

        if (res['features'] is List) {
          _features = List<String>.from(res['features'] as List);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsPremium, _isPremium);
        await prefs.setString(_keyTier, _tier);
        if (_planId != null) await prefs.setString(_keyPlanId, _planId!);
        notifyListeners();
      }
    } catch (_) {
      // Local fallback
    }
  }

  /// Activate DEMO subscription via POST /api/subscription/demo-activate
  Future<bool> activateDemoPremium({String planCode = 'premium_monthly'}) async {
    _isPremium = true;
    _planId = planCode;
    _isDemo = true;

    if (planCode.startsWith('student')) {
      _tier = 'student';
    } else if (planCode.startsWith('family')) {
      _tier = 'family';
    } else {
      _tier = 'premium';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, true);
    await prefs.setString(_keyTier, _tier);
    await prefs.setString(_keyPlanId, _planId!);
    notifyListeners();

    try {
      final res = await ApiClient.instance.post(
        '/api/subscription/demo-activate',
        body: {'planCode': planCode},
        requiresAuth: ApiClient.instance.authToken != null,
      );
      if (res is Map<String, dynamic>) {
        _price = (res['price'] as num?)?.toDouble() ?? _price;
        _billingCycle = (res['billingCycle'] ?? 'monthly').toString();
        if (res['features'] is List) {
          _features = List<String>.from(res['features'] as List);
        }
      }
      notifyListeners();
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Activate free 14-day trial via POST /api/subscription/trial-activate
  Future<bool> activateTrial({String planCode = 'premium_monthly'}) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/subscription/trial-activate',
        body: {'planCode': planCode},
        requiresAuth: ApiClient.instance.authToken != null,
      );
      if (res is Map<String, dynamic>) {
        _isPremium = true;
        _inTrial = true;
        _tier = (res['tier'] ?? 'premium').toString();
        _planId = planCode;
        if (res['trialEndsAt'] != null) {
          try {
            _trialEndsAt = DateTime.parse(res['trialEndsAt'].toString());
          } catch (_) {}
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Cancel subscription (switching back to free tier)
  Future<void> cancelSubscription() async {
    _isPremium = false;
    _tier = 'free';
    _planId = 'free';
    _inTrial = false;
    _trialEndsAt = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, false);
    await prefs.setString(_keyTier, 'free');
    await prefs.setString(_keyPlanId, 'free');
    notifyListeners();

    try {
      await ApiClient.instance.post(
        '/api/subscription/cancel',
        requiresAuth: ApiClient.instance.authToken != null,
      );
    } catch (_) {}
  }

  /// Sync student verification status via GET /api/subscription/student-status
  Future<void> fetchStudentStatus() async {
    try {
      final res = await ApiClient.instance.get(
        '/api/subscription/student-status',
        requiresAuth: ApiClient.instance.authToken != null,
      );
      if (res is Map<String, dynamic>) {
        _isStudentEligible = res['isEligible'] == true;
        _studentVerificationStatus = (res['verificationStatus'] ?? 'unverified').toString();
        _studentInstitution = res['institution']?.toString();
        _studentTrialDays = (res['trialDurationDays'] as num?)?.toInt() ?? 30;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Verify student status via educational email or demo declaration
  Future<bool> verifyStudent({
    String? studentEmail,
    String? institutionName,
    bool isDemoSelfDeclared = false,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/subscription/verify-student',
        body: {
          if (studentEmail != null && studentEmail.isNotEmpty) 'studentEmail': studentEmail,
          if (institutionName != null && institutionName.isNotEmpty) 'institutionName': institutionName,
          'isDemoSelfDeclared': isDemoSelfDeclared,
        },
        requiresAuth: ApiClient.instance.authToken != null,
      );
      if (res is Map<String, dynamic>) {
        await fetchStudentStatus();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
