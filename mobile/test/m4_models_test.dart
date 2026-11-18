import 'package:flutter_test/flutter_test.dart';
import 'package:studymate_ai/features/flashcards/models/flashcard_model.dart';
import 'package:studymate_ai/features/quiz/models/attempt_answer_model.dart';
import 'package:studymate_ai/features/quiz/models/quiz_attempt_model.dart';
import 'package:studymate_ai/features/quiz/models/quiz_dto.dart';

void main() {
  group('M4 Data Models & DTOs Unit Tests', () {
    test('QuizAttemptModel serialization & deserialization', () {
      final now = DateTime.now().toIso8601String();
      final attempt = QuizAttemptModel(
        id: 1,
        subjectId: 10,
        score: 80,
        totalQuestions: 5,
        correctCount: 4,
        durationSeconds: 150,
        completedAt: now,
      );

      final map = attempt.toMap();
      expect(map['id'], 1);
      expect(map['subject_id'], 10);
      expect(map['score'], 80);
      expect(map['total_questions'], 5);
      expect(map['correct_count'], 4);
      expect(map['duration_seconds'], 150);
      expect(map['completed_at'], now);

      final fromMapAttempt = QuizAttemptModel.fromMap(map);
      expect(fromMapAttempt.id, 1);
      expect(fromMapAttempt.subjectId, 10);
      expect(fromMapAttempt.score, 80);
      expect(fromMapAttempt.totalQuestions, 5);
      expect(fromMapAttempt.correctCount, 4);
      expect(fromMapAttempt.durationSeconds, 150);
      expect(fromMapAttempt.completedAt, now);
    });

    test('AttemptAnswerModel boolean to integer (SQLite) conversion', () {
      final correctAnswer = AttemptAnswerModel(
        id: 1,
        attemptId: 100,
        questionId: 5,
        selectedIndex: 2,
        isCorrect: true,
      );

      final correctMap = correctAnswer.toMap();
      expect(correctMap['is_correct'], 1);

      final fromMapCorrect = AttemptAnswerModel.fromMap(correctMap);
      expect(fromMapCorrect.isCorrect, isTrue);

      final wrongAnswer = AttemptAnswerModel(
        id: 2,
        attemptId: 100,
        questionId: 6,
        selectedIndex: 0,
        isCorrect: false,
      );

      final wrongMap = wrongAnswer.toMap();
      expect(wrongMap['is_correct'], 0);

      final fromMapWrong = AttemptAnswerModel.fromMap(wrongMap);
      expect(fromMapWrong.isCorrect, isFalse);
    });

    test('FlashcardModel default values & SM-2 fields integrity', () {
      final now = DateTime.now().toIso8601String();
      final card = FlashcardModel(
        subjectId: 1,
        topicId: 2,
        frontText: 'Khái niệm Provider?',
        frontCode: 'context.watch<T>()',
        backText: 'Lắng nghe thay đổi dữ liệu',
        nextReviewAt: now,
      );

      // Kiểm tra giá trị khởi tạo mặc định của thuật toán SM-2
      expect(card.repetition, 0);
      expect(card.interval, 0);
      expect(card.easeFactor, 2.5);

      final map = card.toMap();
      expect(map['subject_id'], 1);
      expect(map['topic_id'], 2);
      expect(map['ease_factor'], 2.5);
      expect(map['repetition'], 0);
      expect(map['interval'], 0);

      final fromMapCard = FlashcardModel.fromMap(map);
      expect(fromMapCard.frontText, 'Khái niệm Provider?');
      expect(fromMapCard.frontCode, 'context.watch<T>()');
      expect(fromMapCard.easeFactor, 2.5);
    });

    test('QuizGenerateRequest & QuizGenerateResponse JSON contract matches Backend M5', () {
      final request = QuizGenerateRequest(
        programmingLanguage: 'Dart / Flutter',
        difficulty: 'MEDIUM',
        questionCount: 5,
        questionTypes: ['CONCEPT', 'SPOT_BUG'],
        topics: [
          QuizTopicRef(topicId: 3, topicName: 'Widget Rebuild Lifecycle'),
        ],
      );

      final jsonReq = request.toJson();
      expect(jsonReq['programmingLanguage'], 'Dart / Flutter');
      expect(jsonReq['difficulty'], 'MEDIUM');
      expect(jsonReq['questionCount'], 5);
      expect(jsonReq['questionTypes'], ['CONCEPT', 'SPOT_BUG']);
      expect((jsonReq['topics'] as List).length, 1);

      // Giả lập Payload chuẩn mà Backend M5 (Node.js) trả về
      final backendMockPayload = {
        'success': true,
        'quota': {
          'remainingDaily': 19,
          'maxDaily': 20,
        },
        'data': {
          'questions': [
            {
              'topicId': 3,
              'questionType': 'SPOT_BUG',
              'questionText': 'Đoạn code có lỗi tiềm ẩn ở dòng nào?',
              'codeSnippet': '1  class AddButton extends StatelessWidget ...',
              'options': ['Dòng 1', 'Dòng 4: Không gọi watch trong callback', 'Dòng 6', 'Đúng'],
              'correctIndex': 1,
              'explanation': 'Phải dùng context.read thay vì context.watch.',
            }
          ]
        }
      };

      final response = QuizGenerateResponse.fromJson(backendMockPayload);
      expect(response.success, isTrue);
      expect(response.quota?.remainingDaily, 19);
      expect(response.quota?.maxDaily, 20);
      expect(response.questions.length, 1);

      final q = response.questions.first;
      expect(q.topicId, 3);
      expect(q.questionType, 'SPOT_BUG');
      expect(q.correctIndex, 1);
      expect(q.options.length, 4);
      expect(q.options[1], 'Dòng 4: Không gọi watch trong callback');
    });
  });
}
