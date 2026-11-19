/// Model lưu chi tiết từng câu trả lời trong một lượt thi
/// Ánh xạ 1:1 với bảng [attempt_answers] trong SQLite
class AttemptAnswerModel {
  final int? id;
  final int attemptId;
  final int questionId;
  final int selectedIndex;
  final bool isCorrect;

  AttemptAnswerModel({
    this.id,
    required this.attemptId,
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
  });

  /// Chuyển đổi thành Map để lưu vào SQLite (isCorrect chuyển thành 1 hoặc 0)
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'attempt_id': attemptId,
        'question_id': questionId,
        'selected_index': selectedIndex,
        'is_correct': isCorrect ? 1 : 0,
      };

  /// Khởi tạo từ bản ghi Map lấy từ SQLite
  factory AttemptAnswerModel.fromMap(Map<String, dynamic> map) =>
      AttemptAnswerModel(
        id: map['id'] as int?,
        attemptId: (map['attempt_id'] as num).toInt(),
        questionId: (map['question_id'] as num).toInt(),
        selectedIndex: (map['selected_index'] as num).toInt(),
        isCorrect: (map['is_correct'] as int) == 1,
      );
}
