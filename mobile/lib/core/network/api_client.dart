import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef JsonMap = Map<String, dynamic>;
typedef HeaderMap = Map<String, String>;
typedef TokenProvider = Future<String?> Function();
typedef UnauthorizedCallback = Future<void> Function();

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient instance = ApiClient._init();
  ApiClient._init();

  static const String _prefBaseUrlKey = 'server_base_url';
  static const String _prefDeviceIdKey = 'unique_device_id';
  static const String defaultBaseUrl =
      'https://backend-divine-moonbeam-7921.fly.dev';

  TokenProvider? _tokenProvider;
  UnauthorizedCallback? _onUnauthorized;
  bool _isHandlingUnauthorized = false;

  /// Gọi 1 lần lúc khởi tạo app để nối ApiClient với AuthService / AuthProvider.
  void configureAuth({
    required TokenProvider tokenProvider,
    UnauthorizedCallback? onUnauthorized,
  }) {
    _tokenProvider = tokenProvider;
    _onUnauthorized = onUnauthorized;
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefBaseUrlKey) ?? defaultBaseUrl;
    return raw.trim().replaceAll(RegExp(r'/+$'), '');
  }

  Future<void> setBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(_prefBaseUrlKey, cleaned);
  }

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_prefDeviceIdKey);
    if (deviceId == null) {
      deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_prefDeviceIdKey, deviceId);
    }
    return deviceId;
  }

  Future<HeaderMap> getHeaders({
    bool useMock = false,
    bool isStream = false,
  }) async {
    final deviceId = await getDeviceId();
    final token = _tokenProvider != null ? await _tokenProvider!() : null;

    final HeaderMap headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': isStream ? 'text/event-stream' : 'application/json',
      'X-Device-ID': deviceId,
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    if (useMock) {
      headers['X-Mock-Mode'] = 'true';
    }

    return headers;
  }

  Future<JsonMap> get(String endpoint) async {
    final baseUrl = await getBaseUrl();
    final headers = await getHeaders();
    final uri = Uri.parse(_joinUrl(baseUrl, endpoint));

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      return await _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        code: 'TIMEOUT',
        message: 'Không thể kết nối tới Server ($baseUrl).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(code: 'NETWORK_ERROR', message: e.toString());
    }
  }

  Future<JsonMap> post(
    String endpoint, {
    JsonMap? body,
    bool useMock = false,
  }) async {
    final baseUrl = await getBaseUrl();
    final headers = await getHeaders(useMock: useMock);
    final uri = Uri.parse(_joinUrl(baseUrl, endpoint));

    try {
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 25));
      return await _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        code: 'TIMEOUT',
        message: 'Yêu cầu xử lý AI quá thời gian chờ (Timeout).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(code: 'NETWORK_ERROR', message: e.toString());
    }
  }

  /// Gửi request POST và trả về luồng raw text chunk (cho SSE streaming).
  Stream<String> streamPost(
    String endpoint, {
    JsonMap? body,
    bool useMock = false,
    Duration timeout = const Duration(seconds: 60),
  }) async* {
    final baseUrl = await getBaseUrl();
    final headers = await getHeaders(useMock: useMock, isStream: true);
    final uri = Uri.parse(_joinUrl(baseUrl, endpoint));
    final client = http.Client();

    try {
      final request = http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = jsonEncode(body ?? <String, dynamic>{});

      final streamedResponse = await client.send(request).timeout(timeout);

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        final errorBody =
            await streamedResponse.stream.bytesToString().timeout(
                  const Duration(seconds: 10),
                  onTimeout: () => '',
                );
        throw await _buildErrorException(
          statusCode: streamedResponse.statusCode,
          rawBody: errorBody,
        );
      }

      yield* streamedResponse.stream.transform(utf8.decoder);
    } on TimeoutException {
      throw ApiException(
        code: 'TIMEOUT',
        message: 'Luồng phản hồi AI quá thời gian chờ (Timeout).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(code: 'NETWORK_ERROR', message: e.toString());
    } finally {
      client.close();
    }
  }

  Future<JsonMap> _handleResponse(http.Response response) async {
    final rawBody = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (rawBody.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(rawBody);
      if (decoded is JsonMap) return decoded;
      return {'data': decoded};
    }

    throw await _buildErrorException(
      statusCode: response.statusCode,
      rawBody: rawBody,
    );
  }

  Future<ApiException> _buildErrorException({
    required int statusCode,
    required String rawBody,
  }) async {
    String? code;
    String? message;

    if (rawBody.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is JsonMap) {
          final errorObj = decoded['error'];
          if (errorObj is JsonMap) {
            code = errorObj['code']?.toString();
            message = errorObj['message']?.toString();
          }
          code ??= decoded['error']?.toString();
          message ??= decoded['message']?.toString();
        }
      } catch (_) {
        // Body lỗi không phải JSON hợp lệ.
      }
    }

    if (statusCode == 401) {
      await _notifyUnauthorized();
    }

    return ApiException(
      code: code ?? 'HTTP_$statusCode',
      message: message ??
          (statusCode == 401
              ? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'
              : 'Lỗi không xác định từ máy chủ (HTTP $statusCode).'),
      statusCode: statusCode,
    );
  }

  Future<void> _notifyUnauthorized() async {
    final callback = _onUnauthorized;
    if (callback == null || _isHandlingUnauthorized) return;

    _isHandlingUnauthorized = true;
    try {
      await callback();
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  String _joinUrl(String baseUrl, String endpoint) {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$cleanBase$cleanEndpoint';
  }
}