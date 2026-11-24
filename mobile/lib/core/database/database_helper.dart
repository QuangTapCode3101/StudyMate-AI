import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Database? _database;
  int? _currentUserId;
  Future<Database>? _openingFuture;

  int? get currentUserId => _currentUserId;
  bool get isOpen => _database != null && _database!.isOpen;

  /// Thiết lập user đang đăng nhập. Nếu đổi sang user khác, đóng DB cũ trước.
  Future<void> setUserId(int userId) async {
    if (userId <= 0) {
      throw ArgumentError.value(userId, 'userId', 'userId phải lớn hơn 0');
    }

    if (_currentUserId == userId && _database != null && _database!.isOpen) {
      return;
    }

    await closeDatabase();
    _currentUserId = userId;
  }

  Future<Database> get database async {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError(
        'Chưa thiết lập userId cho DatabaseHelper. Hãy gọi setUserId(userId) trước khi truy cập database.',
      );
    }

    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }

    if (_openingFuture != null) {
      return await _openingFuture!;
    }

    final future = _initDB('studymate_user_$userId.db');
    _openingFuture = future;

    try {
      final db = await future;
      // Kiểm tra lại xem trong lúc chờ mở DB có bị đổi user/logout hay không
      if (_currentUserId != userId) {
        await db.close();
        throw StateError(
          'Phiên người dùng đã thay đổi trong lúc mở database.',
        );
      }
      _database = db;
      return db;
    } finally {
      if (identical(_openingFuture, future)) {
        _openingFuture = null;
      }
    }
  }

  /// Đóng DB an toàn khi logout hoặc đổi tài khoản.
  Future<void> closeDatabase({bool clearUserId = true}) async {
    final pendingOpen = _openingFuture;
    if (pendingOpen != null) {
      try {
        await pendingOpen;
      } catch (_) {}
    }

    final db = _database;
    _database = null;
    if (clearUserId) {
      _currentUserId = null;
    }

    if (db != null && db.isOpen) {
      await db.close();
    }
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

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

  Future<void> seedDemoFlutterCourse([Database? passedDb]) async {
    final db = passedDb ?? await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM subjects'),
    );
    if ((count ?? 0) > 0) return;

    final now = DateTime.now().toIso8601String();

    final String jsonString =
        await rootBundle.loadString('assets/seed/flutter_300_questions.json');
    final Map<String, dynamic> rootData = jsonDecode(jsonString);
    final List<dynamic> topicsData = rootData['topics'] ?? [];
    final List<dynamic> questionsData = rootData['questions'] ?? [];

    await db.transaction((txn) async {
      final subjectId = await txn.insert('subjects', {
        'name': 'Lập trình Flutter (INT1449)',
        'programming_language': 'Dart / Flutter',
        'created_at': now,
      });

      final docId = await txn.insert('documents', {
        'subject_id': subjectId,
        'title': 'Tài liệu flutter.pdf',
        'doc_type': 'PDF',
        'total_chunks': 2,
        'created_at': now,
      });

      await txn.insert('document_chunks', {
        'document_id': docId,
        'chunk_index': 1,
        'page_label': 'Trang 12',
        'content': 'Đây là tài liệu flutter mẫu... (đoạn text trích dẫn)',
      });

      for (var t in topicsData) {
        final int topicId = t['id'];
        final String topicName = t['name'] ?? 'Khối kiến thức $topicId';

        await txn.insert('topics', {
          'id': topicId,
          'subject_id': subjectId,
          'document_id': docId,
          'name': topicName,
          'keywords_json': jsonEncode([topicName, 'Dart', 'Flutter']),
          'chunk_indices_json': jsonEncode([topicId]),
          'mastery_score': 0,
          'quiz_count': 0,
          'updated_at': now,
        });
      }

      Batch batch = txn.batch();
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
    });
  }
}