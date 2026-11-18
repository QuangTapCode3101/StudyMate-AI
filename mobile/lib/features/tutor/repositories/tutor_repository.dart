import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../models/tutor_models.dart';

/// Repository của module AI Tutor.
/// Theo phân quyền: M3 chỉ được GHI vào chat_sessions và chat_messages,
/// các bảng còn lại (subjects, topics, document_chunks...) chỉ ĐỌC.
class TutorRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  // ---------------------------------------------------------------------------
  // Đọc ngữ cảnh học (subjects, topics)
  // ---------------------------------------------------------------------------

  static const String _topicContextSelect = '''
    SELECT t.id AS topic_id, t.name AS topic_name, t.document_id,
           t.mastery_score, s.id AS subject_id, s.name AS subject_name,
           s.programming_language
    FROM topics t
    JOIN subjects s ON t.subject_id = s.id
  ''';

  Future<List<TutorContext>> getAllTopicContexts() async {
    final db = await _db;
    final rows = await db.rawQuery(
      '$_topicContextSelect ORDER BY s.name ASC, t.id ASC',
    );
    return rows.map(TutorContext.fromMap).toList();
  }

  Future<TutorContext?> getTopicContext(int topicId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '$_topicContextSelect WHERE t.id = ?',
      [topicId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return TutorContext.fromMap(rows.first);
  }

  /// Chủ đề của phiên chat gần nhất, dùng để mở lại đúng chỗ đang học dở.
  Future<int?> getLastUsedTopicId() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT topic_id FROM chat_sessions ORDER BY id DESC LIMIT 1',
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['topic_id'] as int?;
  }

  // ---------------------------------------------------------------------------
  // Đọc nội dung gốc (document_chunks)
  // ---------------------------------------------------------------------------

  /// Các đoạn nguồn thuộc chủ đề (theo chunk_indices_json) để gửi cho AI.
  /// Nếu chủ đề không khai báo chunk nào khớp thì dùng toàn bộ tài liệu gốc.
  Future<List<SourceChunkModel>> getSourceChunksForTopic(int topicId) async {
    final db = await _db;
    final topicRows = await db.query(
      'topics',
      columns: ['document_id', 'chunk_indices_json'],
      where: 'id = ?',
      whereArgs: [topicId],
      limit: 1,
    );
    if (topicRows.isEmpty) {
      return const [];
    }

    final documentId = topicRows.first['document_id'] as int;
    List<int> indices;
    try {
      indices = List<int>.from(
        jsonDecode(topicRows.first['chunk_indices_json'] as String) as List,
      );
    } catch (_) {
      indices = <int>[];
    }

    if (indices.isNotEmpty) {
      final placeholders = List.filled(indices.length, '?').join(',');
      final rows = await db.rawQuery(
        '''
        SELECT c.*, d.title AS document_title
        FROM document_chunks c
        JOIN documents d ON c.document_id = d.id
        WHERE c.document_id = ? AND c.chunk_index IN ($placeholders)
        ORDER BY c.chunk_index ASC
        ''',
        [documentId, ...indices],
      );
      if (rows.isNotEmpty) {
        return rows.map(SourceChunkModel.fromMap).toList();
      }
    }

    return getChunksOfDocument(documentId);
  }

  /// Toàn bộ đoạn của 1 tài liệu theo thứ tự, dùng cho nút Trang trước / Trang sau (MDL-01).
  Future<List<SourceChunkModel>> getChunksOfDocument(int documentId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT c.*, d.title AS document_title
      FROM document_chunks c
      JOIN documents d ON c.document_id = d.id
      WHERE c.document_id = ?
      ORDER BY c.chunk_index ASC
      ''',
      [documentId],
    );
    return rows.map(SourceChunkModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Phiên chat & tin nhắn (bảng M3 được quyền ghi)
  // ---------------------------------------------------------------------------

  Future<List<ChatSessionModel>> getSessionsByTopic(int topicId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT s.*,
             (SELECT COUNT(*) FROM chat_messages m WHERE m.session_id = s.id)
               AS message_count
      FROM chat_sessions s
      WHERE s.topic_id = ?
      ORDER BY s.id DESC
      ''',
      [topicId],
    );
    return rows.map(ChatSessionModel.fromMap).toList();
  }

  Future<ChatSessionModel> createSession({
    required int subjectId,
    required int topicId,
    required String title,
  }) async {
    final db = await _db;
    final session = ChatSessionModel(
      subjectId: subjectId,
      topicId: topicId,
      title: title,
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await db.insert('chat_sessions', session.toMap());
    return ChatSessionModel(
      id: id,
      subjectId: session.subjectId,
      topicId: session.topicId,
      title: session.title,
      createdAt: session.createdAt,
    );
  }

  Future<void> deleteSession(int sessionId) async {
    final db = await _db;
    // chat_messages bị xóa theo nhờ ON DELETE CASCADE (PRAGMA foreign_keys = ON).
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<void> deleteAllSessionsOfTopic(int topicId) async {
    final db = await _db;
    await db.delete('chat_sessions', where: 'topic_id = ?', whereArgs: [topicId]);
  }

  Future<List<ChatMessageModel>> getMessages(int sessionId) async {
    final db = await _db;
    final rows = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
    return rows.map(ChatMessageModel.fromMap).toList();
  }

  /// Xóa tin nhắn [messageId] và mọi tin nhắn đứng sau nó trong cùng phiên
  /// (dùng khi người dùng sửa lại câu hỏi mới nhất rồi hỏi lại AI).
  Future<void> deleteMessagesFrom({
    required int sessionId,
    required int messageId,
  }) async {
    final db = await _db;
    await db.delete(
      'chat_messages',
      where: 'session_id = ? AND id >= ?',
      whereArgs: [sessionId, messageId],
    );
  }

  Future<void> updateSessionTitle(int sessionId, String title) async {
    final db = await _db;
    await db.update(
      'chat_sessions',
      {'title': title},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Lưu tin nhắn và trả về bản có `id` thật.
  Future<ChatMessageModel> insertMessage(ChatMessageModel message) async {
    final db = await _db;
    final id = await db.insert('chat_messages', message.toMap());
    return message.copyWith(id: id);
  }
}
