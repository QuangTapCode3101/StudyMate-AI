/// Một đoạn nội dung của câu trả lời AI: hoặc là văn bản Markdown thường,
/// hoặc là một khối code (nằm giữa cặp ```).
class MarkdownSegment {
  const MarkdownSegment.text(this.content)
      : isCode = false,
        language = null;

  const MarkdownSegment.code(this.content, this.language) : isCode = true;

  final String content;
  final bool isCode;

  /// Ngôn ngữ đã chuẩn hóa để highlight (chỉ có ý nghĩa khi [isCode] = true).
  final String? language;
}

/// Tách câu trả lời Markdown của AI thành các đoạn văn bản và khối code
/// để khối code luôn hiển thị bằng CodeSnippetBox (nền tối, cuộn ngang, nút Copy).
///
/// Chịu được dữ liệu đang stream dở: khối code chưa có dấu ``` đóng vẫn được
/// coi là khối code đến hết chuỗi hiện tại.
class MarkdownSegmenter {
  const MarkdownSegmenter._();

  /// Ngôn ngữ mà thư viện highlight hỗ trợ ổn định. Ngôn ngữ lạ sẽ rơi về 'dart'
  /// vì highlight có thể ném lỗi khi gặp tên ngôn ngữ không tồn tại.
  static const Map<String, String> _languageAliases = {
    'dart': 'dart',
    'java': 'java',
    'kotlin': 'kotlin',
    'kt': 'kotlin',
    'xml': 'xml',
    'html': 'xml',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'javascript': 'javascript',
    'js': 'javascript',
    'typescript': 'typescript',
    'ts': 'typescript',
    'python': 'python',
    'py': 'python',
    'cpp': 'cpp',
    'c++': 'cpp',
    'bash': 'bash',
    'sh': 'bash',
    'sql': 'sql',
    'css': 'css',
    'swift': 'swift',
  };

  static String normalizeLanguage(String? raw) {
    if (raw == null) {
      return 'dart';
    }
    final key = raw.trim().toLowerCase();
    return _languageAliases[key] ?? 'dart';
  }

  static List<MarkdownSegment> split(String source) {
    final segments = <MarkdownSegment>[];
    final textLines = <String>[];
    final codeLines = <String>[];
    var inCode = false;
    String? currentLanguage;

    void flushText() {
      final text = textLines.join('\n');
      if (text.trim().isNotEmpty) {
        segments.add(MarkdownSegment.text(text));
      }
      textLines.clear();
    }

    void flushCode() {
      final code = codeLines.join('\n');
      if (code.trim().isNotEmpty) {
        segments.add(
          MarkdownSegment.code(code, normalizeLanguage(currentLanguage)),
        );
      }
      codeLines.clear();
    }

    for (final line in source.split('\n')) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('```')) {
        if (inCode) {
          flushCode();
          inCode = false;
          currentLanguage = null;
        } else {
          flushText();
          inCode = true;
          final info = trimmed.substring(3).trim();
          currentLanguage = info.isEmpty ? null : info.split(RegExp(r'\s+')).first;
        }
        continue;
      }

      if (inCode) {
        codeLines.add(line);
      } else {
        textLines.add(line);
      }
    }

    if (inCode) {
      flushCode();
    } else {
      flushText();
    }
    return segments;
  }
}
