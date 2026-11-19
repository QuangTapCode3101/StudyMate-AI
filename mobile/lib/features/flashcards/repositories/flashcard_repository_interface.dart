/// Interface định nghĩa các phương thức thao tác dữ liệu cho Module Flashcards SM-2 (M4)
/// Tuân thủ quy tắc Repository Pattern trong kiến trúc MVVM.
abstract class IFlashcardRepository {
  /// Lấy danh sách thẻ Flashcard đến hạn ôn tập hôm nay của một môn:
  /// WHERE subject_id = ? AND next_review_at <= datetime('now')
  Future<List<Map<String, dynamic>>> getDueFlashcards(int subjectId);

  /// Đếm số lượng thẻ đến hạn ôn tập của từng môn học (hiển thị trên SCR-09 Sub-tab 1)
  Future<int> getDueCountBySubject(int subjectId);

  /// Cập nhật kết quả sau khi đánh giá 1 thẻ bằng thuật toán SM-2:
  /// Cập nhật repetition, interval, ease_factor và next_review_at
  Future<void> updateSm2Review({
    required int cardId,
    required int repetition,
    required int interval,
    required double easeFactor,
    required String nextReviewAt,
  });

  /// Tạo hàng loạt thẻ ghi nhớ mới từ các câu làm sai trong bài Quiz
  /// Được kích hoạt khi người dùng bấm nút [+ Tạo Flashcard từ X câu làm sai] trên SCR-08
  Future<int> createFlashcardsFromFailedAnswers(
    List<Map<String, dynamic>> failedCardData,
  );
}
