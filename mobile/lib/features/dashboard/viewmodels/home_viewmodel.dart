import 'package:flutter/foundation.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/user_prefs_service.dart';
import '../models/dashboard_data_model.dart';
import '../repositories/dashboard_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();

  DashboardSummaryData? _summary;
  bool _isLoading = true;
  int _remainingQuota = 20;
  int _maxQuota = 20;
  bool _isBackendOnline = false;
  String _displayName = '';

  DashboardSummaryData? get summary => _summary;
  bool get isLoading => _isLoading;
  int get remainingQuota => _remainingQuota;
  int get maxQuota => _maxQuota;
  bool get isBackendOnline => _isBackendOnline;
  String get displayName => _displayName;
  String get timeGreeting => UserPrefsService.getTimeGreeting();
  
  Future<void> loadDashboard({
    bool showLoading = true,
    bool checkQuota = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Đọc đồng thời SQLite và SharedPreferences để tránh rebuild 2 lần
      final results = await Future.wait([
        _repository.getDashboardSummary(),
        UserPrefsService.getDisplayName(),
      ]);
      _summary = results[0] as DashboardSummaryData?;
      _displayName = results[1] as String;
    } catch (e) {
      debugPrint('Lỗi đọc dữ liệu Dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (checkQuota) {
      await refreshQuotaStatus();
    }
  }

  Future<void> updateDisplayName(String newName) async {
    await UserPrefsService.saveDisplayName(newName);
    _displayName = newName.trim();
    notifyListeners();
  }

  Future<void> refreshQuotaStatus() async {
    try {
      final res = await ApiClient.instance.get('/api/v1/quota/status');
      final quota = res['quota'] as Map<String, dynamic>?;
      if (quota != null) {
        _remainingQuota = (quota['remainingDaily'] as num?)?.toInt() ?? 20;
        _maxQuota = (quota['maxDaily'] as num?)?.toInt() ?? 20;
        _isBackendOnline = true;
        notifyListeners();
      }
    } catch (_) {
      _isBackendOnline = false;
      notifyListeners();
    }
  }

  Future<void> reloadDemoData() async {
    await DatabaseHelper.instance.seedDemoFlutterCourse();
    await loadDashboard();
  }

  Future<void> resetBackendQuota() async {
    try {
      await ApiClient.instance.post('/api/v1/quota/reset');
      await refreshQuotaStatus();
    } catch (_) {}
  }
}
