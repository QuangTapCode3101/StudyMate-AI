import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_client.dart';
import '../models/analytics_data_model.dart';
import '../repositories/analytics_repository.dart';

class AnalyticsViewModel extends ChangeNotifier {
  final AnalyticsRepository _repository;

  AnalyticsViewModel({AnalyticsRepository? repository})
      : _repository = repository ?? AnalyticsRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AnalyticsDashboardData? _data;
  AnalyticsDashboardData? get data => _data;

  int? _selectedSubjectId;
  int? get selectedSubjectId => _selectedSubjectId;

  Future<void> loadAnalytics({int? subjectId, bool showLoading = true}) async {
    _selectedSubjectId = subjectId;
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _data = await _repository.getAnalyticsDashboardData(subjectId: _selectedSubjectId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu thống kê: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// SUB-602.3: Reset và nạp lại dữ liệu mẫu môn Lập trình Flutter
  Future<void> resetAndSeedDemoData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await DatabaseHelper.instance.seedDemoFlutterCourse();
      await loadAnalytics(subjectId: _selectedSubjectId, showLoading: false);
    } catch (e) {
      _errorMessage = 'Lỗi khi nạp lại dữ liệu mẫu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// SUB-602.3: Cập nhật địa chỉ IP máy chủ Node.js
  Future<void> updateBackendUrl(String url) async {
    await ApiClient.instance.setBaseUrl(url.trim());
  }
}