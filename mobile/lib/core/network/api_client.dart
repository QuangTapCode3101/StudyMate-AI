import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef JsonMap = Map<String, dynamic>;
typedef HeaderMap = Map<String, String>;

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient instance = ApiClient._init();
  ApiClient._init();

  static const String _prefBaseUrlKey = 'server_base_url';
  static const String _prefDeviceIdKey = 'unique_device_id';
  static const String defaultBaseUrl = 'http://10.0.2.2:3000';

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefBaseUrlKey) ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = newUrl.trim().replaceAll(RegExp(r'/$'), '');
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

  Future<HeaderMap> getHeaders({bool useMock = false}) async {
    final deviceId = await getDeviceId();
    final HeaderMap headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'X-Device-ID': deviceId,
    };
    if (useMock) {
      headers['X-Mock-Mode'] = 'true';
    }
    return headers;
  }

  Future<JsonMap> get(String endpoint) async {
    final baseUrl = await getBaseUrl();
    final headers = await getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
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
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}))
          .timeout(const Duration(seconds: 25));
      return _handleResponse(response);
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

  JsonMap _handleResponse(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as JsonMap;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final errorObj = decoded['error'] as JsonMap?;
    throw ApiException(
      code: errorObj?['code']?.toString() ?? 'HTTP_${response.statusCode}',
      message: errorObj?['message']?.toString() ?? 'Lỗi không xác định từ máy chủ.',
      statusCode: response.statusCode,
    );
  }
}