/// Interface định nghĩa các phương thức thao tác dữ liệu cho Module Quiz (M4)
/// Tuân thủ quy tắc Repository Pattern trong kiến trúc MVVM.
abstract class IQuizRepository {
  /// Lấy danh sách câu hỏi theo chủ đề từ SQLite
  Future<List<Map<String, dynamic>>> getQuestionsByTopic(int topicId);

  /// Lưu câu hỏi từ backend/mock vào bảng questions
  Future<void> saveQuestions(List<Map<String, dynamic>> questions);

  /// Lưu kết quả lượt làm bài (quiz_attempts & attempt_answers) bằng SQLite Transaction
  /// Trả về ID của attempt vừa tạo
  Future<int> saveQuizAttempt({
    required int subjectId,
    required int score,
    required int totalQuestions,
    required int correctCount,
    required int durationSeconds,
    required List<Map<String, dynamic>> answers,
  });

  /// Tính toán lại và cập nhật điểm thông thạo (mastery_score) và số lượt quiz (quiz_count)
  /// trong bảng topics theo đúng công thức:
  /// mastery_score = ROUND( (Tổng câu đúng từ trước đến nay / Tổng câu đã làm) * 100 )
  Future<int> calculateAndUpdateTopicMastery(int topicId);

  /// Lấy lịch sử các lượt thi của một môn học (phục vụ màn hình SCR-08 và SCR-09)
  Future<List<Map<String, dynamic>>> getQuizAttemptsBySubject(int subjectId);
}
