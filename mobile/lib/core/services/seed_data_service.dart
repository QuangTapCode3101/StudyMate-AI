import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class SeedDataService {
  static Future<void> loadDemoData(Database db) async {

    try {
      // 1. Dọn dẹp sạch sẽ dữ liệu rác cũ (Reset)
      await db.execute('DELETE FROM questions');
      await db.execute('DELETE FROM topics');
      await db.execute('DELETE FROM subjects');

      final now = DateTime.now().toIso8601String();

      // 2. Nạp Subject và Topic.
      await db.insert('subjects', {
        'id': 1,
        'name': 'Lập trình Flutter (INT1449)',
        'programming_language': 'Dart',
        'created_at': now,
      });

      // 3. Đọc và giải mã file JSON
      final String jsonString = await rootBundle.loadString(
        'assets/seed/flutter_300_questions_2.json',
      );
      final Map<String, dynamic> rootData = jsonDecode(jsonString);

      final List<dynamic> topicsData = rootData['topics'] ?? [];
      final List<dynamic> questionsData = rootData['questions'] ?? [];
      
      // 4. Batch Insert toàn bộ 20 Topics từ JSON
      Batch batch = db.batch();

      for (var t in topicsData) {
        final String topicName = t['name'] ?? 'Chủ đề';
        batch.insert('topics', {
          'id': t['id'],
          'subject_id': 1,
          'document_id': 1,
          'name': topicName,
          'keywords_json': jsonEncode([topicName, "Dart", "Flutter"]),
          'chunk_indices_json': jsonEncode([t['id'] ?? 1]),
          'mastery_score': 0,
          'quiz_count': 0,
          'updated_at': now,
        });
      }

      // 5. Batch Insert 300 câu hỏi từ mảng "questions"
      for (var q in questionsData) {
        batch.insert('questions', {
          'topic_id': q['topicId'] ?? 1,
          'question_type': q['questionType'] ?? 'CONCEPT',
          'question_text': q['questionText'] ?? '',
          'code_snippet': q['codeSnippet'],
          'options_json': jsonEncode(q['options'] ?? []),
          'correct_index': q['correctIndex'] ?? 0,
          'explanation': q['explanation'] ?? 'Kiến thức chuẩn',
        });
      }

      await batch.commit(noResult: true);
      
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}