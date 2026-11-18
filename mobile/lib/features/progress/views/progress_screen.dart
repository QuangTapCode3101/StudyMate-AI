import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/active_context_provider.dart';
import '../viewmodels/analytics_viewmodel.dart';
import 'widgets/analytics_dashboard_tab.dart';
import 'widgets/system_settings_modal.dart';

import 'package:studymate_ai/features/flashcards/views/flashcard_decks_tab.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _selectedSubTab = 1;
  int _lastObservedMainTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsViewModel>().loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tự động làm mới dữ liệu ngầm mỗi khi người dùng bấm sang Tab 5 (index == 4)
    final currentMainTab = context.select<ActiveStudyContextProvider, int>(
      (p) => p.currentTabIndex,
    );
    if (currentMainTab == 4 && _lastObservedMainTab != 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AnalyticsViewModel>().loadAnalytics(showLoading: false);
        }
      });
    }
    _lastObservedMainTab = currentMainTab;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tiến độ & Ghi nhớ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Cấu hình Hệ thống (MDL-03)',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => SystemSettingsModal.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    icon: Icon(Icons.style_outlined, size: 18),
                    label: Text('Bộ thẻ SM-2'),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    icon: Icon(Icons.insights_outlined, size: 18),
                    label: Text('Phân tích năng lực'),
                  ),
                ],
                selected: {_selectedSubTab},
                onSelectionChanged: (selection) {
                  setState(() => _selectedSubTab = selection.first);
                },
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedSubTab,
              children: const [
                FlashcardDecksTab(),
            

                // Ngăn 1: Toàn bộ nội dung TASK-602 của M1
                AnalyticsDashboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
