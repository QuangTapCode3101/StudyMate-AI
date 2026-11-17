import 'package:flutter/foundation.dart';
import '../../../core/models/shared_models.dart';
import '../data/library_repository.dart';

/// Cách sắp xếp danh sách môn học (nút lọc cạnh ô tìm kiếm).
enum LibrarySort {
  newest('Mới thêm gần đây'),
  nameAsc('Tên A → Z'),
  progressAsc('Tiến độ thấp nhất');

  final String label;
  const LibrarySort(this.label);
}

/// Quản lý danh sách môn học, ô tìm kiếm và sắp xếp của SCR-02.
class LibraryViewModel extends ChangeNotifier {
  final LibraryRepository _repository;

  LibraryViewModel({LibraryRepository? repository})
      : _repository = repository ?? LibraryRepository();

  List<SubjectModel> _subjects = [];
  String _query = '';
  LibrarySort _sort = LibrarySort.newest;
  bool _isLoading = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  LibrarySort get sort => _sort;
  bool get hasAnySubject => _subjects.isNotEmpty;

  /// Danh sách đã lọc theo từ khóa (tên môn hoặc ngôn ngữ) và sắp xếp theo _sort.
  List<SubjectModel> get subjects {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? List<SubjectModel>.of(_subjects)
        : _subjects
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                s.programmingLanguage.toLowerCase().contains(q))
            .toList();

    switch (_sort) {
      case LibrarySort.newest:
        break; // Repository đã trả về mới nhất trước.
      case LibrarySort.nameAsc:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case LibrarySort.progressAsc:
        list.sort((a, b) => a.avgMasteryScore.compareTo(b.avgMasteryScore));
    }
    return list;
  }

  Future<void> loadSubjects({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _subjects = await _repository.getSubjectsWithStats();
      _errorMessage = null;
    } catch (e) {
      debugPrint('Lỗi đọc danh sách môn học: $e');
      _errorMessage = 'Không đọc được danh sách môn học. Hãy thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSort(LibrarySort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  Future<bool> addSubject({
    required String name,
    required String programmingLanguage,
  }) async {
    try {
      await _repository.createSubject(
        name: name,
        programmingLanguage: programmingLanguage,
      );
      await loadSubjects(showLoading: false);
      return true;
    } catch (e) {
      debugPrint('Lỗi thêm môn học: $e');
      return false;
    }
  }

  Future<bool> deleteSubject(int subjectId) async {
    try {
      await _repository.deleteSubject(subjectId);
      await loadSubjects(showLoading: false);
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa môn học: $e');
      return false;
    }
  }
}
