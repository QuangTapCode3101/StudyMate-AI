import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/analytics_data_model.dart';

class AnalyticsRepository {
  final DatabaseHelper _dbHelper;

  AnalyticsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Truy vấn song song toàn bộ dữ liệu cho SCR-09 Sub-tab 2 (Analytics)
  Future<AnalyticsDashboardData> getAnalyticsDashboardData({int? subjectId}) async {
    final db = await _dbHelper.database;

    final results = await Future.wait([
      _fetchKpiStats(db, subjectId: subjectId),
      _fetchTopicMasteryMap(db, subjectId: subjectId),
      _fetchRecentQuizAttempts(db, subjectId: subjectId, limit: 10),
    ]);

    return AnalyticsDashboardData(
      kpi: results[0] as AnalyticsKpiModel,
      topicMasteryList: results[1] as List<TopicMasteryItem>,
      recentAttempts: results[2] as List<QuizAttemptHistoryItem>,
    );
  }

  /// 1. Gộp 4 nhóm chỉ số KPI trong 1 câu truy vấn Scalar Subquery duy nhất
  Future<AnalyticsKpiModel> _fetchKpiStats(Database db, {int? subjectId}) async {
    final nowIso = DateTime.now().toIso8601String();
    final hasFilter = subjectId != null;

    final sql = '''
      SELECT
        (SELECT COALESCE(SUM(total_questions), 0) FROM quiz_attempts ${hasFilter ? 'WHERE subject_id = ?' : ''}) AS total_questions_answered,
        (SELECT COALESCE(SUM(correct_count), 0) FROM quiz_attempts ${hasFilter ? 'WHERE subject_id = ?' : ''}) AS total_correct_answers,
        (SELECT COUNT(*) FROM topics WHERE mastery_score >= 80 ${hasFilter ? 'AND subject_id = ?' : ''}) AS strong_topics_count,
        (SELECT COUNT(*) FROM topics ${hasFilter ? 'WHERE subject_id = ?' : ''}) AS total_topics_count,
        (SELECT COUNT(*) FROM flashcards ${hasFilter ? 'WHERE subject_id = ?' : ''}) AS total_flashcards_count,
        (SELECT COUNT(*) FROM flashcards WHERE next_review_at <= ? ${hasFilter ? 'AND subject_id = ?' : ''}) AS due_flashcards_count
    ''';

    final List<Object?> args = hasFilter
        ? [subjectId, subjectId, subjectId, subjectId, subjectId, nowIso, subjectId]
        : [nowIso];

    final rows = await db.rawQuery(sql, args);
    if (rows.isEmpty) {
      return const AnalyticsKpiModel(
        totalQuestionsAnswered: 0,
        totalCorrectAnswers: 0,
        strongTopicsCount: 0,
        totalTopicsCount: 0,
        totalFlashcardsCount: 0,
        dueFlashcardsCount: 0,
      );
    }
    return AnalyticsKpiModel.fromMap(rows.first);
  }

  /// 2. Bản đồ độ thông thạo xếp từ yếu đến mạnh (mastery_score ASC)
  Future<List<TopicMasteryItem>> _fetchTopicMasteryMap(Database db, {int? subjectId}) async {
    final hasFilter = subjectId != null;

    final sql = '''
      SELECT 
        t.id AS topic_id,
        t.subject_id,
        s.name AS subject_name,
        s.programming_language,
        t.name AS topic_name,
        t.mastery_score,
        t.quiz_count
      FROM topics t
      INNER JOIN subjects s ON t.subject_id = s.id
      ${hasFilter ? 'WHERE t.subject_id = ?' : ''}
      ORDER BY t.mastery_score ASC, t.quiz_count ASC, t.id ASC
    ''';

    final rows = await db.rawQuery(sql, hasFilter ? [subjectId] : []);
    return rows.map(TopicMasteryItem.fromMap).toList();
  }

  /// 3. Lịch sử làm Quiz gần đây (Mới nhất lên đầu)
  Future<List<QuizAttemptHistoryItem>> _fetchRecentQuizAttempts(
    Database db, {
    int? subjectId,
    int limit = 10,
  }) async {
    final hasFilter = subjectId != null;

    final sql = '''
      SELECT 
        qa.id AS attempt_id,
        qa.subject_id,
        COALESCE(s.name, 'Môn học đã xóa') AS subject_name,
        qa.score,
        qa.total_questions,
        qa.correct_count,
        qa.duration_seconds,
        qa.completed_at
      FROM quiz_attempts qa
      LEFT JOIN subjects s ON qa.subject_id = s.id
      ${hasFilter ? 'WHERE qa.subject_id = ?' : ''}
      ORDER BY qa.completed_at DESC, qa.id DESC
      LIMIT ?
    ''';

    final args = hasFilter ? [subjectId, limit] : [limit];
    final rows = await db.rawQuery(sql, args);
    return rows.map(QuizAttemptHistoryItem.fromMap).toList();
  }
}