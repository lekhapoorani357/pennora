import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../auth/models/user_model.dart';
import '../../onboarding/models/financial_profile_model.dart';

/// API service for User profile and Financial Profile endpoints.
class ProfileApiService {
  final ApiClient _client;

  ProfileApiService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Retrieve the authenticated user's profile from GET /users/me.
  Future<UserModel> getMe() async {
    final response = await _client.get('/users/me', requiresAuth: true);
    final userMap = response as Map<String, dynamic>;

    return UserModel(
      id: (userMap['_id'] ?? userMap['id'] ?? '').toString(),
      fullName: (userMap['fullName'] ?? '').toString(),
      phone: (userMap['phone'] ?? '').toString(),
      countryCode: '+91',
      email: (userMap['email'] ?? '').toString(),
      passwordHash: '',
      createdAt: userMap['createdAt'] != null
          ? DateTime.tryParse(userMap['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Set user's financial role via POST /financial-profile/role.
  Future<FinancialProfile> setFinancialRole(String role) async {
    final response = await _client.post(
      '/financial-profile/role',
      body: {'role': role},
      requiresAuth: true,
    );
    return _mapToFinancialProfile(response as Map<String, dynamic>);
  }

  /// Get user's financial role via GET /financial-profile/role.
  Future<String> getFinancialRole() async {
    try {
      final response = await _client.get('/financial-profile/role', requiresAuth: true);
      if (response is Map<String, dynamic>) {
        return (response['financialRole'] ?? response['role'] ?? 'working_single').toString();
      }
    } catch (_) {}
    return 'working_single';
  }

  /// Retrieve the authenticated user's financial profile from GET /financial-profile.
  /// Returns null if not found (404).
  Future<FinancialProfile?> getFinancialProfile() async {
    try {
      final response = await _client.get('/financial-profile', requiresAuth: true);
      if (response == null) return null;
      return _mapToFinancialProfile(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isNotFound) {
        return null;
      }
      rethrow;
    }
  }

  /// Create a financial profile on backend via POST /financial-profile.
  /// Note: The backend POST /financial-profile also performs upsert if profile exists.
  Future<FinancialProfile> saveFinancialProfile(FinancialProfile profile) async {
    final payload = _financialProfileToPayload(profile);
    final response = await _client.post(
      '/financial-profile',
      body: payload,
      requiresAuth: true,
    );
    return _mapToFinancialProfile(response as Map<String, dynamic>);
  }

  /// Update an existing financial profile on backend via PUT /financial-profile.
  Future<FinancialProfile> updateFinancialProfile(FinancialProfile profile) async {
    final payload = _financialProfileToPayload(profile);
    final response = await _client.put(
      '/financial-profile',
      body: payload,
      requiresAuth: true,
    );
    return _mapToFinancialProfile(response as Map<String, dynamic>);
  }

  Map<String, dynamic> _financialProfileToPayload(FinancialProfile profile) {
    return {
      'financialRole': profile.normalizedRole,
      'roleData': profile.roleData,
      'age': profile.age,
      'occupation': profile.occupation,
      'dependents': profile.dependents,
      'monthlyIncome': profile.monthlyIncome,
      'incomeType': profile.incomeType,
      'additionalIncome': profile.additionalIncome,
      'currentSavings': profile.currentSavings,
      'fixedExpenses': profile.monthlyFixedExpenses,
      'variableExpenses': profile.monthlyVariableExpenses,
      'monthlyEMI': profile.existingLoanEmi,
      'activeLoans': profile.activeLoansCount,
    };
  }

  FinancialProfile _mapToFinancialProfile(Map<String, dynamic> map) {
    return FinancialProfile(
      userId: (map['userId'] ?? '').toString(),
      financialRole: (map['financialRole'] ?? map['role'] ?? 'working_single').toString(),
      roleData: map['roleData']?.toString(),
      age: (map['age'] as num?)?.toInt() ?? 18,
      occupation: (map['occupation'] ?? '').toString(),
      dependents: (map['dependents'] as num?)?.toInt() ?? 0,
      monthlyIncome: (map['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      incomeType: (map['incomeType'] ?? 'Salary').toString(),
      additionalIncome: (map['additionalIncome'] as num?)?.toDouble() ?? 0.0,
      currentSavings: (map['currentSavings'] as num?)?.toDouble() ?? 0.0,
      monthlyFixedExpenses:
          (map['fixedExpenses'] as num?)?.toDouble() ??
          (map['monthlyFixedExpenses'] as num?)?.toDouble() ??
          0.0,
      monthlyVariableExpenses:
          (map['variableExpenses'] as num?)?.toDouble() ??
          (map['monthlyVariableExpenses'] as num?)?.toDouble() ??
          0.0,
      existingLoanEmi:
          (map['monthlyEMI'] as num?)?.toDouble() ??
          (map['existingLoanEmi'] as num?)?.toDouble() ??
          0.0,
      activeLoansCount:
          (map['activeLoans'] as num?)?.toInt() ??
          (map['activeLoansCount'] as num?)?.toInt() ??
          0,
      isCompleted: true,
      completedAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
