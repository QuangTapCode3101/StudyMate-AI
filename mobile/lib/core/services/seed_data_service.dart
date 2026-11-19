import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class SeedDataService {
  static Future<void> loadDemoData(Database db) async {
    print('--- BẮT ĐẦU NẠP DỮ LIỆU TỪ JSON VÀO SQLITE ---');

    try {
      // 1. Dọn dẹp sạch sẽ dữ liệu rác cũ (Reset)
      await db.execute('DELETE FROM questions');
      await db.execute('DELETE FROM topics');
      await db.execute('DELETE FROM subjects');

      // 2. Nạp Subject và Topic mồi (BẮT BUỘC để không bị lỗi Foreign Key)
      await db.insert('subjects', {
        'id': 1,
        'name': 'Lập trình Flutter (INT1449)',
        'programming_language': 'Dart',
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('topics', {
        'id': 1, // Khớp với topicId = 1 trong file JSON
        'subject_id': 1,
        'document_id': 1, // Giả định ID tài liệu
        'name': 'Ngân hàng 300 câu hỏi trắc nghiệm',
        'keywords_json': jsonEncode(["Dart", "Flutter", "INT1449"]),
        'chunk_indices_json': jsonEncode([1]),
        'mastery_score': 0,
        'quiz_count': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. Đọc file JSON từ assets
      final String jsonString = await rootBundle.loadString('assets/seed/flutter_300_questions.json');
      final List<dynamic> questionsData = jsonDecode(jsonString);

      // 4. Batch Insert 300 câu hỏi siêu tốc
      Batch batch = db.batch();
      for (var q in questionsData) {
        batch.insert('questions', {
          'topic_id': q['topicId'] ?? 1,
          'question_type': q['questionType'] ?? 'CONCEPT',
          'question_text': q['questionText'] ?? '',
          'code_snippet': q['codeSnippet'], // Có thể null
          'options_json': jsonEncode(q['options']), // Phải encode mảng thành chuỗi để lưu SQLite
          'correct_index': q['correctIndex'] ?? 0,
          'explanation': q['explanation'] ?? 'Kiến thức chuẩn',
        });
      }

      // Execute toàn bộ 300 câu lệnh insert cùng lúc (cực kỳ tối ưu)
      await batch.commit(noResult: true);
      print('--- ĐÃ NẠP THÀNH CÔNG ${questionsData.length} CÂU HỎI VÀO SQLITE ---');
      
    } catch (e) {
      print('--- LỖI KHI NẠP DỮ LIỆU: $e ---');
    }
  }
}