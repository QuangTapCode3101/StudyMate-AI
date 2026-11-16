import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/dashboard/views/home_screen.dart';
import '../providers/active_context_provider.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key});

  // Đưa ra ngoài hàm build với từ khóa static const để tối ưu bộ nhớ khi chuyển tab
  static const List<Widget> _tabs = [
    HomeScreen(),
    Center(child: Text('SCR-02: Thư viện môn học (M2 phụ trách)')),
    Center(child: Text('SCR-05: AI Tutor (M3 phụ trách)')),
    Center(child: Text('SCR-06: Luyện tập Quiz (M4 phụ trách)')),
    Center(child: Text('SCR-09: Tiến độ & Bộ thẻ (M1 & M4 phụ trách)')),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<ActiveStudyContextProvider>();

    return Scaffold(
      body: IndexedStack(
        index: navProvider.currentTabIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navProvider.currentTabIndex,
        onDestinationSelected: navProvider.setTabIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEFF6FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2563EB)),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder, color: Color(0xFF2563EB)),
            label: 'Thư viện',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy, color: Color(0xFF2563EB)),
            label: 'AI Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz, color: Color(0xFF2563EB)),
            label: 'Luyện tập',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: Color(0xFF2563EB)),
            label: 'Tiến độ',
          ),
        ],
      ),
    );
  }
}