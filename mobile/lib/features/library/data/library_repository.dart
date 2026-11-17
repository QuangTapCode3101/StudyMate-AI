import '../../../core/database/database_helper.dart';
import '../../../core/models/shared_models.dart';
import '../models/document_model.dart';
import '../services/pdf_text_extractor_service.dart';
import 'document_api_service.dart';

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

  /// Lưu tài liệu, các chunk và chủ đề trong MỘT transaction: lỗi ở bước nào
  /// thì cả ba bảng (documents, document_chunks, topics) đều được hoàn tác.
  /// Trả về id của tài liệu vừa tạo.
  Future<int> saveDocumentAndTopicsTransaction({
    required int subjectId,
    required String title,
    required String docType, // 'PDF' | 'MARKDOWN' | 'CODE'
    required List<DocumentChunk> chunks,
    required List<ExtractedTopic> topics,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      final documentId = await txn.insert(
        'documents',
        DocumentModel(
          subjectId: subjectId,
          title: title.trim(),
          docType: docType,
          totalChunks: chunks.length,
          createdAt: now,
        ).toMap(),
      );

      for (final chunk in chunks) {
        await txn.insert('document_chunks', {
          'document_id': documentId,
          ...chunk.toMap(),
        });
      }

      // chunk_indices_json của chủ đề phải trùng chunk_index đã lưu ở trên.
      final savedIndices = <int>{for (final c in chunks) c.chunkIndex};
      for (final topic in topics) {
        final name = topic.name.trim();
        if (name.isEmpty) continue;
        var indices = topic.chunkIndices.where(savedIndices.contains).toList();
        if (indices.isEmpty) indices = savedIndices.toList()..sort();
        await txn.insert(
          'topics',
          TopicModel(
            subjectId: subjectId,
            documentId: documentId,
            name: name,
            keywords: topic.keywords,
            chunkIndices: indices,
            updatedAt: now,
          ).toMap(),
        );
      }
      return documentId;
    });
  }
}
