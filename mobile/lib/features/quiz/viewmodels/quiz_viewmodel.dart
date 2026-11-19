import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/shared_models.dart';
import '../models/quiz_dto.dart';
import '../repositories/quiz_repository.dart';

class QuizViewModel extends ChangeNotifier {
  final QuizRepository _repository;

  QuizViewModel({QuizRepository? repository})
      : _repository = repository ?? QuizRepository();

  // =================== 1. SETUP STATE (SCR-06) ===================
  List<SubjectModel> _subjects = [];
  List<TopicModel> _topics = [];
  SubjectModel? _selectedSubject;
  TopicModel? _selectedTopic;

  int _questionCount = 5;
  final Set<String> _selectedQuestionTypes = {'CONCEPT', 'PREDICT_OUTPUT', 'SPOT_BUG'};
  String _difficulty = 'MEDIUM'; // 'EASY', 'MEDIUM', 'HARD'

  bool _isLoading = false;
  String? _errorMessage;

  List<SubjectModel> get subjects => _subjects;
  List<TopicModel> get topics => _topics;
  SubjectModel? get selectedSubject => _selectedSubject;
  TopicModel? get selectedTopic => _selectedTopic;
  int get questionCount => _questionCount;
  Set<String> get selectedQuestionTypes => _selectedQuestionTypes;
  String get difficulty => _difficulty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initSetup({int? preferredSubjectId, int? preferredTopicId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subjects = await _repository.getSubjects();

      if (_subjects.isNotEmpty) {
        if (preferredSubjectId != null) {
          _selectedSubject = _subjects.firstWhere(
            (s) => s.id == preferredSubjectId,
            orElse: () => _subjects.first,
          );
        } else {
          _selectedSubject = _subjects.first;
        }

        if (_selectedSubject != null && _selectedSubject!.id != null) {
          _topics = await _repository.getTopicsBySubject(_selectedSubject!.id!);
          if (_topics.isNotEmpty) {
            if (preferredTopicId != null) {
              _selectedTopic = _topics.firstWhere(
                (t) => t.id == preferredTopicId,
                orElse: () => _topics.first,
              );
            } else {
              _selectedTopic = _topics.first;
            }
          } else {
            _selectedTopic = null;
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu môn học: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectSubject(SubjectModel subject) async {
    _selectedSubject = subject;
    _selectedTopic = null;
    notifyListeners();

    if (subject.id != null) {
      _topics = await _repository.getTopicsBySubject(subject.id!);
      if (_topics.isNotEmpty) {
        _selectedTopic = _topics.first;
      }
      notifyListeners();
    }
  }

  void selectTopic(TopicModel topic) {
    _selectedTopic = topic;
    notifyListeners();
  }

  void setQuestionCount(int count) {
    _questionCount = count;
    notifyListeners();
  }

  void toggleQuestionType(String type) {
    if (_selectedQuestionTypes.contains(type)) {
      if (_selectedQuestionTypes.length > 1) {
        _selectedQuestionTypes.remove(type);
      }
    } else {
      _selectedQuestionTypes.add(type);
    }
    notifyListeners();
  }

  void setDifficulty(String diff) {
    _difficulty = diff;
    notifyListeners();
  }

  // =================== 2. ACTIVE QUIZ STATE (SCR-07) ===================
  List<QuestionModel> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {}; // questionIndex -> selectedOptionIndex
  int _remainingSeconds = 600; // 10 phút mặc định
  Timer? _timer;
  int _elapsedSeconds = 0;

  List<QuestionModel> get currentQuestions => _currentQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, int> get userAnswers => _userAnswers;
  int get remainingSeconds => _remainingSeconds;

  QuestionModel? get currentQuestion =>
      (_currentQuestions.isNotEmpty && _currentQuestionIndex < _currentQuestions.length)
          ? _currentQuestions[_currentQuestionIndex]
          : null;

  String get formattedTimer {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Khởi tạo bài thi: gọi API tạo đề hoặc đọc SQLite
  Future<bool> startQuiz() async {
    if (_selectedSubject == null || _selectedTopic == null) {
      _errorMessage = 'Vui lòng chọn môn học và chủ đề để bắt đầu thi.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.generateQuiz(
        programmingLanguage: _selectedSubject!.programmingLanguage,
        difficulty: _difficulty,
        questionCount: _questionCount,
        questionTypes: _selectedQuestionTypes.toList(),
        topics: [
          QuizTopicRef(
            topicId: _selectedTopic!.id!,
            topicName: _selectedTopic!.name,
          ),
        ],
      );

      _currentQuestions = response.questions;
      if (_currentQuestions.isEmpty) {
        _errorMessage = 'Chưa có câu hỏi nào cho chủ đề này.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Khởi tạo phòng thi
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _remainingSeconds = _questionCount * 120; // 2 phút mỗi câu
      _elapsedSeconds = 0;

      _startCountdownTimer();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể tạo đề thi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _elapsedSeconds++;
        notifyListeners();
      } else {
        _timer?.cancel();
        // Hết giờ tự động nộp bài
        submitQuiz();
      }
    });
  }

  void selectAnswer(int optionIndex) {
    _userAnswers[_currentQuestionIndex] = optionIndex;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < _currentQuestions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  // =================== 3. RESULT STATE (SCR-08) ===================
  int _score = 0;
  int _correctCount = 0;
  int _topicMasteryBefore = 0;
  int _topicMasteryAfter = 0;
  List<QuestionModel> _wrongQuestions = [];
  bool _isFlashcardCreated = false;
  int _flashcardsAddedCount = 0;

  int get score => _score;
  int get correctCount => _correctCount;
  int get totalQuestions => _currentQuestions.length;
  int get elapsedSeconds => _elapsedSeconds;
  int get topicMasteryBefore => _topicMasteryBefore;
  int get topicMasteryAfter => _topicMasteryAfter;
  List<QuestionModel> get wrongQuestions => _wrongQuestions;
  bool get isFlashcardCreated => _isFlashcardCreated;
  int get flashcardsAddedCount => _flashcardsAddedCount;

  /// Chấm điểm bài thi và lưu vào SQLite Transaction
  Future<void> submitQuiz() async {
    _timer?.cancel();
    _isLoading = true;
    notifyListeners();

    _correctCount = 0;
    _wrongQuestions = [];
    final answersPayload = <Map<String, dynamic>>[];

    for (int i = 0; i < _currentQuestions.length; i++) {
      final q = _currentQuestions[i];
      final userChoice = _userAnswers[i] ?? -1;
      final isCorrect = (userChoice == q.correctIndex);

      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongQuestions.add(q);
      }

      answersPayload.add({
        'question_id': q.id ?? 0,
        'selected_index': userChoice,
        'is_correct': isCorrect ? 1 : 0,
      });
    }

    // Điểm số theo thang 100
    _score = _currentQuestions.isNotEmpty
        ? ((_correctCount / _currentQuestions.length) * 100).round()
        : 0;

    _topicMasteryBefore = _selectedTopic?.masteryScore ?? 0;

    try {
      if (_selectedSubject?.id != null) {
        // Lưu lượt làm bài vào SQLite
        await _repository.saveQuizAttempt(
          subjectId: _selectedSubject!.id!,
          score: _score,
          totalQuestions: _currentQuestions.length,
          correctCount: _correctCount,
          durationSeconds: _elapsedSeconds,
          answers: answersPayload,
        );

        // Tính toán lại Mastery Score của topic
        if (_selectedTopic?.id != null) {
          _topicMasteryAfter = await _repository
              .calculateAndUpdateTopicMastery(_selectedTopic!.id!);

          // Cập nhật lại trong danh sách local
          final updatedTopic = await _repository.getTopicById(_selectedTopic!.id!);
          if (updatedTopic != null) {
            _selectedTopic = updatedTopic;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[QuizViewModel Error]: $e');
      }
    } finally {
      _isFlashcardCreated = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nút bấm [+ Tạo Flashcard từ X câu làm sai] trên SCR-08
  Future<int> createFlashcardsFromMistakes() async {
    if (_isFlashcardCreated || _wrongQuestions.isEmpty || _selectedSubject?.id == null) {
      return 0;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final count = await _repository.createFlashcardsFromMistakes(
        subjectId: _selectedSubject!.id!,
        wrongQuestions: _wrongQuestions,
      );

      _isFlashcardCreated = true;
      _flashcardsAddedCount = count;
      return count;
    } catch (e) {
      if (kDebugMode) {
        print('[Create Flashcards Error]: $e');
      }
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
