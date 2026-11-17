import 'package:flutter/foundation.dart';
import '../../../core/models/shared_models.dart';
import '../data/library_repository.dart';
import '../models/document_model.dart';

/// Dữ liệu cho SCR-03: tài liệu nguồn và cây chủ đề của một môn học.
class SubjectDetailViewModel extends ChangeNotifier {
  final int subjectId;
  final LibraryRepository _repository;

  SubjectDetailViewModel({
    required this.subjectId,
    LibraryRepository? repository,
  }) : _repository = repository ?? LibraryRepository();

  List<DocumentModel> _documents = [];
  List<TopicModel> _topics = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _expandedTopicIds = {};

  List<DocumentModel> get documents => _documents;
  List<TopicModel> get topics => _topics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isExpanded(int topicId) => _expandedTopicIds.contains(topicId);

  /// Mở/đóng 2 nút [Học với AI] / [Luyện Quiz] của một chủ đề.
  void toggleTopic(int topicId) {
    if (!_expandedTopicIds.remove(topicId)) _expandedTopicIds.add(topicId);
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getDocumentsBySubject(subjectId),
        _repository.getTopicsBySubject(subjectId),
      ]);
      _documents = results[0] as List<DocumentModel>;
      _topics = results[1] as List<TopicModel>;
      // Mặc định mở sẵn các chủ đề yếu (<50%) giống mockup để thấy ngay nút hành động.
      _expandedTopicIds
        ..clear()
        ..addAll(_topics
            .where((t) => t.masteryScore < 50 && t.id != null)
            .map((t) => t.id!));
      _errorMessage = null;
    } catch (e) {
      debugPrint('Lỗi đọc chi tiết môn học: $e');
      _errorMessage = 'Không đọc được dữ liệu môn học. Hãy thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
