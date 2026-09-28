import 'dart:convert';

/// Financial Profile model capturing user-entered onboarding data,
/// including role-specific answers, financial baseline, and calculations.
class FinancialProfile {
  final String userId;
  final String financialRole; // 'student', 'working_single', 'working_married'
  final String? roleData; // JSON-encoded role-specific answers
  final int age;
  final String occupation;
  final int dependents;
  final double monthlyIncome;
  final String incomeType;
  final double additionalIncome;
  final double currentSavings;
  final double monthlyFixedExpenses;
  final double monthlyVariableExpenses;
  final double existingLoanEmi;
  final int activeLoansCount;
  final bool isCompleted;
  final DateTime completedAt;

  const FinancialProfile({
    required this.userId,
    this.financialRole = 'working_single',
    this.roleData,
    required this.age,
    required this.occupation,
    required this.dependents,
    required this.monthlyIncome,
    required this.incomeType,
    this.additionalIncome = 0.0,
    required this.currentSavings,
    required this.monthlyFixedExpenses,
    required this.monthlyVariableExpenses,
    required this.existingLoanEmi,
    required this.activeLoansCount,
    this.isCompleted = true,
    required this.completedAt,
  });

  /// Normalized role key ('student', 'working_single', 'working_married')
  String get normalizedRole {
    final r = financialRole.trim().toLowerCase();
    if (r == 'student') return 'student';
    if (r == 'family' || r == 'working_married') return 'working_married';
    return 'working_single';
  }

  bool get isStudent => normalizedRole == 'student';
  bool get isWorkingSingle => normalizedRole == 'working_single';
  bool get isWorkingMarried => normalizedRole == 'working_married';

  String get roleTitle {
    switch (normalizedRole) {
      case 'student':
        return 'Student';
      case 'working_married':
        return 'Married / Family';
      case 'working_single':
      default:
        return 'Working Professional';
    }
  }

  /// Total combined monthly income.
  double get totalMonthlyIncome => monthlyIncome + additionalIncome;

  /// Savings reserve alias for current savings
  double get savingsReserve => currentSavings;

  /// Essential obligations (Fixed living/housing costs + required EMIs)
  double get essentialExpenses => monthlyFixedExpenses + existingLoanEmi;

  /// Discretionary spending (lifestyle, variable expenses)
  double get discretionaryExpenses => monthlyVariableExpenses;

  /// Total monthly expenses including loans.
  double get totalMonthlyExpenses =>
      monthlyFixedExpenses + monthlyVariableExpenses + existingLoanEmi;

  /// Available monthly surplus after expenses
  double get monthlySurplus => totalMonthlyIncome - totalMonthlyExpenses;

  /// Savings rate percentage (0% - 100%)
  double get savingsRate {
    if (totalMonthlyIncome <= 0) return 0.0;
    final rate = (monthlySurplus / totalMonthlyIncome) * 100.0;
    return rate.clamp(0.0, 100.0);
  }

  /// Emergency fund coverage in months of essential expenses
  double get emergencyFundMonths {
    if (essentialExpenses <= 0) return currentSavings > 0 ? 12.0 : 0.0;
    return (currentSavings / essentialExpenses);
  }

  /// Debt-to-income ratio (0.0 to 1.0+)
  double get debtToIncomeRatio {
    if (totalMonthlyIncome <= 0) return existingLoanEmi > 0 ? 1.0 : 0.0;
    return (existingLoanEmi / totalMonthlyIncome);
  }

  /// Parsed role-specific answers map
  Map<String, dynamic> get parsedRoleData {
    if (roleData == null || roleData!.isEmpty) return {};
    try {
      return json.decode(roleData!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'financialRole': normalizedRole,
      'roleData': roleData,
      'age': age,
      'occupation': occupation,
      'dependents': dependents,
      'monthlyIncome': monthlyIncome,
      'incomeType': incomeType,
      'additionalIncome': additionalIncome,
      'currentSavings': currentSavings,
      'monthlyFixedExpenses': monthlyFixedExpenses,
      'monthlyVariableExpenses': monthlyVariableExpenses,
      'existingLoanEmi': existingLoanEmi,
      'activeLoansCount': activeLoansCount,
      'isCompleted': isCompleted,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory FinancialProfile.fromMap(Map<String, dynamic> map) {
    return FinancialProfile(
      userId: map['userId'] as String? ?? '',
      financialRole: (map['financialRole'] ?? map['role'] ?? 'working_single').toString(),
      roleData: map['roleData']?.toString(),
      age: (map['age'] as num?)?.toInt() ?? 18,
      occupation: map['occupation'] as String? ?? '',
      dependents: (map['dependents'] as num?)?.toInt() ?? 0,
      monthlyIncome: (map['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      incomeType: map['incomeType'] as String? ?? 'Salary',
      additionalIncome: (map['additionalIncome'] as num?)?.toDouble() ?? 0.0,
      currentSavings: (map['currentSavings'] as num?)?.toDouble() ?? 0.0,
      monthlyFixedExpenses:
          (map['monthlyFixedExpenses'] as num?)?.toDouble() ??
          (map['fixedExpenses'] as num?)?.toDouble() ??
          0.0,
      monthlyVariableExpenses:
          (map['monthlyVariableExpenses'] as num?)?.toDouble() ??
          (map['variableExpenses'] as num?)?.toDouble() ??
          0.0,
      existingLoanEmi:
          (map['existingLoanEmi'] as num?)?.toDouble() ??
          (map['monthlyEMI'] as num?)?.toDouble() ??
          0.0,
      activeLoansCount:
          (map['activeLoansCount'] as num?)?.toInt() ??
          (map['activeLoans'] as num?)?.toInt() ??
          0,
      isCompleted: map['isCompleted'] as bool? ?? true,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String) ?? DateTime.now()
          : (map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  String toJson() => json.encode(toMap());

  factory FinancialProfile.fromJson(String source) =>
      FinancialProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
