import '../../../core/network/api_client.dart';
import '../services/pdf_text_extractor_service.dart';

/// Một chủ đề do AI (hoặc người dùng) đề xuất trong bước xem trước của SCR-04.
class ExtractedTopic {
  String name;
  final List<String> keywords;

  /// Các `chunk_index` (bắt đầu từ 1) chứa nội dung của chủ đề này.
  final List<int> chunkIndices;

  ExtractedTopic({
    required this.name,
    this.keywords = const [],
    this.chunkIndices = const [],
  });

  factory ExtractedTopic.fromJson(Map<String, dynamic> json) => ExtractedTopic(
        name: (json['name'] ?? '').toString().trim(),
        keywords: [
          for (final k in (json['keywords'] as List? ?? const [])) k.toString(),
        ],
        chunkIndices: [
          for (final i in (json['chunkIndices'] as List? ?? const []))
            (i as num).toInt(),
        ],
      );
}

class ExtractTopicsResult {
  final String summary;
  final List<ExtractedTopic> topics;
  final int? remainingDaily;

  const ExtractTopicsResult({
    required this.summary,
    required this.topics,
    this.remainingDaily,
  });
}

/// Gọi `POST /api/v1/documents/extract-topics` (backend của M5).
class DocumentApiService {
  const DocumentApiService();

  /// true: gửi header X-Mock-Mode để máy chủ trả dữ liệu mẫu.
  /// Đổi thành false khi M5 tích hợp xong Gemini thật.
  static const bool useMockAi = true;

  /// Ném [ApiException] (từ ApiClient) với các mã như INVALID_INPUT,
  /// DAILY_QUOTA_EXCEEDED, RATE_LIMIT_EXCEEDED, TIMEOUT, NETWORK_ERROR.
  Future<ExtractTopicsResult> extractTopics({
    required String subjectName,
    required String documentTitle,
    required List<DocumentChunk> chunks,
  }) async {
    final response = await ApiClient.instance.post(
      '/api/v1/documents/extract-topics',
      body: {
        'subjectName': subjectName,
        'documentTitle': documentTitle,
        'chunks': [
          for (final c in chunks)
            {
              'chunkIndex': c.chunkIndex,
              'pageLabel': c.pageLabel,
              'content': c.content,
            },
        ],
      },
      useMock: useMockAi,
    );

    final data = (response['data'] as Map<String, dynamic>?) ?? const {};
    final quota = response['quota'] as Map<String, dynamic>?;

    return ExtractTopicsResult(
      summary: (data['summary'] ?? '').toString(),
      topics: [
        for (final t in (data['topics'] as List? ?? const []))
          ExtractedTopic.fromJson(t as Map<String, dynamic>),
      ],
      remainingDaily: (quota?['remainingDaily'] as num?)?.toInt(),
    );
  }
}
