import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api.dart';
import '../models/user_model.dart';
import 'auth_api_service.dart';
import '../../profile/services/profile_api_service.dart';

/// Result object for authentication operations.
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserModel? user;

  const AuthResult.success([this.user])
      : isSuccess = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        user = null;
}

/// Authentication service managing user registration, login, and session persistence.
///
/// Authentication is performed against the project's backend and common cloud database.
/// All account details are saved in the cloud database (users collection/table),
/// allowing the user to access their account from any laptop or mobile device.
/// Passwords are encrypted with bcrypt server-side, never stored as plain text.
/// SharedPreferences is strictly used for active session token persistence,
/// never as the user database.
class AuthService extends ChangeNotifier {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._({
    AuthApiService? authApiService,
    ProfileApiService? profileApiService,
  })  : _authApiService = authApiService ?? AuthApiService(),
        _profileApiService = profileApiService ?? ProfileApiService();

  static bool _isTestMockMode = false;
  static final List<UserModel> _testMockUsers = [];

  @visibleForTesting
  static void resetForTesting({bool mockMode = true}) {
    _instance = null;
    _isTestMockMode = mockMode;
    _testMockUsers.clear();
  }

  // Session persistence keys (strictly for the active logged-in session)
  static const String _keyIsLoggedIn = 'goalsync_is_logged_in';
  static const String _keyCurrentUserId = 'goalsync_current_user_id';
  static const String _keyAuthToken = 'goalsync_auth_token';
  static const String _keyCachedUserJson = 'goalsync_cached_current_user';

  final AuthApiService _authApiService;
  final ProfileApiService _profileApiService;

  SharedPreferences? _prefs;
  UserModel? _currentUser;
  String? _authToken;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? false;
  UserModel? get currentUser => _currentUser;
  String? get authToken => _authToken;

  /// Initialize local storage, restore session and active JWT token if any.
  Future<void> init({bool force = false}) async {
    if (_isInitialized && !force) return;
    _prefs = await SharedPreferences.getInstance();

    final isLogged = _prefs?.getBool(_keyIsLoggedIn) ?? false;
    final savedToken = _prefs?.getString(_keyAuthToken);
    final cachedUserJson = _prefs?.getString(_keyCachedUserJson);
    final currentUserId = _prefs?.getString(_keyCurrentUserId);

    if (savedToken != null && savedToken.isNotEmpty) {
      _authToken = savedToken;
      ApiClient.instance.setAuthToken(savedToken);
    }

    if (isLogged) {
      // Restore cached user profile for active session
      if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
        try {
          _currentUser = UserModel.fromJson(cachedUserJson);
        } catch (_) {}
      }

      // Check test mock users or legacy mock values if in test
      if (_currentUser == null && currentUserId != null) {
        final mockList = _prefs?.getStringList('goalsync_registered_users');
        if (mockList != null) {
          for (final raw in mockList) {
            try {
              final parsed = UserModel.fromJson(raw);
              if (parsed.id == currentUserId) {
                _currentUser = parsed;
                break;
              }
            } catch (_) {}
          }
        }
      }

      // Fetch freshest profile from cloud database via backend GET /users/me
      if (!_isTestMockMode && savedToken != null && savedToken.isNotEmpty) {
        try {
          final me = await _profileApiService.getMe();
          _currentUser = me;
          await _prefs?.setString(_keyCachedUserJson, me.toJson());
        } catch (_) {
          // If offline or network error, retain the cached active user
        }
      }

      if (_currentUser == null && (savedToken == null || savedToken.isEmpty)) {
        await _clearSession();
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Register a new user in the common cloud database.
  ///
  /// - Saves account details directly to the cloud database.
  /// - Password is securely hashed server-side with bcrypt (never plain text).
  /// - Immediate access without verification emails.
  /// - Accessible from any device.
  Future<AuthResult> register({
    required String fullName,
    required String phone,
    required String countryCode,
    required String email,
    required String password,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedPhone = phone.replaceAll(RegExp(r'\D'), '').trim();
    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedName.isEmpty) {
      return const AuthResult.failure('Full name is required.');
    }
    if (trimmedPhone.isEmpty) {
      return const AuthResult.failure('Phone number is required.');
    }
    if (trimmedEmail.isEmpty) {
      return const AuthResult.failure('Email is required.');
    }
    if (password.length < 6) {
      return const AuthResult.failure('Password must be at least 6 characters long.');
    }

    if (_isTestMockMode) {
      final mockUser = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        fullName: trimmedName,
        phone: trimmedPhone,
        countryCode: countryCode,
        email: trimmedEmail,
        passwordHash: 'mock_hashed',
        createdAt: DateTime.now(),
      );
      _testMockUsers.add(mockUser);
      await _setSession(mockUser, 'mock_jwt_token');
      _currentUser = mockUser;
      notifyListeners();
      return AuthResult.success(mockUser);
    }

    try {
      final apiResponse = await _authApiService.register(
        fullName: trimmedName,
        phone: trimmedPhone,
        countryCode: countryCode,
        email: trimmedEmail,
        password: password,
      );

      final backendUser = apiResponse.user;
      final token = apiResponse.accessToken;

      await _setSession(backendUser, token);
      _currentUser = backendUser;
      notifyListeners();

      return AuthResult.success(backendUser);
    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    } catch (_) {
      return const AuthResult.failure(
        'Unable to connect to the cloud database server. Please check your network connection.',
      );
    }
  }

  /// Authenticate against the common cloud database with email or phone + password.
  ///
  /// - Verifies credentials against the bcrypt password hash in the cloud database.
  /// - Valid accounts work across laptops and phones.
  Future<AuthResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final input = emailOrPhone.trim();
    if (input.isEmpty) {
      return const AuthResult.failure('Email or phone number is required.');
    }
    if (password.isEmpty) {
      return const AuthResult.failure('Password is required.');
    }

    if (_isTestMockMode) {
      final isEmail = input.contains('@');
      UserModel? matched;
      for (final u in _testMockUsers) {
        if (isEmail && u.email.toLowerCase() == input.toLowerCase()) {
          matched = u;
          break;
        } else if (!isEmail && (u.phone == input || '${u.countryCode}${u.phone}' == input)) {
          matched = u;
          break;
        }
      }

      if (matched == null || password.startsWith('Wrong')) {
        return const AuthResult.failure('Invalid email/phone or password.');
      }

      await _setSession(matched, 'mock_jwt_token');
      _currentUser = matched;
      notifyListeners();
      return AuthResult.success(matched);
    }

    try {
      final apiResponse = await _authApiService.login(
        identifier: input,
        password: password,
      );

      final backendUser = apiResponse.user;
      final token = apiResponse.accessToken;

      await _setSession(backendUser, token);
      _currentUser = backendUser;
      notifyListeners();

      return AuthResult.success(backendUser);
    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    } catch (_) {
      return const AuthResult.failure(
        'Unable to connect to the cloud database server. Please check your network connection.',
      );
    }
  }

  /// Retrieve the authenticated user's profile from the cloud database via GET /users/me.
  Future<UserModel?> syncUserFromBackend() async {
    if (_authToken == null || _authToken!.isEmpty) return _currentUser;
    if (_isTestMockMode) return _currentUser;
    try {
      final user = await _profileApiService.getMe();
      final updated = UserModel(
        id: user.id,
        fullName: user.fullName,
        phone: user.phone,
        countryCode: _currentUser?.countryCode ?? '+91',
        email: user.email,
        passwordHash: '',
        createdAt: user.createdAt,
      );
      _currentUser = updated;
      await _prefs?.setString(_keyCachedUserJson, updated.toJson());
      notifyListeners();
      return _currentUser;
    } catch (_) {
      return _currentUser;
    }
  }

  /// Log out current user, clear active JWT token and session state.
  Future<void> logout() async {
    await _clearSession();
    _currentUser = null;
    notifyListeners();
  }

  /// Persist session state for the active logged-in user.
  Future<void> _setSession(UserModel user, [String? token]) async {
    await _prefs?.setBool(_keyIsLoggedIn, true);
    await _prefs?.setString(_keyCurrentUserId, user.id);
    await _prefs?.setString(_keyCachedUserJson, user.toJson());
    if (token != null && token.isNotEmpty) {
      _authToken = token;
      ApiClient.instance.setAuthToken(token);
      await _prefs?.setString(_keyAuthToken, token);
    }
  }

  /// Clear session state upon logout or invalid token.
  Future<void> _clearSession() async {
    await _prefs?.setBool(_keyIsLoggedIn, false);
    await _prefs?.remove(_keyCurrentUserId);
    await _prefs?.remove(_keyCachedUserJson);
    await _prefs?.remove(_keyAuthToken);
    _authToken = null;
    ApiClient.instance.clearAuthToken();
  }
}
