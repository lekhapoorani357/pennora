import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';

class HouseholdMemberModel {
  final String id;
  final String userId;
  final String role;
  final String status;
  final bool shareFinancials;
  final String fullName;
  final String email;
  final DateTime? joinedAt;

  const HouseholdMemberModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.status,
    required this.shareFinancials,
    required this.fullName,
    required this.email,
    this.joinedAt,
  });

  factory HouseholdMemberModel.fromMap(Map<String, dynamic> map) {
    return HouseholdMemberModel(
      id: (map['_id'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      role: (map['role'] ?? 'member').toString(),
      status: (map['status'] ?? 'active').toString(),
      shareFinancials: map['shareFinancials'] == true,
      fullName: (map['fullName'] ?? 'Family Member').toString(),
      email: (map['email'] ?? '').toString(),
      joinedAt: map['joinedAt'] != null
          ? DateTime.tryParse(map['joinedAt'].toString())
          : null,
    );
  }
}

class HouseholdInvitationModel {
  final String id;
  final String householdId;
  final String householdName;
  final String invitedBy;
  final String status;
  final DateTime? expiresAt;

  const HouseholdInvitationModel({
    required this.id,
    required this.householdId,
    required this.householdName,
    required this.invitedBy,
    required this.status,
    this.expiresAt,
  });

  factory HouseholdInvitationModel.fromMap(Map<String, dynamic> map) {
    return HouseholdInvitationModel(
      id: (map['_id'] ?? '').toString(),
      householdId: (map['householdId'] ?? '').toString(),
      householdName: (map['householdName'] ?? 'Family Household').toString(),
      invitedBy: (map['invitedBy'] ?? 'Family Member').toString(),
      status: (map['status'] ?? 'pending').toString(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'].toString())
          : null,
    );
  }
}

class HouseholdService extends ChangeNotifier {
  static HouseholdService? _instance;
  static HouseholdService get instance => _instance ??= HouseholdService._();

  HouseholdService._();

  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  Map<String, dynamic>? _household;
  List<HouseholdMemberModel> _members = [];
  List<HouseholdInvitationModel> _myInvitations = [];
  bool _isOwner = false;
  int _maxMembers = 5;
  int _currentCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get household => _household;
  List<HouseholdMemberModel> get members => _members;
  List<HouseholdInvitationModel> get myInvitations => _myInvitations;
  bool get isOwner => _isOwner;
  int get maxMembers => _maxMembers;
  int get currentCount => _currentCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyHousehold() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.get('/api/household/my-household');
      if (res is Map<String, dynamic>) {
        _household = res['household'] as Map<String, dynamic>?;
        _isOwner = res['isOwner'] == true;
        _maxMembers = (res['maxMembers'] as num?)?.toInt() ?? 5;
        _currentCount = (res['currentCount'] as num?)?.toInt() ?? 0;

        final rawMembers = res['members'] as List? ?? [];
        _members = rawMembers
            .map((m) => HouseholdMemberModel.fromMap(m as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyInvitations() async {
    try {
      final res = await ApiClient.instance.get('/api/household/my-invitations');
      if (res is Map<String, dynamic>) {
        final rawList = res['invitations'] as List? ?? [];
        _myInvitations = rawList
            .map((i) => HouseholdInvitationModel.fromMap(i as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> createHousehold(String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.post(
        '/api/household/create',
        body: {'name': name.trim()},
      );
      if (res is Map<String, dynamic>) {
        await fetchMyHousehold();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> inviteMember(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.post(
        '/api/household/invite',
        body: {'email': email.trim()},
      );
      if (res is Map<String, dynamic>) {
        await fetchMyHousehold();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptInvitation(String inviteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.post('/api/household/invitations/$inviteId/accept');
      if (res is Map<String, dynamic>) {
        await fetchMyHousehold();
        await fetchMyInvitations();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> declineInvitation(String inviteId) async {
    try {
      await ApiClient.instance.post('/api/household/invitations/$inviteId/decline');
      await fetchMyInvitations();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeOrLeave(String memberId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.instance.delete('/api/household/members/$memberId');
      await fetchMyHousehold();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFinancialSharing(bool share) async {
    try {
      await ApiClient.instance.patch(
        '/api/household/privacy',
        body: {'shareFinancials': share},
      );
      await fetchMyHousehold();
      return true;
    } catch (_) {
      return false;
    }
  }
}
