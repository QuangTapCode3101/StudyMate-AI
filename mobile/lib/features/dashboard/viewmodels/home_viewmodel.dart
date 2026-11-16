import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_data_model.dart';
import '../repositories/dashboard_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();

  DashboardSummaryData? _summary;
  bool _isLoading = true;
  int _remainingQuota = 20;
  int _maxQuota = 20;
  bool _isBackendOnline = false;

  DashboardSummaryData? get summary => _summary;
  bool get isLoading => _isLoading;
  int get remainingQuota => _remainingQuota;
  int get maxQuota => _maxQuota;
  bool get isBackendOnline => _isBackendOnline;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      _summary = await _repository.getDashboardSummary();
    } catch (e) {
      debugPrint('Lỗi đọc SQLite Dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    await refreshQuotaStatus();
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