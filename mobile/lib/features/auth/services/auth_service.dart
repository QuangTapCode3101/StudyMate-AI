
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';

class AuthException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  AuthException(this.message, {this.errorCode, this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final AuthUser user;

  AuthResult({required this.token, required this.user});
}

class AuthService {
  static const String _tokenKey = 'studymate_jwt_token';
  static const String _userKey = 'studymate_cached_user';

  final String baseUrl;
  final FlutterSecureStorage _storage;
  final http.Client _client;

  AuthService({
    required this.baseUrl,
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<AuthUser?> getCachedUser() async {
    final raw = await _storage.read(key: _userKey);

    if (raw == null || raw.isEmpty) return null;

    try {
      return AuthUser.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      await _storage.delete(key: _userKey);
      return null;
    }
  }

  Future<void> saveSession({
    required String token,
    required AuthUser user,
  }) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(
        key: _userKey,
        value: jsonEncode(user.toJson()),
      );
    } catch (_) {
      await clearSession();
      rethrow;
    }
  }

  Future<void> saveCachedUser(AuthUser user) async {
    await _storage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final data = await _post(
      '/api/v1/auth/register',
      body: {
        'email': email.trim(),
        'password': password,
        'displayName': displayName.trim(),
      },
    );

    final result = AuthResult(
      token: data['token'] as String,
      user: AuthUser.fromJson(
        data['user'] as Map<String, dynamic>,
      ),
    );

    await saveSession(
      token: result.token,
      user: result.user,
    );

    return result;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _post(
      '/api/v1/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final result = AuthResult(
      token: data['token'] as String,
      user: AuthUser.fromJson(
        data['user'] as Map<String, dynamic>,
      ),
    );

    await saveSession(
      token: result.token,
      user: result.user,
    );

    return result;
  }

  Future<AuthUser> fetchMe() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw AuthException(
        'Chưa đăng nhập.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/v1/auth/me');

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));

      final data = _handleResponse(response);

      final user = AuthUser.fromJson(
        data['user'] as Map<String, dynamic>,
      );

      await saveCachedUser(user);

      return user;
    } on SocketException {
      throw AuthException(
        'Không có kết nối mạng.',
        errorCode: 'NETWORK_ERROR',
      );
    } on TimeoutException {
      throw AuthException(
        'Kết nối máy chủ quá hạn.',
        errorCode: 'TIMEOUT',
      );
    } on HttpException {
      throw AuthException(
        'Không thể kết nối đến máy chủ.',
        errorCode: 'HTTP_ERROR',
      );
    }
  }

  Future<({String message, AuthUser user})> redeemCode(
    String code,
  ) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw AuthException(
        'Phiên đăng nhập hết hạn.',
        statusCode: 401,
      );
    }

    final data = await _post(
      '/api/v1/auth/redeem-code',
      body: {
        'code': code.trim().toUpperCase(),
      },
      token: token,
    );

    final user = AuthUser.fromJson(
      data['user'] as Map<String, dynamic>,
    );

    await saveCachedUser(user);

    return (
      message: data['message'] as String? ??
          'Kích hoạt Premium thành công!',
      user: user,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      return _handleResponse(response);
    } on SocketException {
      throw AuthException(
        'Không có kết nối mạng. Vui lòng kiểm tra Wi-Fi/4G.',
        errorCode: 'NETWORK_ERROR',
      );
    } on TimeoutException {
      throw AuthException(
        'Máy chủ phản hồi quá chậm. Vui lòng thử lại.',
        errorCode: 'TIMEOUT',
      );
    } on HttpException {
      throw AuthException(
        'Không thể kết nối đến máy chủ.',
        errorCode: 'HTTP_ERROR',
      );
    }
  }

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    Map<String, dynamic> decoded = {};

    if (response.body.isNotEmpty) {
      try {
        final result = jsonDecode(response.body);

        if (result is Map<String, dynamic>) {
          decoded = result;
        }
      } catch (_) {
        // Response không phải JSON hợp lệ.
      }
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return decoded;
    }

    final message = decoded['message'] as String? ??
        'Có lỗi xảy ra (Mã lỗi: ${response.statusCode}).';

    final errorCode = decoded['error'] as String?;

    throw AuthException(
      message,
      errorCode: errorCode,
      statusCode: response.statusCode,
    );
  }

  void dispose() {
    _client.close();
  }
}
