import 'package:flutter_test/flutter_test.dart';
import 'package:studymate_ai/features/tutor/services/sse_event_parser.dart';

Future<List<TutorStreamEvent>> _parse(List<String> lines) {
  return SseEventParser.parse(Stream.fromIterable(lines)).toList();
}

void main() {
  group('SseEventParser', () {
    test('đọc đúng chuỗi chunk rồi done theo định dạng của Backend', () async {
      final events = await _parse([
        'data: {"type":"chunk","text":"Xin chào "}',
        '',
        'data: {"type":"chunk","text":"Flutter"}',
        '',
        'data: {"type":"done","citations":["Trang 12"],"quota":{"remainingDaily":17,"maxDaily":20}}',
        '',
      ]);

      expect(events.length, 3);
      expect((events[0] as TutorChunkEvent).text, 'Xin chào ');
      expect((events[1] as TutorChunkEvent).text, 'Flutter');

      final done = events[2] as TutorDoneEvent;
      expect(done.citations, ['Trang 12']);
      expect(done.remainingDaily, 17);
      expect(done.maxDaily, 20);
    });

    test('giữ nguyên ký tự xuống dòng và khối code trong text', () async {
      final events = await _parse([
        r'data: {"type":"chunk","text":"```dart\nfinal a = 1;\n```\n"}',
        '',
      ]);

      expect(events.length, 1);
      expect(
        (events.first as TutorChunkEvent).text,
        '```dart\nfinal a = 1;\n```\n',
      );
    });

    test('bỏ qua dòng comment, trường lạ và gói tin JSON hỏng', () async {
      final events = await _parse([
        ': heartbeat',
        'event: message',
        'data: {khong phai json',
        '',
        'data: {"type":"chunk","text":"ok"}',
        '',
      ]);

      expect(events.length, 1);
      expect((events.first as TutorChunkEvent).text, 'ok');
    });

    test('vẫn xử lý gói tin cuối khi luồng đóng mà thiếu dòng trống', () async {
      final events = await _parse([
        'data: {"type":"done","citations":[]}',
      ]);

      expect(events.length, 1);
      final done = events.first as TutorDoneEvent;
      expect(done.citations, isEmpty);
      expect(done.remainingDaily, isNull);
    });

    test('nhận diện sự kiện error', () async {
      final events = await _parse([
        'data: {"type":"error","message":"Gemini Stream chưa cấu hình"}',
        '',
      ]);

      expect(events.length, 1);
      expect(
        (events.first as TutorErrorEvent).message,
        'Gemini Stream chưa cấu hình',
      );
    });

    test('bỏ qua sự kiện có type không xác định', () async {
      final events = await _parse([
        'data: {"type":"ping"}',
        '',
      ]);

      expect(events, isEmpty);
    });
  });
}
