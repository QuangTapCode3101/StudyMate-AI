/// Model đại diện cho một thẻ ghi nhớ theo thuật toán SuperMemo-2 (SM-2)
/// Ánh xạ 1:1 với bảng [flashcards] trong SQLite
class FlashcardModel {
  final int? id;
  final int subjectId;
  final int topicId;
  final String frontText;
  final String? frontCode;
  final String backText;
  final int repetition;
  final int interval;
  final double easeFactor;
  final String nextReviewAt; // ISO8601 String để so sánh <= datetime('now')

  FlashcardModel({
    this.id,
    required this.subjectId,
    required this.topicId,
    required this.frontText,
    this.frontCode,
    required this.backText,
    this.repetition = 0,
    this.interval = 0,
    this.easeFactor = 2.5,
    required this.nextReviewAt,
  });

  /// Chuyển đổi thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'subject_id': subjectId,
        'topic_id': topicId,
        'front_text': frontText,
        'front_code': frontCode,
        'back_text': backText,
        'repetition': repetition,
        'interval': interval,
        'ease_factor': easeFactor,
        'next_review_at': nextReviewAt,
      };

  /// Khởi tạo từ bản ghi Map lấy từ SQLite
  factory FlashcardModel.fromMap(Map<String, dynamic> map) => FlashcardModel(
        id: map['id'] as int?,
        subjectId: (map['subject_id'] as num).toInt(),
        topicId: (map['topic_id'] as num).toInt(),
        frontText: map['front_text'] as String,
        frontCode: map['front_code'] as String?,
        backText: map['back_text'] as String,
        repetition: (map['repetition'] as num?)?.toInt() ?? 0,
        interval: (map['interval'] as num?)?.toInt() ?? 0,
        easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
        nextReviewAt: map['next_review_at'] as String,
      );

  FlashcardModel copyWith({
    int? id,
    int? subjectId,
    int? topicId,
    String? frontText,
    String? frontCode,
    String? backText,
    int? repetition,
    int? interval,
    double? easeFactor,
    String? nextReviewAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      frontText: frontText ?? this.frontText,
      frontCode: frontCode ?? this.frontCode,
      backText: backText ?? this.backText,
      repetition: repetition ?? this.repetition,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    );
  }
}
