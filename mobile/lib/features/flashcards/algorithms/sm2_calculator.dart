import 'dart:math' as math;

/// Kết quả đầu ra của thuật toán SuperMemo-2 (SM-2)
class Sm2Result {
  /// Số lần nhớ liên tiếp thành công
  final int repetition;

  /// Khoảng cách ngày đến lần ôn tập tiếp theo (đơn vị: ngày)
  final int interval;

  /// Hệ số độ dễ của thẻ (luôn >= 1.3)
  final double easeFactor;

  /// Thời điểm ôn tập tiếp theo dạng DateTime
  final DateTime nextReviewDate;

  /// Thời điểm ôn tập tiếp theo dạng ISO8601 String để lưu vào SQLite
  final String nextReviewAt;

  const Sm2Result({
    required this.repetition,
    required this.interval,
    required this.easeFactor,
    required this.nextReviewDate,
    required this.nextReviewAt,
  });

  @override
  String toString() =>
      'Sm2Result(repetition: $repetition, interval: $interval, easeFactor: $easeFactor, nextReviewAt: $nextReviewAt)';
}

/// Bộ tính toán thuật toán lặp lại ngắt quãng SuperMemo-2 (SM-2)
/// Áp dụng cho 4 nút đánh giá ở màn hình ôn tập SCR-10:
/// - Again (q = 1): Quên hoàn toàn
/// - Hard (q = 3): Nhớ nhưng khó khăn
/// - Good (q = 4): Nhớ tốt sau một chút suy nghĩ
/// - Easy (q = 5): Nhớ ngay lập tức và chính xác
class Sm2Calculator {
  /// Giới hạn sàn tối thiểu của Ease Factor theo quy chuẩn SM-2
  static const double minEaseFactor = 1.3;

  /// Giá trị Ease Factor mặc định khi mới tạo thẻ
  static const double defaultEaseFactor = 2.5;

  /// Tính toán trạng thái ôn tập mới dựa trên đánh giá của người dùng
  ///
  /// [quality]: Điểm chất lượng nhớ (1: Again, 3: Hard, 4: Good, 5: Easy)
  /// [repetition]: Số lần nhớ liên tiếp hiện tại của thẻ
  /// [interval]: Khoảng cách ngày ôn tập hiện tại của thẻ
  /// [easeFactor]: Hệ số độ dễ hiện tại của thẻ (mặc định 2.5)
  /// [baseDate]: Mốc thời gian làm căn cứ tính ngày tiếp theo (mặc định DateTime.now())
  static Sm2Result calculate({
    required int quality,
    required int repetition,
    required int interval,
    double easeFactor = defaultEaseFactor,
    DateTime? baseDate,
  }) {
    assert(
      quality == 1 || quality == 3 || quality == 4 || quality == 5,
      'Điểm quality phải thuộc tập {1, 3, 4, 5}',
    );

    int newRepetition;
    int newInterval;

    // 1. Tính toán Interval và Repetition
    if (quality < 3) {
      // Người dùng quên thẻ (Again - q=1)
      // Reset số lần nhớ liên tiếp về 0 và chu kỳ về 1 ngày
      newRepetition = 0;
      newInterval = 1;
    } else {
      // Người dùng nhớ được thẻ (Hard, Good, Easy - q >= 3)
      if (repetition == 0) {
        newInterval = 1;
      } else if (repetition == 1) {
        newInterval = 3;
      } else {
        newInterval = (interval * easeFactor).round();
      }
      newRepetition = repetition + 1;
    }

    // 2. Cập nhật Ease Factor (EF') theo công thức toán học SM-2:
    // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final diff = 5 - quality;
    final delta = 0.1 - diff * (0.08 + diff * 0.02);
    double newEaseFactor = easeFactor + delta;

    // Ràng buộc giới hạn sàn: EF' không bao giờ nhỏ hơn 1.3
    newEaseFactor = math.max(minEaseFactor, newEaseFactor);

    // Làm tròn đến 4 chữ số thập phân để tránh sai số số thực trong Dart
    newEaseFactor = double.parse(newEaseFactor.toStringAsFixed(4));

    // 3. Tính toán thời điểm ôn tập tiếp theo
    final effectiveBaseDate = baseDate ?? DateTime.now();
    final nextReviewDate = effectiveBaseDate.add(Duration(days: newInterval));
    final nextReviewAt = nextReviewDate.toIso8601String();

    return Sm2Result(
      repetition: newRepetition,
      interval: newInterval,
      easeFactor: newEaseFactor,
      nextReviewDate: nextReviewDate,
      nextReviewAt: nextReviewAt,
    );
  }
}
