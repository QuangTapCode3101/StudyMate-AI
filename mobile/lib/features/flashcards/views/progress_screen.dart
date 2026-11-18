import 'package:flutter/material.dart';
import 'flashcard_decks_tab.dart';

/// Màn hình SCR-09: Tiến độ & Bộ thẻ ghi nhớ
/// Gồm 2 Sub-tab:
/// - Sub-tab 1 (M4 phụ trách): Bộ thẻ Flashcard SM-2
/// - Sub-tab 2 (M1 phụ trách): Phân tích Học tập (Learning Analytics)
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Tiến độ & Bộ thẻ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF2563EB),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF2563EB),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.style_outlined, size: 20),
                text: 'Bộ thẻ SM-2',
              ),
              Tab(
                icon: Icon(Icons.insights_outlined, size: 20),
                text: 'Phân tích học tập',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Sub-tab 1: Danh sách bộ thẻ SM-2 (M4)
            const FlashcardDecksTab(),

            // Sub-tab 2: Placeholder Thống kê Phân tích (M1 phụ trách)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.insights, size: 48, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SCR-09 Sub-tab 2: Phân tích Học tập',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Module Thống kê Radar Chart & Lịch sử học tập do Lead M1 phụ trách.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
