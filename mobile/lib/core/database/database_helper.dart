import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('studymate_ai.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        programming_language TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        doc_type TEXT NOT NULL,
        total_chunks INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE document_chunks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        chunk_index INTEGER NOT NULL,
        page_label TEXT NOT NULL,
        content TEXT NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        document_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        keywords_json TEXT NOT NULL,
        chunk_indices_json TEXT NOT NULL,
        mastery_score INTEGER DEFAULT 0,
        quiz_count INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        topic_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        citations_json TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        question_type TEXT NOT NULL,
        question_text TEXT NOT NULL,
        code_snippet TEXT,
        options_json TEXT NOT NULL,
        correct_index INTEGER NOT NULL,
        explanation TEXT NOT NULL,
        FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        correct_count INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE attempt_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        selected_index INTEGER NOT NULL,
        is_correct INTEGER NOT NULL,
        FOREIGN KEY (attempt_id) REFERENCES quiz_attempts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        topic_id INTEGER NOT NULL,
        front_text TEXT NOT NULL,
        front_code TEXT,
        back_text TEXT NOT NULL,
        repetition INTEGER DEFAULT 0,
        interval INTEGER DEFAULT 0,
        ease_factor REAL DEFAULT 2.5,
        next_review_at TEXT NOT NULL,
        FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> seedDemoFlutterCourse([Database? db]) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM subjects'),
    );
    if ((count ?? 0) > 0) return;

    final now = DateTime.now().toIso8601String();

    // 1. Đọc file 300 câu hỏi JSON từ thư mục assets/seed/
    final String jsonString = await rootBundle.loadString('assets/seed/flutter_300_questions.json');
    final List<dynamic> questionsData = jsonDecode(jsonString);

    await db.transaction((txn) async {
      // 2. Tạo môn Lập trình Flutter
      final subjectId = await txn.insert('subjects', {
        'name': 'Lập trình Flutter',
        'programming_language': 'Dart / Flutter',
        'created_at': now,
      });

      // 3. Tạo tài liệu mẫu
      final docId = await txn.insert('documents', {
        'subject_id': subjectId,
        'title': 'Slide_StateManagement.pdf',
        'doc_type': 'PDF',
        'total_chunks': 2,
        'created_at': now,
      });

      await txn.insert('document_chunks', {
        'document_id': docId,
        'chunk_index': 1,
        'page_label': 'Trang 12',
        'content': 'Consumer và context.watch<T>()... (đoạn text trích dẫn)',
      });

      // 4. Khởi tạo 20 Chủ đề (Topic) để hứng 300 câu hỏi
      for (int i = 1; i <= 20; i++) {
        String topicName = 'Khối kiến thức $i';
        int score = 0;
        
        // Giữ lại 3 chủ đề gốc để test UI
        if (i == 1) { topicName = 'Ngôn ngữ Dart'; score = 85; }
        if (i == 2) { topicName = 'Môi trường & Công cụ'; score = 60; }
        if (i == 3) { topicName = 'Cách Flutter hoạt động'; score = 25; }

        await txn.insert('topics', {
          'id': i, // Ép ID tĩnh từ 1 đến 20
          'subject_id': subjectId,
          'document_id': docId,
          'name': topicName,
          'keywords_json': jsonEncode(['Khối $i']),
          'chunk_indices_json': jsonEncode([1]),
          'mastery_score': score,
          'quiz_count': i <= 3 ? 2 : 0,
          'updated_at': now,
        });
      }

      // 5. Sử dụng Batch để Insert 300 câu hỏi cực nhanh
      Batch batch = txn.batch();
      for (var q in questionsData) {
        batch.insert('questions', {
          'topic_id': q['topicId'] ?? 1,
          'question_type': q['questionType'] ?? 'CONCEPT',
          'question_text': q['questionText'] ?? '',
          'code_snippet': q['codeSnippet'],
          'options_json': jsonEncode(q['options']),
          'correct_index': q['correctIndex'] ?? 0,
          'explanation': q['explanation'] ?? '',
        });
      }
      await batch.commit(noResult: true);

      // 6. Tạo thẻ Flashcard SM-2 mồi
      await txn.insert('flashcards', {
        'subject_id': subjectId,
        'topic_id': 2, // Map vào Topic "Môi trường & Công cụ"
        'front_text': 'Để gọi hàm trong onPressed mà không làm rebuild Widget, ta dùng phương thức nào của Provider?',
        'front_code': 'context.____<CartModel>().clear();',
        'back_text': 'Đáp án: read\nPhương thức context.read<T>()...',
        'repetition': 0,
        'interval': 0,
        'ease_factor': 2.5,
        'next_review_at': now,
      });
    });
    
    print('--- ĐÃ NẠP 300 CÂU HỎI VÀ DATA MẪU THÀNH CÔNG ---');
  }
}