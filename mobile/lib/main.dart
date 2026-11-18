import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studymate_ai/features/progress/viewmodels/analytics_viewmodel.dart';
import 'core/database/database_helper.dart';
import 'core/providers/active_context_provider.dart';
import 'core/widgets/main_navigation_shell.dart';
import 'features/dashboard/viewmodels/home_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Database cục bộ
  await DatabaseHelper.instance.seedDemoFlutterCourse();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActiveStudyContextProvider()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => AnalyticsViewModel()),
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
      home: const MainNavigationShell(),
    );
  }
}