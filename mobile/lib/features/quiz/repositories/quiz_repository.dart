import '../../../core/database/database_helper.dart';
import '../../../core/models/shared_models.dart';
import '../../../core/network/api_client.dart';
import '../models/quiz_dto.dart';
import 'quiz_repository_interface.dart';

class QuizRepository implements IQuizRepository {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient;

  QuizRepository({
    DatabaseHelper? dbHelper,
    ApiClient? apiClient,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _apiClient = apiClient ?? ApiClient.instance;

  /// Lấy danh sách tất cả môn học trong SQLite
  Future<List<SubjectModel>> getSubjects() async {
    final db = await _dbHelper.database;
    final maps = await db.query('subjects', orderBy: 'id ASC');
    return maps.map((m) => SubjectModel.fromMap(m)).toList();
  }

  /// Lấy danh sách các chủ đề theo môn học
  Future<List<TopicModel>> getTopicsBySubject(int subjectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'topics',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => TopicModel.fromMap(m)).toList();
  }

  /// Lấy thông tin 1 chủ đề cụ thể
  Future<TopicModel?> getTopicById(int topicId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'topics',
      where: 'id = ?',
      whereArgs: [topicId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TopicModel.fromMap(maps.first);
  }

  @override
  Future<List<Map<String, dynamic>>> getQuestionsByTopic(int topicId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'questions',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'id ASC',
    );
  }

  @override
  Future<void> saveQuestions(List<Map<String, dynamic>> questions) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final q in questions) {
      batch.insert('questions', q);
    }
    await batch.commit(noResult: true);
  }

  /// Gọi API Backend Node.js sinh đề câu hỏi kỹ thuật (hỗ trợ Mock Mode theo Rubric)
  /// Nếu mất mạng hoặc backend offline, tự động fallback lấy câu hỏi mẫu có sẵn trong SQLite
  Future<QuizGenerateResponse> generateQuiz({
    required String programmingLanguage,
    required String difficulty,
    required int questionCount,
    required List<String> questionTypes,
    required List<QuizTopicRef> topics,
  }) async {
    final request = QuizGenerateRequest(
      programmingLanguage: programmingLanguage,
      difficulty: difficulty,
      questionCount: questionCount,
      questionTypes: questionTypes,
      topics: topics,
    );

    try {
      final jsonResponse = await _apiClient.post(
        '/api/v1/quiz/generate',
        body: request.toJson(),
        useMock: false,
      );

      final response = QuizGenerateResponse.fromJson(jsonResponse);

      // Lưu các câu hỏi vừa nhận được vào SQLite nếu chưa có
      if (response.questions.isNotEmpty) {
        final db = await _dbHelper.database;
        for (final q in response.questions) {
          final existing = await db.query(
            'questions',
            where: 'topic_id = ? AND question_text = ?',
            whereArgs: [q.topicId, q.questionText],
          );
          if (existing.isEmpty) {
            await db.insert('questions', q.toMap());
          }
        }
      }

      return response;
    } catch (_) {
      // Fallback: Khi offline hoặc backend chưa chạy, đọc câu hỏi từ SQLite
      final fallbackQuestions = <QuestionModel>[];
      for (final t in topics) {
        final rawList = await getQuestionsByTopic(t.topicId);
        fallbackQuestions.addAll(rawList.map((m) => QuestionModel.fromMap(m)));
      }

      if (fallbackQuestions.isNotEmpty) {
        return QuizGenerateResponse(
          success: true,
          quota: QuotaInfo(remainingDaily: 20, maxDaily: 20),
          questions: fallbackQuestions.take(questionCount).toList(),
        );
      }

      rethrow;
    }
  }

  @override
  Future<int> saveQuizAttempt({
    required int subjectId,
    required int score,
    required int totalQuestions,
    required int correctCount,
    required int durationSeconds,
    required List<Map<String, dynamic>> answers,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      // 1. Lưu bản ghi lượt thi vào quiz_attempts
      final attemptId = await txn.insert('quiz_attempts', {
        'subject_id': subjectId,
        'score': score,
        'total_questions': totalQuestions,
        'correct_count': correctCount,
        'duration_seconds': durationSeconds,
        'completed_at': now,
      });

      // 2. Lưu từng câu trả lời vào attempt_answers
      for (final ans in answers) {
        await txn.insert('attempt_answers', {
          'attempt_id': attemptId,
          'question_id': ans['question_id'],
          'selected_index': ans['selected_index'],
          'is_correct': ans['is_correct'],
        });
      }

      return attemptId;
    });
  }

  @override
  Future<int> calculateAndUpdateTopicMastery(int topicId) async {
    final db = await _dbHelper.database;

    // Truy vấn tổng số câu ĐÚNG và tổng số câu ĐÃ LÀM của topic này từ trước đến nay
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_done,
        SUM(CASE WHEN aa.is_correct = 1 THEN 1 ELSE 0 END) as total_correct
      FROM attempt_answers aa
      JOIN questions q ON aa.question_id = q.id
      WHERE q.topic_id = ?
    ''', [topicId]);

    final totalDone = (result.first['total_done'] as num?)?.toInt() ?? 0;
    final totalCorrect = (result.first['total_correct'] as num?)?.toInt() ?? 0;

    int newMasteryScore = 0;
    if (totalDone > 0) {
      newMasteryScore = ((totalCorrect / totalDone) * 100).round();
    }

    // Đếm số lượt làm quiz liên quan đến topic này
    final attemptsCountResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT aa.attempt_id) as quiz_count
      FROM attempt_answers aa
      JOIN questions q ON aa.question_id = q.id
      WHERE q.topic_id = ?
    ''', [topicId]);
    final quizCount = (attemptsCountResult.first['quiz_count'] as num?)?.toInt() ?? 0;

    // Cập nhật lại vào bảng topics
    final now = DateTime.now().toIso8601String();
    await db.update(
      'topics',
      {
        'mastery_score': newMasteryScore,
        'quiz_count': quizCount,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [topicId],
    );

    return newMasteryScore;
  }

  /// Tạo hàng loạt thẻ Flashcard mới từ các câu trả lời sai
  Future<int> createFlashcardsFromMistakes({
    required int subjectId,
    required List<QuestionModel> wrongQuestions,
  }) async {
    if (wrongQuestions.isEmpty) return 0;
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    int insertedCount = 0;
    await db.transaction((txn) async {
      for (final q in wrongQuestions) {
        // Kiểm tra xem thẻ câu hỏi này đã có trong flashcards chưa
        final existing = await txn.query(
          'flashcards',
          where: 'topic_id = ? AND front_text = ?',
          whereArgs: [q.topicId, q.questionText],
        );

        if (existing.isEmpty) {
          final correctText = (q.correctIndex >= 0 && q.correctIndex < q.options.length)
              ? q.options[q.correctIndex]
              : 'Đáp án đúng';

          await txn.insert('flashcards', {
            'subject_id': subjectId,
            'topic_id': q.topicId,
            'front_text': q.questionText,
            'front_code': q.codeSnippet,
            'back_text': 'Đáp án đúng: $correctText\n\nGiải thích: ${q.explanation}',
            'repetition': 0,
            'interval': 0,
            'ease_factor': 2.5,
            'next_review_at': now,
          });
          insertedCount++;
        }
      }
    });

    return insertedCount;
  }

  @override
  Future<List<Map<String, dynamic>>> getQuizAttemptsBySubject(int subjectId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'quiz_attempts',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'id DESC',
    );
  }
}
