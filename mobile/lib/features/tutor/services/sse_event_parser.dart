import 'dart:async';
import 'dart:convert';

/// Các loại sự kiện Backend đẩy về qua luồng SSE của POST /api/v1/tutor/stream:
///   data: {"type":"chunk","text":"..."}
///   data: {"type":"done","citations":["Trang 12"],"quota":{"remainingDaily":17,"maxDaily":20}}
///   data: {"type":"error","message":"..."}
sealed class TutorStreamEvent {
  const TutorStreamEvent();
}

class TutorChunkEvent extends TutorStreamEvent {
  const TutorChunkEvent(this.text);

  final String text;
}

class TutorDoneEvent extends TutorStreamEvent {
  const TutorDoneEvent({
    this.citations = const [],
    this.remainingDaily,
    this.maxDaily,
  });

  /// Nhãn trang AI đã trích dẫn, VD: ["Trang 12"].
  final List<String> citations;
  final int? remainingDaily;
  final int? maxDaily;
}

class TutorErrorEvent extends TutorStreamEvent {
  const TutorErrorEvent(this.message);

  final String message;
}

/// Bộ phân tích luồng SSE thuần Dart (không phụ thuộc Flutter hay mạng)
/// để dễ viết Unit Test.
class SseEventParser {
  const SseEventParser._();

  /// [lines] là luồng các dòng văn bản (đã tách bằng LineSplitter).
  /// Một sự kiện kết thúc khi gặp dòng trống; các dòng `data:` liên tiếp
  /// được nối bằng '\n' theo chuẩn SSE.
  static Stream<TutorStreamEvent> parse(Stream<String> lines) async* {
    final dataBuffer = StringBuffer();

    await for (final line in lines) {
      if (line.isEmpty) {
        final event = _dispatch(dataBuffer);
        if (event != null) {
          yield event;
        }
        continue;
      }

      // Dòng bắt đầu bằng ':' là comment / heartbeat, bỏ qua.
      if (line.startsWith(':')) {
        continue;
      }

      if (line.startsWith('data:')) {
        var value = line.substring(5);
        if (value.startsWith(' ')) {
          value = value.substring(1);
        }
        if (dataBuffer.isNotEmpty) {
          dataBuffer.write('\n');
        }
        dataBuffer.write(value);
      }
      // Các trường event:, id:, retry: không dùng tới nên bỏ qua.
    }

    // Luồng đóng mà chưa có dòng trống cuối cùng: vẫn xử lý phần còn lại.
    final tail = _dispatch(dataBuffer);
    if (tail != null) {
      yield tail;
    }
  }

  static TutorStreamEvent? _dispatch(StringBuffer buffer) {
    if (buffer.isEmpty) {
      return null;
    }
    final raw = buffer.toString();
    buffer.clear();

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null; // Gói tin hỏng: bỏ qua thay vì làm sập cả luồng.
    }
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    switch (decoded['type']) {
      case 'chunk':
        return TutorChunkEvent(decoded['text']?.toString() ?? '');
      case 'done':
        final rawCitations = decoded['citations'];
        final quota = decoded['quota'];
        return TutorDoneEvent(
          citations: rawCitations is List
              ? rawCitations.map((e) => e.toString()).toList()
              : const [],
          remainingDaily:
              quota is Map ? (quota['remainingDaily'] as num?)?.toInt() : null,
          maxDaily: quota is Map ? (quota['maxDaily'] as num?)?.toInt() : null,
        );
      case 'error':
        return TutorErrorEvent(
          decoded['message']?.toString() ?? 'AI gặp lỗi không xác định.',
        );
      default:
        return null;
    }
  }
}
