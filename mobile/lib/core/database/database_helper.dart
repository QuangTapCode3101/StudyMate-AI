import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

  Future<void> seedDemoFlutterCourse() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM subjects'),
    );
    if ((count ?? 0) > 0) return; // Tránh nạp trùng nếu đã có dữ liệu

    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Tạo môn Lập trình Flutter
      final subjectId = await txn.insert('subjects', {
        'name': 'Lập trình Flutter',
        'programming_language': 'Dart / Flutter',
        'created_at': now,
      });

      // 2. Tạo tài liệu mẫu Slide_StateManagement.pdf
      final docId = await txn.insert('documents', {
        'subject_id': subjectId,
        'title': 'Slide_StateManagement.pdf',
        'doc_type': 'PDF',
        'total_chunks': 2,
        'created_at': now,
      });

      // 3. Tạo các trang văn bản mẫu để M3 test tính năng Trích dẫn nguồn (MDL-01)
      await txn.insert('document_chunks', {
        'document_id': docId,
        'chunk_index': 1,
        'page_label': 'Trang 12',
        'content':
            'Consumer và context.watch<T>() dùng để lắng nghe sự thay đổi của dữ liệu trong Provider và kích hoạt rebuild Widget. Ngược lại, context.read<T>() chỉ đọc dữ liệu 1 lần duy nhất mà không đăng ký lắng nghe, bắt buộc dùng bên trong các callback sự kiện như onPressed.',
      });

      // 4. Tạo 3 Chủ đề khớp 100% với Mockup (85% Xanh, 60% Vàng, 25% Đỏ)
      await txn.insert('topics', {
        'subject_id': subjectId,
        'document_id': docId,
        'name': 'ChangeNotifier',
        'keywords_json': jsonEncode(['notifyListeners()', 'extends']),
        'chunk_indices_json': jsonEncode([1]),
        'mastery_score': 85,
        'quiz_count': 2,
        'updated_at': now,
      });

      final topicProviderId = await txn.insert('topics', {
        'subject_id': subjectId,
        'document_id': docId,
        'name': 'Provider & Consumer',
        'keywords_json': jsonEncode(['context.watch()', 'context.read()']),
        'chunk_indices_json': jsonEncode([1]),
        'mastery_score': 60,
        'quiz_count': 2,
        'updated_at': now,
      });

      final topicLifecycleId = await txn.insert('topics', {
        'subject_id': subjectId,
        'document_id': docId,
        'name': 'Widget Rebuild Lifecycle',
        'keywords_json': jsonEncode(['build()', 'didChangeDependencies']),
        'chunk_indices_json': jsonEncode([1]),
        'mastery_score': 25,
        'quiz_count': 1,
        'updated_at': now,
      });

      // 5. Tạo câu hỏi Spot the Bug mẫu cho M4
      await txn.insert('questions', {
        'topic_id': topicLifecycleId,
        'question_type': 'SPOT_BUG',
        'question_text': 'Đoạn code Flutter dưới đây có lỗi tiềm ẩn ở dòng nào?',
        'code_snippet':
            '1  Widget build(BuildContext context) {\n2    return ElevatedButton(\n3      onPressed: () {\n4        context.watch<CartModel>().addItem();\n5      },\n6      child: const Text("Add to Cart"),\n7    );\n8  }',
        'options_json': jsonEncode([
          'Dòng 1: Sai kiểu trả về của hàm build',
          'Dòng 4: Không gọi context.watch bên trong callback onPressed',
          'Dòng 6: Không được dùng từ khóa const cho Text',
          'Đoạn code hoàn toàn đúng',
        ]),
        'correct_index': 1,
        'explanation':
            'Hàm onPressed là một callback sự kiện, không phải hàm build. Phải dùng context.read<CartModel>() thay vì context.watch.',
      });

      // 6. Tạo thẻ Flashcard SM-2 đến hạn ngay hôm nay cho M1 & M4
      await txn.insert('flashcards', {
        'subject_id': subjectId,
        'topic_id': topicProviderId,
        'front_text':
            'Để gọi hàm trong onPressed mà không làm rebuild Widget, ta dùng phương thức nào của Provider?',
        'front_code': 'context.____<CartModel>().clear();',
        'back_text':
            'Đáp án: read\nPhương thức context.read<T>() lấy giá trị 1 lần mà không đăng ký lắng nghe sự thay đổi, tránh lỗi runtime và tránh rebuild dư thừa.',
        'repetition': 0,
        'interval': 0,
        'ease_factor': 2.5,
        'next_review_at': now,
      });
    });
  }
}