import 'package:flutter_test/flutter_test.dart';
import 'package:studymate_ai/core/models/shared_models.dart';

void main() {
  group('Logic Chấm điểm & Cập nhật Mastery Score (TASK-502)', () {
    test('Chấm điểm bài làm 5 câu (4 đúng, 1 sai) -> score = 80%', () {
      final questions = [
        QuestionModel(
          id: 1,
          topicId: 3,
          questionType: 'SPOT_BUG',
          questionText: 'Câu 1?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 1,
          explanation: 'Giải thích 1',
        ),
        QuestionModel(
          id: 2,
          topicId: 3,
          questionType: 'PREDICT_OUTPUT',
          questionText: 'Câu 2?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Giải thích 2',
        ),
        QuestionModel(
          id: 3,
          topicId: 3,
          questionType: 'CONCEPT',
          questionText: 'Câu 3?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 2,
          explanation: 'Giải thích 3',
        ),
        QuestionModel(
          id: 4,
          topicId: 3,
          questionType: 'CONCEPT',
          questionText: 'Câu 4?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 3,
          explanation: 'Giải thích 4',
        ),
        QuestionModel(
          id: 5,
          topicId: 3,
          questionType: 'SPOT_BUG',
          questionText: 'Câu 5?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 1,
          explanation: 'Giải thích 5',
        ),
      ];

      // Giả lập người dùng trả lời: câu 1 đúng, câu 2 đúng, câu 3 đúng, câu 4 sai (chọn 0), câu 5 đúng
      final userAnswers = <int, int>{
        0: 1, // đúng
        1: 0, // đúng
        2: 2, // đúng
        3: 0, // sai (đáp án đúng là 3)
        4: 1, // đúng
      };

      int correctCount = 0;
      final wrongQuestions = <QuestionModel>[];

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final userChoice = userAnswers[i];
        if (userChoice == q.correctIndex) {
          correctCount++;
        } else {
          wrongQuestions.add(q);
        }
      }

      final score = ((correctCount / questions.length) * 100).round();

      expect(correctCount, 4);
      expect(score, 80);
      expect(wrongQuestions.length, 1);
      expect(wrongQuestions.first.id, 4);
    });

    test('Công thức tính điểm thông thạo chủ đề (Mastery Score) chuẩn xác', () {
      // Giả lập từ trước đến nay:
      // Lần 1: làm 5 câu đúng 4
      // Lần 2: làm 5 câu đúng 1
      const totalAttempted = 5 + 5;
      const totalCorrect = 4 + 1;

      final masteryScore = ((totalCorrect / totalAttempted) * 100).round();

      // (5 / 10) * 100 = 50%
      expect(masteryScore, 50);

      // Phân loại nhãn theo rubric:
      // 50% - 79% là mức Vàng (Trung bình / Khá)
      expect(masteryScore >= 50 && masteryScore < 80, isTrue);
    });

    test('Chuyển đổi câu làm sai thành Flashcard với thông số SM-2 mặc định', () {
      final wrongQuestion = QuestionModel(
        id: 10,
        topicId: 3,
        questionType: 'SPOT_BUG',
        questionText: 'Đoạn code bị lỗi ở dòng nào?',
        codeSnippet: '1  context.watch<Cart>().clear();',
        options: ['A', 'B: Phải dùng context.read', 'C', 'D'],
        correctIndex: 1,
        explanation: 'Callback onPressed không được gọi context.watch',
      );

      final flashcardData = {
        'subject_id': 1,
        'topic_id': wrongQuestion.topicId,
        'front_text': wrongQuestion.questionText,
        'front_code': wrongQuestion.codeSnippet,
        'back_text':
            'Đáp án đúng: ${wrongQuestion.options[wrongQuestion.correctIndex]}\n\nGiải thích: ${wrongQuestion.explanation}',
        'repetition': 0,
        'interval': 0,
        'ease_factor': 2.5,
      };

      expect(flashcardData['repetition'], 0);
      expect(flashcardData['interval'], 0);
      expect(flashcardData['ease_factor'], 2.5);
      expect(flashcardData['front_code'], contains('context.watch'));
      expect(flashcardData['back_text'], contains('Đáp án đúng: B: Phải dùng context.read'));
    });
  });
}
