import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/shared_models.dart';
import '../models/dashboard_data_model.dart';

class DashboardRepository {
  Future<DashboardSummaryData> getDashboardSummary() async {
    final db = await DatabaseHelper.instance.database;
    final nowIso = DateTime.now().toIso8601String();

    //  Đếm tổng số chủ đề để kiểm tra trạng thái Empty State
    final totalTopics = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM topics'),
        ) ??
        0;

    if (totalTopics == 0) {
      return DashboardSummaryData(
        dueFlashcardsCount: 0,
        weakTopics: [],
        totalMasteredCards: 0,
        totalTopicsCount: 0,
      );
    }

    // Lấy chủ đề đang học dở gần nhất (ưu tiên chủ đề có điểm 40-79% như Provider & Consumer)
    final continueRows = await db.rawQuery('''
      SELECT t.*, s.name AS subject_name
      FROM topics t
      JOIN subjects s ON t.subject_id = s.id
      ORDER BY CASE WHEN t.mastery_score BETWEEN 40 AND 79 THEN 0 ELSE 1 END,
               t.updated_at DESC
      LIMIT 1
    ''');

    TopicModel? continueTopic;
    String? activeSubjectName;
    if (continueRows.isNotEmpty) {
      continueTopic = TopicModel.fromMap(continueRows.first);
      activeSubjectName = continueRows.first['subject_name'] as String;
    }

    // Đếm số thẻ Flashcard đến hạn ôn tập hôm nay (next_review_at <= now)
    final dueCardsCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM flashcards WHERE next_review_at <= ?',
            [nowIso],
          ),
        ) ??
        0;

    //  Lấy danh sách Chủ đề yếu (< 50%) để hiện vào mục "Chủ đề yếu cần ôn lại"
    final weakRows = await db.rawQuery('''
      SELECT t.*, s.name AS subject_name
      FROM topics t
      JOIN subjects s ON t.subject_id = s.id
      WHERE t.mastery_score < 50
      ORDER BY t.mastery_score ASC
      LIMIT 5
    ''');

    final weakTopics = weakRows
        .map(
          (row) => WeakTopicItem(
            topic: TopicModel.fromMap(row),
            subjectName: row['subject_name'] as String,
          ),
        )
        .toList();

    // Đếm tổng số thẻ Flashcard đang có
    final totalCards = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM flashcards'),
        ) ??
        0;

    return DashboardSummaryData(
      activeSubjectName: activeSubjectName,
      continueTopic: continueTopic,
      dueFlashcardsCount: dueCardsCount,
      weakTopics: weakTopics,
      totalMasteredCards: totalCards,
      totalTopicsCount: totalTopics,
    );
  }
}