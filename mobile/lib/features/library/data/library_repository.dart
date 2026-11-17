import '../../../core/database/database_helper.dart';
import '../../../core/models/shared_models.dart';
import '../models/document_model.dart';

/// Các hàm đọc/ghi SQLite cho module Thư viện (M2).
/// Luôn lấy DB qua DatabaseHelper.instance, không tự openDatabase.
class LibraryRepository {
  /// Danh sách môn kèm thống kê. Tên cột doc_count / topic_count / avg_score
  /// phải khớp với SubjectModel.fromMap trong shared_models.dart.
  Future<List<SubjectModel>> getSubjectsWithStats() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT s.*,
        (SELECT COUNT(*) FROM documents d WHERE d.subject_id = s.id) AS doc_count,
        (SELECT COUNT(*) FROM topics t WHERE t.subject_id = s.id) AS topic_count,
        (SELECT COALESCE(AVG(t.mastery_score), 0) FROM topics t WHERE t.subject_id = s.id) AS avg_score
      FROM subjects s
      ORDER BY s.created_at DESC, s.id DESC
    ''');
    return rows.map(SubjectModel.fromMap).toList();
  }

  /// Trả về id của môn vừa tạo.
  Future<int> createSubject({
    required String name,
    required String programmingLanguage,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final subject = SubjectModel(
      name: name.trim(),
      programmingLanguage: programmingLanguage.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    return db.insert('subjects', subject.toMap());
  }

  /// Xóa môn học. Nhờ PRAGMA foreign_keys = ON và ON DELETE CASCADE, các bảng
  /// documents, document_chunks, topics, chat_*, questions, flashcards,
  /// quiz_attempts, attempt_answers liên quan đều bị xóa theo.
  Future<void> deleteSubject(int subjectId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [subjectId]);
  }

  Future<List<DocumentModel>> getDocumentsBySubject(int subjectId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'documents',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(DocumentModel.fromMap).toList();
  }

  Future<List<TopicModel>> getTopicsBySubject(int subjectId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'topics',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'id ASC',
    );
    return rows.map(TopicModel.fromMap).toList();
  }
}
