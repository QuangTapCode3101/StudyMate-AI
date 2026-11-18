/// Model đại diện cho một lượt làm bài thi trắc nghiệm kỹ thuật
/// Ánh xạ 1:1 với bảng [quiz_attempts] trong SQLite
class QuizAttemptModel {
  final int? id;
  final int subjectId;
  final int score;
  final int totalQuestions;
  final int correctCount;
  final int durationSeconds;
  final String completedAt; // ISO8601 String

  QuizAttemptModel({
    this.id,
    required this.subjectId,
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.durationSeconds,
    required this.completedAt,
  });

  /// Chuyển đổi thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'subject_id': subjectId,
        'score': score,
        'total_questions': totalQuestions,
        'correct_count': correctCount,
        'duration_seconds': durationSeconds,
        'completed_at': completedAt,
      };

  /// Khởi tạo từ bản ghi Map lấy từ SQLite
  factory QuizAttemptModel.fromMap(Map<String, dynamic> map) =>
      QuizAttemptModel(
        id: map['id'] as int?,
        subjectId: (map['subject_id'] as num).toInt(),
        score: (map['score'] as num).toInt(),
        totalQuestions: (map['total_questions'] as num).toInt(),
        correctCount: (map['correct_count'] as num).toInt(),
        durationSeconds: (map['duration_seconds'] as num).toInt(),
        completedAt: map['completed_at'] as String,
      );

  QuizAttemptModel copyWith({
    int? id,
    int? subjectId,
    int? score,
    int? totalQuestions,
    int? correctCount,
    int? durationSeconds,
    String? completedAt,
  }) {
    return QuizAttemptModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
