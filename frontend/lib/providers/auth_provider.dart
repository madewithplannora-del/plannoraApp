import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/storage_service.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final StorageService _storage = StorageService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _activeRole; // 'customer' or 'freelancer'
  String? _errorMessage;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _token != null;
  bool get isLoading => _status == AuthStatus.loading;
  UserModel? get user => _user;
  String? get token => _token;
  String? get activeRole => _activeRole;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initializeAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final savedToken = await _storage.getToken();
      final savedUserMap = await _storage.getUser();
      final savedRole = await _storage.getActiveRole();

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        if (savedUserMap != null) {
          _user = UserModel.fromJson(savedUserMap);
        }
        _activeRole = savedRole;

        // Verify with server profile endpoint
        try {
          final res = await _api.get(ApiConfig.profile);
          if (res is Map && res['user'] != null) {
            _user = UserModel.fromJson(res['user']);
            await _storage.saveUser(_user!.toJson());
          }
        } catch (_) {
          // If server is temporarily unreachable or awake delay, keep cached session
        }

        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final isEmail = identifier.contains('@');
      final body = {
        isEmail ? 'email' : 'username': identifier.trim(),
        'password': password,
      };

      final res = await _api.post(
        ApiConfig.login,
        body: body,
        requiresAuth: false,
      );

      if (res is Map && res['token'] != null) {
        _token = res['token'].toString();
        await _storage.saveToken(_token!);

        if (res['user'] != null) {
          _user = UserModel.fromJson(res['user']);
          await _storage.saveUser(_user!.toJson());
        }

        // Restore active role if any
        _activeRole = await _storage.getActiveRole();

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      throw ApiException(message: 'Authentication failed. No token received.');
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      };

      await _api.post(
        ApiConfig.register,
        body: body,
        requiresAuth: false,
      );

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred during registration.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      };

      final res = await _api.post(
        ApiConfig.verifyOtp,
        body: body,
        requiresAuth: false,
      );

      if (res is Map && res['token'] != null) {
        _token = res['token'].toString();
        await _storage.saveToken(_token!);

        if (res['user'] != null) {
          _user = UserModel.fromJson(res['user']);
          await _storage.saveUser(_user!.toJson());
        }

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      // If verified without direct token
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred during OTP verification.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post(
        ApiConfig.forgotPassword,
        body: {'email': email.trim().toLowerCase()},
        requiresAuth: false,
      );

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to request password reset OTP.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /*
      Forgot-password is a 2-step flow on the backend:

        Step 1  POST /api/auth/verifyforgototp   { email, otp }
                -> verifies the OTP and returns a short-lived resetToken
        Step 2  POST /api/auth/resetpassword     { resettoken / resetpassword: }
                -> actually changes the password

      The resetToken is passed via the Authorization header because the Dart
      http client does not persist httpOnly cookies. Both steps must succeed
      for the password to actually change — a success response from step 1
      alone changes nothing.
  */
  Future<bool> verifyOtpForgot({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // ---- Step 1: verify the OTP, receive resetToken ----
      final verifyRes = await _api.post(
        ApiConfig.verifyOtpForgot,
        body: {
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
        },
        requiresAuth: false,
      );

      String? resetToken;
      if (verifyRes is Map) {
        resetToken = verifyRes['resetToken']?.toString();
      }

      if (resetToken == null || resetToken.isEmpty) {
        throw ApiException(
          message:
              'Could not complete password reset. Please try requesting a new OTP.',
        );
      }

      // ---- Step 2: submit the new password with the reset token ----
      await _api.post(
        ApiConfig.resetPassword,
        body: {
          'resetpassword': newPassword,
        },
        requiresAuth: false,
        headers: {'Authorization': 'Bearer $resetToken'},
      );

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reset password.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> setActiveRole(String role) async {
    _activeRole = role;
    await _storage.saveActiveRole(role);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout, requiresAuth: true);
    } catch (_) {}

    await _storage.clearAll();
    _token = null;
    _user = null;
    _activeRole = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
