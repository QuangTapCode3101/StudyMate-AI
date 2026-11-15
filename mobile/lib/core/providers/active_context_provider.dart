import 'package:flutter/foundation.dart';

class ActiveStudyContextProvider extends ChangeNotifier {
  int _currentTabIndex = 0; // 0: Trang chủ, 1: Thư viện, 2: AI Tutor, 3: Luyện tập, 4: Tiến độ
  int? _activeSubjectId;
  int? _activeTopicId;

  int get currentTabIndex => _currentTabIndex;
  int? get activeSubjectId => _activeSubjectId;
  int? get activeTopicId => _activeTopicId;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// Gọi hàm này khi bấm nút [Học với AI] từ Home (M1) hoặc Subject Detail (M2)
  void openAiTutorWithTopic({required int subjectId, required int topicId}) {
    _activeSubjectId = subjectId;
    _activeTopicId = topicId;
    _currentTabIndex = 2; // Nhảy sang Tab AI Tutor
    notifyListeners();
  }

  /// Gọi hàm này khi bấm nút [Làm Quiz] từ Home (M1) hoặc Subject Detail (M2)
  void openQuizSetupWithTopic({required int subjectId, required int topicId}) {
    _activeSubjectId = subjectId;
    _activeTopicId = topicId;
    _currentTabIndex = 3; // Nhảy sang Tab Luyện tập
    notifyListeners();
  }
}