import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studymate_ai/core/providers/active_context_provider.dart';
import 'package:studymate_ai/features/dashboard/models/dashboard_data_model.dart';
import 'package:studymate_ai/features/dashboard/views/home_screen.dart';
import 'package:studymate_ai/features/dashboard/viewmodels/home_viewmodel.dart';

class FakeHomeViewModel extends ChangeNotifier implements HomeViewModel {
  FakeHomeViewModel({
    this.fakeSummary,
    this.fakeIsLoading = false,
    this.fakeDisplayName = '',
    this.fakeRemainingQuota = 18,
    this.fakeMaxQuota = 20,
    this.fakeIsBackendOnline = true,
  });

  DashboardSummaryData? fakeSummary;
  bool fakeIsLoading;
  String fakeDisplayName;
  int fakeRemainingQuota;
  int fakeMaxQuota;
  bool fakeIsBackendOnline;

  int loadDashboardCallCount = 0;
  int reloadDemoDataCallCount = 0;

  @override
  DashboardSummaryData? get summary => fakeSummary;

  @override
  bool get isLoading => fakeIsLoading;

  @override
  int get remainingQuota => fakeRemainingQuota;

  @override
  int get maxQuota => fakeMaxQuota;

  @override
  bool get isBackendOnline => fakeIsBackendOnline;

  @override
  String get displayName => fakeDisplayName;

  @override
  String get timeGreeting => 'Chào buổi chiều';

  @override
  Future<void> loadDashboard({
    bool showLoading = true,
    bool checkQuota = true,
  }) async {
    loadDashboardCallCount++;
  }

  @override
  Future<void> updateDisplayName(String newName) async {
    fakeDisplayName = newName.trim();
    notifyListeners();
  }

  @override
  Future<void> reloadDemoData() async {
    reloadDemoDataCallCount++;
    notifyListeners();
  }

  @override
  Future<void> refreshQuotaStatus() async {}

  @override
  Future<void> resetBackendQuota() async {}
}

Widget _buildTestApp(
  FakeHomeViewModel vm,
  ActiveStudyContextProvider navProvider,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<HomeViewModel>.value(value: vm),
      ChangeNotifierProvider<ActiveStudyContextProvider>.value(
        value: navProvider,
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  group('SCR-01 HomeScreen Widget Tests', () {
    testWidgets('WT-01: Hiển thị vòng xoay loading khi đang tải dữ liệu', (
      tester,
    ) async {
      final vm = FakeHomeViewModel(fakeIsLoading: true);
      final nav = ActiveStudyContextProvider();

      await tester.pumpWidget(_buildTestApp(vm, nav));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chào buổi chiều'), findsOneWidget);
      expect(vm.loadDashboardCallCount, 1);
    });

    testWidgets(
      'WT-02: Hiển thị Empty State và gọi reloadDemoData khi bấm nạp dữ liệu mẫu',
      (tester) async {
        final vm = FakeHomeViewModel(fakeIsLoading: false, fakeSummary: null);
        final nav = ActiveStudyContextProvider();

        await tester.pumpWidget(_buildTestApp(vm, nav));
        await tester.pumpAndSettle();

        expect(find.text('Chưa có học liệu nào'), findsOneWidget);
        final seedBtn = find.text('Nạp dữ liệu mẫu Lập trình Flutter');
        expect(seedBtn, findsOneWidget);

        await tester.tap(seedBtn);
        await tester.pump();

        expect(vm.reloadDemoDataCallCount, 1);
      },
    );

    testWidgets(
      'WT-03: Mở hộp thoại đổi tên hiển thị và cập nhật UI sau khi bấm Lưu',
      (tester) async {
        final vm = FakeHomeViewModel(
          fakeIsLoading: false,
          fakeSummary: null,
          fakeDisplayName: '',
        );
        final nav = ActiveStudyContextProvider();

        await tester.pumpWidget(_buildTestApp(vm, nav));
        await tester.pumpAndSettle();

        expect(find.text('Hôm nay ôn tập gì nào? 👋'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Tên hiển thị'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Quảng');
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();

        expect(find.text('Quảng 👋'), findsOneWidget);
        expect(find.text('Hôm nay bạn muốn ôn tập gì?'), findsOneWidget);
      },
    );
  });
}