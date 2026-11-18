import '../../../../core/models/shared_models.dart';

/// DTO tham chiếu chủ đề cần sinh câu hỏi
class QuizTopicRef {
  final int topicId;
  final String topicName;
  final String? referenceContent;

  QuizTopicRef({
    required this.topicId,
    required this.topicName,
    this.referenceContent,
  });

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'topicName': topicName,
        if (referenceContent != null) 'referenceContent': referenceContent,
      };

  factory QuizTopicRef.fromJson(Map<String, dynamic> json) => QuizTopicRef(
        topicId: (json['topicId'] as num).toInt(),
        topicName: json['topicName'] as String,
        referenceContent: json['referenceContent'] as String?,
      );
}

/// DTO gửi lên Backend Node.js endpoint: POST /api/v1/quiz/generate
class QuizGenerateRequest {
  final String programmingLanguage;
  final String difficulty; // 'EASY' | 'MEDIUM' | 'HARD'
  final int questionCount; // 5 hoặc 10 câu
  final List<String> questionTypes; // ['CONCEPT', 'PREDICT_OUTPUT', 'SPOT_BUG']
  final List<QuizTopicRef> topics;

  QuizGenerateRequest({
    this.programmingLanguage = 'Dart / Flutter',
    this.difficulty = 'MEDIUM',
    this.questionCount = 5,
    this.questionTypes = const ['CONCEPT', 'PREDICT_OUTPUT', 'SPOT_BUG'],
    required this.topics,
  });

  Map<String, dynamic> toJson() => {
        'programmingLanguage': programmingLanguage,
        'difficulty': difficulty,
        'questionCount': questionCount,
        'questionTypes': questionTypes,
        'topics': topics.map((t) => t.toJson()).toList(),
      };
}

/// DTO hứng thông tin hạn mức gọi AI trong ngày do Backend Node.js trả về
class QuotaInfo {
  final int remainingDaily;
  final int maxDaily;

  QuotaInfo({
    required this.remainingDaily,
    required this.maxDaily,
  });

  factory QuotaInfo.fromJson(Map<String, dynamic> json) => QuotaInfo(
        remainingDaily: (json['remainingDaily'] as num?)?.toInt() ?? 0,
        maxDaily: (json['maxDaily'] as num?)?.toInt() ?? 20,
      );

  Map<String, dynamic> toJson() => {
        'remainingDaily': remainingDaily,
        'maxDaily': maxDaily,
      };
}

/// DTO hứng dữ liệu phản hồi từ Backend Node.js endpoint: POST /api/v1/quiz/generate
class QuizGenerateResponse {
  final bool success;
  final QuotaInfo? quota;
  final List<QuestionModel> questions;

  QuizGenerateResponse({
    required this.success,
    this.quota,
    required this.questions,
  });

  factory QuizGenerateResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    final quota = json['quota'] != null
        ? QuotaInfo.fromJson(json['quota'] as Map<String, dynamic>)
        : null;

    final data = json['data'] as Map<String, dynamic>?;
    final questionsList = (data?['questions'] as List<dynamic>?) ?? [];

    final questions = questionsList.map((q) {
      final qMap = q as Map<String, dynamic>;
      return QuestionModel(
        id: qMap['id'] as int?,
        topicId: (qMap['topicId'] as num?)?.toInt() ??
            (qMap['topic_id'] as num?)?.toInt() ??
            0,
        questionType: (qMap['questionType'] ?? qMap['question_type']) as String,
        questionText: (qMap['questionText'] ?? qMap['question_text']) as String,
        codeSnippet:
            (qMap['codeSnippet'] ?? qMap['code_snippet']) as String?,
        options: List<String>.from(qMap['options'] as List),
        correctIndex: (qMap['correctIndex'] ?? qMap['correct_index'] as num).toInt(),
        explanation: (qMap['explanation'] as String?) ?? '',
      );
    }).toList();

    return QuizGenerateResponse(
      success: success,
      quota: quota,
      questions: questions,
    );
  }
}
