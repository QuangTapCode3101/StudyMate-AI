import 'dart:convert';

/// 5 chế độ Quick Action của AI Tutor.
/// [apiValue] phải khớp với trường `actionMode` mà Backend (TASK-203) nhận.
enum TutorActionMode {
  basic('BASIC', 'Giải thích cơ bản'),
  mechanism('MECHANISM', 'Cơ chế hoạt động'),
  compare('COMPARE', 'So sánh khái niệm'),
  explainCode('EXPLAIN_CODE', 'Giải thích code'),
  pitfalls('PITFALLS', 'Lỗi thường gặp');

  const TutorActionMode(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Câu hỏi mặc định gửi cho AI khi người dùng bấm Quick Action.
  String defaultPrompt(String topicName) {
    return switch (this) {
      TutorActionMode.basic => 'Giải thích cơ bản về "$topicName".',
      TutorActionMode.mechanism =>
        'Giải thích cơ chế hoạt động bên trong của "$topicName".',
      TutorActionMode.compare =>
        'So sánh các khái niệm dễ nhầm lẫn trong "$topicName".',
      TutorActionMode.explainCode =>
        'Giải thích từng dòng code ví dụ của "$topicName".',
      TutorActionMode.pitfalls =>
        'Những lỗi thường gặp khi dùng "$topicName" và cách tránh.',
    };
  }
}

/// Ngữ cảnh học: Môn học + Chủ đề đang được chọn trên thanh AppBar của SCR-05.
class TutorContext {
  const TutorContext({
    required this.subjectId,
    required this.subjectName,
    required this.programmingLanguage,
    required this.topicId,
    required this.topicName,
    required this.documentId,
    this.masteryScore = 0,
  });

  final int subjectId;
  final String subjectName;
  final String programmingLanguage;
  final int topicId;
  final String topicName;
  final int documentId;
  final int masteryScore;

  String get displayTitle => '$subjectName • $topicName';

  factory TutorContext.fromMap(Map<String, dynamic> map) => TutorContext(
        subjectId: map['subject_id'] as int,
        subjectName: map['subject_name'] as String,
        programmingLanguage: map['programming_language'] as String,
        topicId: map['topic_id'] as int,
        topicName: map['topic_name'] as String,
        documentId: map['document_id'] as int,
        masteryScore: (map['mastery_score'] as num?)?.toInt() ?? 0,
      );
}

/// Một đoạn nội dung gốc (bảng document_chunks) dùng làm ngữ cảnh gửi AI
/// và làm nội dung đối chiếu khi bấm vào chip trích dẫn (MDL-01).
class SourceChunkModel {
  const SourceChunkModel({
    required this.documentId,
    required this.documentTitle,
    required this.chunkIndex,
    required this.pageLabel,
    required this.content,
  });

  final int documentId;
  final String documentTitle;
  final int chunkIndex;
  final String pageLabel;
  final String content;

  factory SourceChunkModel.fromMap(Map<String, dynamic> map) =>
      SourceChunkModel(
        documentId: map['document_id'] as int,
        documentTitle: (map['document_title'] as String?) ?? '',
        chunkIndex: map['chunk_index'] as int,
        pageLabel: map['page_label'] as String,
        content: map['content'] as String,
      );

  /// Định dạng đúng theo API Contract: sourceChunks[{pageLabel, content}].
  Map<String, dynamic> toRequestJson() => {
        'pageLabel': pageLabel,
        'content': content,
      };
}

/// Trích dẫn nguồn lưu trong chat_messages.citations_json:
/// [{"docId": 1, "docTitle": "Slide.pdf", "pageLabel": "Trang 12"}]
class CitationModel {
  const CitationModel({
    required this.docId,
    required this.docTitle,
    required this.pageLabel,
  });

  final int docId;
  final String docTitle;
  final String pageLabel;

  Map<String, dynamic> toJson() => {
        'docId': docId,
        'docTitle': docTitle,
        'pageLabel': pageLabel,
      };

  factory CitationModel.fromJson(Map<String, dynamic> json) => CitationModel(
        docId: (json['docId'] as num).toInt(),
        docTitle: json['docTitle']?.toString() ?? '',
        pageLabel: json['pageLabel']?.toString() ?? '',
      );

  static String? encodeList(List<CitationModel> citations) {
    if (citations.isEmpty) {
      return null;
    }
    return jsonEncode(citations.map((c) => c.toJson()).toList());
  }

  static List<CitationModel> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CitationModel.fromJson)
          .toList();
    } catch (_) {
      // Dữ liệu cũ bị hỏng thì bỏ qua trích dẫn, không làm crash màn hình chat.
      return const [];
    }
  }
}

class ChatSessionModel {
  const ChatSessionModel({
    this.id,
    required this.subjectId,
    required this.topicId,
    required this.title,
    required this.createdAt,
    this.messageCount = 0,
  });

  final int? id;
  final int subjectId;
  final int topicId;
  final String title;
  final String createdAt;
  final int messageCount;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'subject_id': subjectId,
        'topic_id': topicId,
        'title': title,
        'created_at': createdAt,
      };

  factory ChatSessionModel.fromMap(Map<String, dynamic> map) =>
      ChatSessionModel(
        id: map['id'] as int?,
        subjectId: map['subject_id'] as int,
        topicId: map['topic_id'] as int,
        title: map['title'] as String,
        createdAt: map['created_at'] as String,
        messageCount: (map['message_count'] as num?)?.toInt() ?? 0,
      );
}

class ChatMessageModel {
  const ChatMessageModel({
    this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.citations = const [],
    required this.createdAt,
    this.isStreaming = false,
  });

  static const String roleUser = 'USER';
  static const String roleAi = 'AI';

  final int? id;
  final int sessionId;
  final String role;
  final String content;
  final List<CitationModel> citations;
  final String createdAt;

  /// Chỉ dùng cho giao diện: bong bóng AI đang nhận chữ chạy dần, chưa lưu SQLite.
  final bool isStreaming;

  bool get isUser => role == roleUser;
  bool get isAi => role == roleAi;

  ChatMessageModel copyWith({
    int? id,
    String? content,
    List<CitationModel>? citations,
    bool? isStreaming,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      sessionId: sessionId,
      role: role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      createdAt: createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'role': role,
        'content': content,
        'citations_json': CitationModel.encodeList(citations),
        'created_at': createdAt,
      };

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) =>
      ChatMessageModel(
        id: map['id'] as int?,
        sessionId: map['session_id'] as int,
        role: map['role'] as String,
        content: map['content'] as String,
        citations: CitationModel.decodeList(map['citations_json'] as String?),
        createdAt: map['created_at'] as String,
      );
}

/// Một câu hỏi trong Mini-Quiz (MDL-02). Không lưu vào SQLite
/// (bảng questions thuộc quyền ghi của M4).
class MiniQuizQuestion {
  const MiniQuizQuestion({
    required this.questionType,
    required this.questionText,
    this.codeSnippet,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String questionType;
  final String questionText;
  final String? codeSnippet;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  bool get isValid => questionText.trim().isNotEmpty && options.length >= 2;

  factory MiniQuizQuestion.fromJson(Map<String, dynamic> json) {
    final options =
        (json['options'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];
    final rawCorrect = (json['correctIndex'] as num?)?.toInt() ?? 0;
    final int correct;
    if (options.isEmpty || rawCorrect < 0) {
      correct = 0;
    } else if (rawCorrect >= options.length) {
      correct = options.length - 1;
    } else {
      correct = rawCorrect;
    }

    final rawCode = json['codeSnippet']?.toString();
    return MiniQuizQuestion(
      questionType: json['questionType']?.toString() ?? 'CONCEPT',
      questionText: json['questionText']?.toString() ?? '',
      codeSnippet: (rawCode == null || rawCode.trim().isEmpty) ? null : rawCode,
      options: options,
      correctIndex: correct,
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}
