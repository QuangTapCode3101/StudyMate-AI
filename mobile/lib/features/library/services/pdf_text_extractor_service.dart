import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Một đoạn văn bản sau khi trích xuất, khớp với bảng `document_chunks`.
///
/// [chunkIndex] bắt đầu từ 1 (giống dữ liệu mẫu trong DatabaseHelper) và là
/// giá trị cần dùng khi gửi `chunk_indices_json` cho API extract-topics.
class DocumentChunk {
  final int chunkIndex;
  final String pageLabel; // 'Trang 12' hoặc 'Đoạn 3'
  final String content;

  const DocumentChunk({
    required this.chunkIndex,
    required this.pageLabel,
    required this.content,
  });

  Map<String, dynamic> toMap() => {
        'chunk_index': chunkIndex,
        'page_label': pageLabel,
        'content': content,
      };
}

/// File PDF dạng ảnh scan, không có lớp chữ để đọc.
class ScannedPdfException implements Exception {
  final String message;
  const ScannedPdfException([
    this.message =
        'File PDF này là bản scan (không có chữ để đọc). Hãy dùng file PDF có thể bôi đen chữ.',
  ]);

  @override
  String toString() => message;
}

/// Khoảng trang người dùng chọn không hợp lệ.
class InvalidPageRangeException implements Exception {
  final String message;
  const InvalidPageRangeException(this.message);

  @override
  String toString() => message;
}

/// TASK-303: đọc PDF theo khoảng trang và chia văn bản thành các đoạn.
class DocumentChunkerService {
  const DocumentChunkerService();

  /// Số trang tối đa được phân tích trong một lần.
  static const int maxPagesPerRun = 15;

  /// Tổng số ký tự tối thiểu để coi PDF là có chữ.
  static const int minTotalChars = 50;

  /// Độ dài mục tiêu của một đoạn với Markdown / Source Code.
  static const int targetChunkChars = 1500;

  /// Đọc tổng số trang của file PDF (để hiện "Tổng: N trang" trên UI).
  int readTotalPages(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    try {
      return document.pages.count;
    } finally {
      document.dispose();
    }
  }

  /// Trích xuất chữ từ trang [startPage] đến [endPage] (đánh số từ 1, gồm cả
  /// hai đầu). Mỗi trang là một chunk có nhãn 'Trang X'.
  ///
  /// Ném [InvalidPageRangeException] nếu khoảng trang sai hoặc quá
  /// [maxPagesPerRun] trang, và [ScannedPdfException] nếu gần như không đọc
  /// được chữ nào.
  List<DocumentChunk> extractPdfChunks(
    Uint8List pdfBytes, {
    required int startPage,
    required int endPage,
  }) {
    final document = PdfDocument(inputBytes: pdfBytes);
    try {
      final totalPages = document.pages.count;

      if (startPage < 1 || endPage < startPage) {
        throw const InvalidPageRangeException(
            'Khoảng trang không hợp lệ. Trang bắt đầu phải nhỏ hơn hoặc bằng trang kết thúc.');
      }
      if (endPage > totalPages) {
        throw InvalidPageRangeException(
            'File chỉ có $totalPages trang. Hãy chọn trang kết thúc nhỏ hơn hoặc bằng $totalPages.');
      }
      if (endPage - startPage + 1 > maxPagesPerRun) {
        throw const InvalidPageRangeException(
            'Mỗi lần chỉ phân tích tối đa $maxPagesPerRun trang. Hãy chọn khoảng trang ngắn hơn.');
      }

      final extractor = PdfTextExtractor(document);
      final chunks = <DocumentChunk>[];
      var totalChars = 0;
      var chunkIndex = 1;

      for (var page = startPage; page <= endPage; page++) {
        // Syncfusion đánh số trang từ 0.
        final text = extractor
            .extractText(startPageIndex: page - 1, endPageIndex: page - 1)
            .trim();
        totalChars += text.length;
        if (text.isEmpty) continue; // bỏ qua trang trắng / trang chỉ có ảnh
        chunks.add(DocumentChunk(
          chunkIndex: chunkIndex++,
          pageLabel: 'Trang $page',
          content: text,
        ));
      }

      if (totalChars < minTotalChars) {
        throw const ScannedPdfException();
      }
      return chunks;
    } finally {
      document.dispose();
    }
  }

  /// Chia văn bản Markdown / Source Code thành các đoạn ~[targetChunkChars]
  /// ký tự, luôn cắt ở dấu xuống dòng. Nhãn là 'Đoạn 1', 'Đoạn 2', ...
  List<DocumentChunk> chunkText(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];

    final pieces = <String>[];
    final buffer = StringBuffer();
    var length = 0;

    void flush() {
      final piece = buffer.toString().trimRight();
      if (piece.isNotEmpty) pieces.add(piece);
      buffer.clear();
      length = 0;
    }

    for (final rawLine in normalized.split('\n')) {
      // Một dòng quá dài (ví dụ file minified): cắt cứng theo độ dài.
      final lines = rawLine.length > targetChunkChars
          ? [
              for (var i = 0; i < rawLine.length; i += targetChunkChars)
                rawLine.substring(
                    i,
                    i + targetChunkChars > rawLine.length
                        ? rawLine.length
                        : i + targetChunkChars)
            ]
          : [rawLine];

      for (final line in lines) {
        // +1 cho dấu xuống dòng.
        if (length > 0 && length + line.length + 1 > targetChunkChars) {
          flush();
        }
        buffer.writeln(line);
        length += line.length + 1;
      }
    }
    flush();

    return [
      for (var i = 0; i < pieces.length; i++)
        DocumentChunk(
          chunkIndex: i + 1,
          pageLabel: 'Đoạn ${i + 1}',
          content: pieces[i],
        ),
    ];
  }
}
