import 'package:flutter_test/flutter_test.dart';
import 'package:studymate_ai/features/flashcards/algorithms/sm2_calculator.dart';
import 'package:studymate_ai/features/flashcards/models/flashcard_model.dart';

void main() {
  group('Quy trình Ôn tập Flashcards SM-2 (TASK-504)', () {
    test('Thẻ đến hạn ôn tập hôm nay: next_review_at <= now', () {
      final now = DateTime.now();

      // Thẻ đến hạn hôm nay (thời điểm trong quá khứ hoặc hiện tại)
      final dueCard = FlashcardModel(
        id: 1,
        subjectId: 1,
        topicId: 2,
        frontText: 'ChangeNotifier là gì?',
        backText: 'Lớp cung cấp thông báo thay đổi cho listeners',
        nextReviewAt: now.subtract(const Duration(hours: 2)).toIso8601String(),
      );

      // Thẻ chưa đến hạn (thời điểm trong tương lai 3 ngày nữa)
      final futureCard = FlashcardModel(
        id: 2,
        subjectId: 1,
        topicId: 2,
        frontText: 'Consumer dùng khi nào?',
        backText: 'Dùng để rebuild widget khi dữ liệu thay đổi',
        nextReviewAt: now.add(const Duration(days: 3)).toIso8601String(),
      );

      final cards = [dueCard, futureCard];
      final dueCards = cards.where((c) {
        return DateTime.parse(c.nextReviewAt).isBefore(now) ||
            DateTime.parse(c.nextReviewAt).isAtSameMomentAs(now);
      }).toList();

      expect(dueCards.length, 1);
      expect(dueCards.first.id, 1);
    });

    test('Đánh giá Good (q=4) đẩy next_review_at sang tương lai và giảm số thẻ đến hạn', () {
      final baseDate = DateTime(2026, 11, 18, 12, 0, 0);

      final card = FlashcardModel(
        id: 1,
        subjectId: 1,
        topicId: 2,
        frontText: 'context.watch vs context.read',
        backText: 'watch lắng nghe thay đổi, read chỉ đọc 1 lần',
        repetition: 0,
        interval: 0,
        easeFactor: 2.5,
        nextReviewAt: baseDate.toIso8601String(),
      );

      // Bấm Good (q=4)
      final sm2Result = Sm2Calculator.calculate(
        quality: 4,
        repetition: card.repetition,
        interval: card.interval,
        easeFactor: card.easeFactor,
        baseDate: baseDate,
      );

      // Cập nhật card với thông số mới
      final updatedCard = card.copyWith(
        repetition: sm2Result.repetition,
        interval: sm2Result.interval,
        easeFactor: sm2Result.easeFactor,
        nextReviewAt: sm2Result.nextReviewAt,
      );

      // Kiểm tra chu kỳ mới
      expect(updatedCard.repetition, 1);
      expect(updatedCard.interval, 1);
      expect(updatedCard.easeFactor, 2.5);

      // Ngày ôn tiếp theo đã được đẩy sang ngày mai (tương lai so với baseDate)
      final nextDate = DateTime.parse(updatedCard.nextReviewAt);
      expect(nextDate.isAfter(baseDate), isTrue);

      // Kiểm tra số thẻ đến hạn tại thời điểm baseDate giảm về 0
      final isStillDue = nextDate.isBefore(baseDate) || nextDate.isAtSameMomentAs(baseDate);
      expect(isStillDue, isFalse);
    });

    test('Đánh giá Again (q=1) reset chu kỳ về 1 ngày và giảm Ease Factor', () {
      final baseDate = DateTime(2026, 11, 18, 12, 0, 0);

      // Giả lập thẻ đã từng nhớ 3 lần
      final card = FlashcardModel(
        id: 5,
        subjectId: 1,
        topicId: 2,
        frontText: 'Widget Rebuild Lifecycle',
        backText: 'build(), didChangeDependencies()',
        repetition: 3,
        interval: 8,
        easeFactor: 2.5,
        nextReviewAt: baseDate.toIso8601String(),
      );

      // Người dùng quên thẻ -> Bấm Again (q=1)
      final sm2Result = Sm2Calculator.calculate(
        quality: 1,
        repetition: card.repetition,
        interval: card.interval,
        easeFactor: card.easeFactor,
        baseDate: baseDate,
      );

      expect(sm2Result.repetition, 0);
      expect(sm2Result.interval, 1);
      expect(sm2Result.easeFactor, 1.96);
      expect(sm2Result.nextReviewDate, baseDate.add(const Duration(days: 1)));
    });
  });
}
