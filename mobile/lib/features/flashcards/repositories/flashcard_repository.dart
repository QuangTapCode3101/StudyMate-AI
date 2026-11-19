import '../../../core/database/database_helper.dart';
import '../models/flashcard_model.dart';
import 'flashcard_repository_interface.dart';

/// DTO chứa thông tin thống kê số thẻ của 1 môn học
class DeckStatItem {
  final int subjectId;
  final String subjectName;
  final String programmingLanguage;
  final int totalCards;
  final int dueCards;

  const DeckStatItem({
    required this.subjectId,
    required this.subjectName,
    required this.programmingLanguage,
    required this.totalCards,
    required this.dueCards,
  });
}

class FlashcardRepository implements IFlashcardRepository {
  final DatabaseHelper _dbHelper;

  FlashcardRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Lấy danh sách thống kê bộ thẻ của từng môn học (SCR-09 Sub-tab 1)
  Future<List<DeckStatItem>> getDeckStats() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final result = await db.rawQuery('''
      SELECT 
        s.id as subject_id,
        s.name as subject_name,
        s.programming_language,
        COUNT(f.id) as total_cards,
        SUM(CASE WHEN f.next_review_at <= ? THEN 1 ELSE 0 END) as due_cards
      FROM subjects s
      LEFT JOIN flashcards f ON s.id = f.subject_id
      GROUP BY s.id, s.name, s.programming_language
      ORDER BY s.id ASC
    ''', [now]);

    return result.map((row) {
      return DeckStatItem(
        subjectId: (row['subject_id'] as num).toInt(),
        subjectName: row['subject_name'] as String,
        programmingLanguage: row['programming_language'] as String,
        totalCards: (row['total_cards'] as num?)?.toInt() ?? 0,
        dueCards: (row['due_cards'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getDueFlashcards(int subjectId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.query(
      'flashcards',
      where: 'subject_id = ? AND next_review_at <= ?',
      whereArgs: [subjectId, now],
      orderBy: 'next_review_at ASC',
    );
  }

  /// Lấy danh sách thẻ đến hạn đã được parse sang FlashcardModel
  Future<List<FlashcardModel>> getDueFlashcardModels(int subjectId) async {
    final rawList = await getDueFlashcards(subjectId);
    return rawList.map((m) => FlashcardModel.fromMap(m)).toList();
  }

  @override
  Future<int> getDueCountBySubject(int subjectId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM flashcards 
      WHERE subject_id = ? AND next_review_at <= ?
    ''', [subjectId, now]);

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> updateSm2Review({
    required int cardId,
    required int repetition,
    required int interval,
    required double easeFactor,
    required String nextReviewAt,
  }) async {
    final db = await _dbHelper.database;

    await db.update(
      'flashcards',
      {
        'repetition': repetition,
        'interval': interval,
        'ease_factor': easeFactor,
        'next_review_at': nextReviewAt,
      },
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  @override
  Future<int> createFlashcardsFromFailedAnswers(
    List<Map<String, dynamic>> failedCardData,
  ) async {
    if (failedCardData.isEmpty) return 0;
    final db = await _dbHelper.database;
    int count = 0;

    await db.transaction((txn) async {
      for (final card in failedCardData) {
        await txn.insert('flashcards', card);
        count++;
      }
    });

    return count;
  }
}
