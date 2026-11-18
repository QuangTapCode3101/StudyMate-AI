import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import 'sse_event_parser.dart';

/// Client đọc luồng Server-Sent Events từ POST /api/v1/tutor/stream (TASK-402).
///
/// Dùng lại baseUrl và header X-Device-ID / X-Mock-Mode của [ApiClient] (M1),
/// nhưng tự mở kết nối bằng `http.Client.send()` vì [ApiClient.post] chỉ đọc
/// được phản hồi khi đã tải xong toàn bộ.
///
/// Mọi lỗi (mất mạng, timeout, HTTP 429...) đều được ném ra dưới dạng
/// [ApiException] để ViewModel hiển thị thông báo và nút [Thử lại].
class SseStreamClient {
  SseStreamClient({http.Client Function()? clientFactory})
      : _clientFactory = clientFactory ?? http.Client.new;

  final http.Client Function() _clientFactory;

  /// Thời gian chờ Server bắt đầu phản hồi.
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Thời gian chờ tối đa giữa 2 gói tin liên tiếp trước khi coi là mất kết nối.
  static const Duration idleTimeout = Duration(seconds: 45);

  /// Mở luồng. Hủy subscription sẽ đóng kết nối HTTP.
  /// Luồng kết thúc bình thường ngay sau khi nhận [TutorDoneEvent].
  Stream<TutorStreamEvent> streamTutor(
    Map<String, dynamic> body, {
    bool useMock = false,
  }) async* {
    final client = _clientFactory();
    try {
      final baseUrl = await ApiClient.instance.getBaseUrl();
      final headers = await ApiClient.instance.getHeaders(useMock: useMock);
      headers['Accept'] = 'text/event-stream';

      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/api/v1/tutor/stream'),
      )
        ..headers.addAll(headers)
        ..body = jsonEncode(body);

      final response = await client.send(request).timeout(connectTimeout);

      if (response.statusCode != 200) {
        final rawBody = await response.stream.bytesToString();
        throw _toApiException(response.statusCode, rawBody);
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(idleTimeout);

      var finished = false;
      await for (final event in SseEventParser.parse(lines)) {
        if (event is TutorErrorEvent) {
          throw ApiException(code: 'AI_STREAM_ERROR', message: event.message);
        }
        yield event;
        if (event is TutorDoneEvent) {
          finished = true;
          break;
        }
      }

      if (!finished) {
        throw ApiException(
          code: 'STREAM_INTERRUPTED',
          message: 'Kết nối bị ngắt giữa chừng, câu trả lời chưa hoàn chỉnh.',
        );
      }
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        code: 'TIMEOUT',
        message: 'Server phản hồi quá chậm hoặc đường truyền bị gián đoạn.',
      );
    } catch (_) {
      throw ApiException(
        code: 'NETWORK_ERROR',
        message:
            'Mất kết nối mạng. Hãy kiểm tra Wi-Fi và địa chỉ Server trong phần cài đặt.',
      );
    } finally {
      client.close();
    }
  }

  ApiException _toApiException(int statusCode, String rawBody) {
    String? code;
    String? message;
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          code = error['code']?.toString();
          message = error['message']?.toString();
        }
      }
    } catch (_) {
      // Phản hồi không phải JSON: dùng thông báo mặc định bên dưới.
    }

    if (statusCode == 429) {
      return ApiException(
        code: code ?? 'RATE_LIMIT_EXCEEDED',
        message: message ?? 'Bạn thao tác quá nhanh hoặc đã hết lượt hỏi AI hôm nay.',
        statusCode: statusCode,
      );
    }
    return ApiException(
      code: code ?? 'HTTP_$statusCode',
      message: message ?? 'Server trả về lỗi ($statusCode).',
      statusCode: statusCode,
    );
  }
}
