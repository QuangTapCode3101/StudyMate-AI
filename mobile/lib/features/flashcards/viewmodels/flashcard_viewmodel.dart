import 'package:flutter/foundation.dart';
import '../algorithms/sm2_calculator.dart';
import '../models/flashcard_model.dart';
import '../repositories/flashcard_repository.dart';

class FlashcardViewModel extends ChangeNotifier {
  final FlashcardRepository _repository;

  FlashcardViewModel({FlashcardRepository? repository})
      : _repository = repository ?? FlashcardRepository();

  // =================== 1. DECK LIST STATE (SCR-09) ===================
  List<DeckStatItem> _deckStats = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DeckStatItem> get deckStats => _deckStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalDueToday =>
      _deckStats.fold(0, (sum, deck) => sum + deck.dueCards);

  Future<void> loadDecks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _deckStats = await _repository.getDeckStats();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách bộ thẻ: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =================== 2. REVIEW SESSION STATE (SCR-10) ===================
  List<FlashcardModel> _currentDeckCards = [];
  int _currentIndex = 0;
  bool _isBackRevealed = false;
  int _reviewedCount = 0;
  bool _isSessionCompleted = false;
  String _currentSubjectName = '';

  List<FlashcardModel> get currentDeckCards => _currentDeckCards;
  int get currentIndex => _currentIndex;
  bool get isBackRevealed => _isBackRevealed;
  int get reviewedCount => _reviewedCount;
  bool get isSessionCompleted => _isSessionCompleted;
  String get currentSubjectName => _currentSubjectName;

  FlashcardModel? get currentCard =>
      (_currentDeckCards.isNotEmpty && _currentIndex < _currentDeckCards.length)
          ? _currentDeckCards[_currentIndex]
          : null;

  int get totalSessionCards => _currentDeckCards.length;

  /// Bắt đầu phiên ôn tập cho một môn học cụ thể
  Future<bool> startReviewSession({
    required int subjectId,
    required String subjectName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSubjectName = subjectName;
      _currentDeckCards = await _repository.getDueFlashcardModels(subjectId);

      if (_currentDeckCards.isEmpty) {
        _errorMessage = 'Môn học này hiện không có thẻ nào đến hạn ôn tập hôm nay.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentIndex = 0;
      _isBackRevealed = false;
      _reviewedCount = 0;
      _isSessionCompleted = false;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể bắt đầu phiên ôn tập: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Chạm vào thẻ để lật mở mặt sau
  void revealBack() {
    if (!_isBackRevealed) {
      _isBackRevealed = true;
      notifyListeners();
    }
  }

  /// Bấm 1 trong 4 nút đánh giá SM-2 (Again: 1, Hard: 3, Good: 4, Easy: 5)
  Future<void> submitRating(int quality) async {
    final card = currentCard;
    if (card == null || card.id == null) return;

    // 1. Tính toán chu kỳ mới bằng thuật toán SM-2 thuần túy
    final sm2Result = Sm2Calculator.calculate(
      quality: quality,
      repetition: card.repetition,
      interval: card.interval,
      easeFactor: card.easeFactor,
    );

    // 2. Cập nhật SQLite
    await _repository.updateSm2Review(
      cardId: card.id!,
      repetition: sm2Result.repetition,
      interval: sm2Result.interval,
      easeFactor: sm2Result.easeFactor,
      nextReviewAt: sm2Result.nextReviewAt,
    );

    _reviewedCount++;

    // 3. Chuyển sang thẻ tiếp theo hoặc hoàn thành
    if (_currentIndex < _currentDeckCards.length - 1) {
      _currentIndex++;
      _isBackRevealed = false;
    } else {
      _isSessionCompleted = true;
    }

    notifyListeners();

    // Tự động làm mới danh sách bộ thẻ để số thẻ đến hạn giảm về 0
    if (_isSessionCompleted) {
      await loadDecks();
    }
  }

  void resetSession() {
    _currentDeckCards = [];
    _currentIndex = 0;
    _isBackRevealed = false;
    _reviewedCount = 0;
    _isSessionCompleted = false;
    notifyListeners();
  }
}
