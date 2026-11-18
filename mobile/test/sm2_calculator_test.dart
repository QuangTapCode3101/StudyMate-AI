import 'package:flutter_test/flutter_test.dart';
import 'package:studymate_ai/features/flashcards/algorithms/sm2_calculator.dart';

void main() {
  group('Thuật toán Spaced Repetition SM-2 Unit Tests (TASK-503)', () {
    final fixedBaseDate = DateTime(2026, 11, 18, 10, 0, 0);

    test('Case 1: Quên thẻ (Again, q=1) -> reset repetition=0 va interval=1 ngay', () {
      // Giả lập thẻ đã nhớ 4 lần liên tiếp, chu kỳ 18 ngày, easeFactor 2.5
      final result = Sm2Calculator.calculate(
        quality: 1, // Again
        repetition: 4,
        interval: 18,
        easeFactor: 2.5,
        baseDate: fixedBaseDate,
      );

      // Bấm Again bắt buộc reset repetition về 0 và interval về 1 ngày
      expect(result.repetition, 0);
      expect(result.interval, 1);
      // EF' = 2.5 + (0.1 - 4 * (0.08 + 4 * 0.02)) = 2.5 + (0.1 - 0.64) = 1.96
      expect(result.easeFactor, 1.96);
      expect(result.nextReviewDate, fixedBaseDate.add(const Duration(days: 1)));
      expect(result.nextReviewAt, fixedBaseDate.add(const Duration(days: 1)).toIso8601String());
    });

    test('Case 2: Học thẻ mới lần đầu đánh giá Good (q=4, repetition=0) -> interval=1 ngay', () {
      final result = Sm2Calculator.calculate(
        quality: 4, // Good
        repetition: 0,
        interval: 0,
        easeFactor: 2.5,
        baseDate: fixedBaseDate,
      );

      expect(result.repetition, 1);
      expect(result.interval, 1);
      // Khi q=4, delta = 0.1 - 1 * (0.08 + 0.02) = 0 -> EF giữ nguyên 2.5
      expect(result.easeFactor, 2.5);
      expect(result.nextReviewDate, fixedBaseDate.add(const Duration(days: 1)));
    });

    test('Case 3: Thẻ học lần thứ hai đánh giá Good (q=4, repetition=1) -> interval=3 ngay', () {
      final result = Sm2Calculator.calculate(
        quality: 4, // Good
        repetition: 1,
        interval: 1,
        easeFactor: 2.5,
        baseDate: fixedBaseDate,
      );

      expect(result.repetition, 2);
      expect(result.interval, 3);
      expect(result.easeFactor, 2.5);
      expect(result.nextReviewDate, fixedBaseDate.add(const Duration(days: 3)));
    });

    test('Case 4: Thẻ học lần thứ ba đánh giá Good (q=4, repetition=2, interval=3) -> interval tang theo cap so nhan', () {
      final result = Sm2Calculator.calculate(
        quality: 4, // Good
        repetition: 2,
        interval: 3,
        easeFactor: 2.5,
        baseDate: fixedBaseDate,
      );

      expect(result.repetition, 3);
      // interval = (3 * 2.5).round() = 8
      expect(result.interval, 8);
      expect(result.easeFactor, 2.5);
      expect(result.nextReviewDate, fixedBaseDate.add(const Duration(days: 8)));
    });

    test('Case 5: Ràng buộc giới hạn sàn Ease Factor (EF >= 1.3)', () {
      // Giả lập thẻ liên tục bị quên (Again) nhiều lần khiến EF giảm mạnh
      double currentEf = 1.4;
      final result = Sm2Calculator.calculate(
        quality: 1, // Again làm giảm EF đi 0.54
        repetition: 2,
        interval: 5,
        easeFactor: currentEf,
        baseDate: fixedBaseDate,
      );

      // 1.4 - 0.54 = 0.86, nhưng bị chặn sàn tối thiểu là 1.3
      expect(result.easeFactor, 1.3);
      expect(result.easeFactor >= Sm2Calculator.minEaseFactor, isTrue);
    });

    test('Case 6: Đánh giá Easy (q=5) lam tang EF va Hard (q=3) lam giam EF hop ly', () {
      // Thẻ đánh giá Easy (q=5)
      final easyResult = Sm2Calculator.calculate(
        quality: 5, // Easy
        repetition: 2,
        interval: 3,
        easeFactor: 2.5,
        baseDate: fixedBaseDate,
      );
      // q=5: delta = 0.1 - 0 = +0.1 -> EF = 2.6
      expect(easyResult.easeFactor, 2.6);
      expect(easyResult.repetition, 3);
      expect(easyResult.interval, (3 * 2.5).round());

      // Thẻ đánh giá Hard (q=3)
      final hardResult = Sm2Calculator.calculate(
        quality: 3, // Hard
        repetition: 2,
        interval: 3,
        easeFactor: 2.5,
        baseDate: fixedBaseDate,
      );
      // q=3: delta = 0.1 - 2 * (0.08 + 0.04) = 0.1 - 0.24 = -0.14 -> EF = 2.36
      expect(hardResult.easeFactor, 2.36);
      expect(hardResult.repetition, 3);
      expect(hardResult.interval, (3 * 2.5).round());
    });
  });
}
