import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/providers/active_context_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // khởi tạo dtb
  await DatabaseHelper.instance.seedDemoFlutterCourse();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActiveStudyContextProvider()),
      ],
      child: const StudyMateApp(),
    ),
  );
}

class StudyMateApp extends StatelessWidget {
  const StudyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyMate AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const MainShellScreen(),
    );
  }
}

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<ActiveStudyContextProvider>();

    // M1, M2, M3, M4 sẽ thay thế 5 Widget giữ chỗ này bằng màn hình thật của mình
    final List<Widget> tabs = [
      const Center(child: Text('SCR-01: Trang chủ (M1 phụ trách)')),
      const Center(child: Text('SCR-02: Thư viện môn học (M2 phụ trách)')),
      const Center(child: Text('SCR-05: AI Tutor (M3 phụ trách)')),
      const Center(child: Text('SCR-06: Luyện tập Quiz (M4 phụ trách)')),
      const Center(child: Text('SCR-09: Tiến độ & Bộ thẻ (M1 & M4 phụ trách)')),
    ];

    return Scaffold(
      body: IndexedStack(
        index: navProvider.currentTabIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navProvider.currentTabIndex,
        onDestinationSelected: (idx) => navProvider.setTabIndex(idx),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEFF6FF),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF2563EB)), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder, color: Color(0xFF2563EB)), label: 'Thư viện'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy, color: Color(0xFF2563EB)), label: 'AI Tutor'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz, color: Color(0xFF2563EB)), label: 'Luyện tập'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights, color: Color(0xFF2563EB)), label: 'Tiến độ'),
        ],
      ),
    );
  }
}