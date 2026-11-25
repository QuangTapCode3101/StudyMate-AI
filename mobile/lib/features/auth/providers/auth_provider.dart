import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final Future<void> Function()? onBeforeLogout;

  AuthStatus _status = AuthStatus.initializing;
  AuthUser? _user;
  bool _isLoading = false;
  bool _isOfflineSession = false;
  String? _errorMessage;

  AuthProvider({
    required this._authService,
    this.onBeforeLogout,
  });

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  int? get userId => _user?.id;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isPremium => _user?.isPremium ?? false;
  bool get isLoading => _isLoading;
  bool get isOfflineSession => _isOfflineSession;
  String? get errorMessage => _errorMessage;

  /// Gọi 1 lần lúc khởi động app trong AuthGate
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.initializing;
    _errorMessage = null;
    notifyListeners();

    final token = await _authService.getToken();
    final cachedUser = await _authService.getCachedUser();

    if (token == null || token.isEmpty || cachedUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Cho phép vào app trước bằng cache nếu đang offline, đồng thời xác thực lại với server
    try {
      final freshUser = await _authService.fetchMe();
      _user = freshUser;
      _isOfflineSession = false;
      _status = AuthStatus.authenticated;
    } on AuthException catch (e) {
      if (e.isUnauthorized) {
        // Token hết hạn hoặc bị thu hồi -> bắt đăng nhập lại
        await _authService.clearSession();
        _user = null;
        _status = AuthStatus.unauthenticated;
      } else {
        // Lỗi mạng / Timeout -> Vẫn cho vào học Offline bằng cache
        _user = cachedUser;
        _isOfflineSession = true;
        _status = AuthStatus.authenticated;
      }
    } catch (_) {
      _user = cachedUser;
      _isOfflineSession = true;
      _status = AuthStatus.authenticated;
    }

    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.login(email: email, password: password);
      _user = result.user;
      _isOfflineSession = false;
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _user = result.user;
      _isOfflineSession = false;
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Trả về chuỗi thông báo thành công nếu kích hoạt được, null nếu lỗi (đọc errorMessage)
  Future<String?> redeemCode(String code) async {
    _setLoading(true);
    try {
      final res = await _authService.redeemCode(code);
      _user = res.user;
      _isOfflineSession = false;
      return res.message;
    } on AuthException catch (e) {
      if (e.isUnauthorized) {
        await logout();
      }
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Không thể kích hoạt mã lúc này.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      if (onBeforeLogout != null) {
        await onBeforeLogout!(); // Dùng để đóng DatabaseHelper an toàn
      }
      await _authService.clearSession();
      _user = null;
      _isOfflineSession = false;
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }
}