import 'package:flutter_test/flutter_test.dart';
import 'package:studymate_ai/features/tutor/utils/markdown_segmenter.dart';

void main() {
  group('MarkdownSegmenter.split', () {
    test('tách văn bản - khối code - văn bản', () {
      const source = 'Giải thích:\n'
          '```dart\n'
          'final a = 1;\n'
          'print(a);\n'
          '```\n'
          'Hết.';

      final segments = MarkdownSegmenter.split(source);

      expect(segments.length, 3);
      expect(segments[0].isCode, isFalse);
      expect(segments[0].content, 'Giải thích:');
      expect(segments[1].isCode, isTrue);
      expect(segments[1].language, 'dart');
      expect(segments[1].content, 'final a = 1;\nprint(a);');
      expect(segments[2].isCode, isFalse);
      expect(segments[2].content, 'Hết.');
    });

    test('khối code chưa đóng khi đang stream vẫn hiển thị là code', () {
      const source = 'Ví dụ:\n```dart\nfinal counter = context.watch<Counter>();';

      final segments = MarkdownSegmenter.split(source);

      expect(segments.length, 2);
      expect(segments[1].isCode, isTrue);
      expect(
        segments[1].content,
        'final counter = context.watch<Counter>();',
      );
    });

    test('mở khối code mà chưa có dòng nào thì chưa tạo khối rỗng', () {
      final segments = MarkdownSegmenter.split('Ví dụ:\n```dart\n');

      expect(segments.length, 1);
      expect(segments.first.isCode, isFalse);
    });

    test('ngôn ngữ lạ hoặc thiếu rơi về dart, alias được chuẩn hóa', () {
      expect(MarkdownSegmenter.normalizeLanguage(null), 'dart');
      expect(MarkdownSegmenter.normalizeLanguage('brainfuck'), 'dart');
      expect(MarkdownSegmenter.normalizeLanguage('JS'), 'javascript');
      expect(MarkdownSegmenter.normalizeLanguage('html'), 'xml');
    });

    test('chuỗi rỗng không tạo đoạn nào', () {
      expect(MarkdownSegmenter.split(''), isEmpty);
    });
  });
}
