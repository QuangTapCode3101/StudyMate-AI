import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studymate_ai/features/progress/viewmodels/analytics_viewmodel.dart';

import 'core/database/database_helper.dart';
import 'core/network/api_client.dart';
import 'core/providers/active_context_provider.dart';
import 'core/widgets/main_navigation_shell.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/widgets/auth_gate.dart';
import 'features/dashboard/viewmodels/home_viewmodel.dart';
import 'features/flashcards/viewmodels/flashcard_viewmodel.dart';
import 'features/quiz/viewmodels/quiz_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final baseUrl = await ApiClient.instance.getBaseUrl();
  final authService = AuthService(baseUrl: baseUrl);

  final authProvider = AuthProvider(
    authService: authService,
    onBeforeLogout: () async {
      await DatabaseHelper.instance.closeDatabase();
    },
  );

  ApiClient.instance.configureAuth(
    tokenProvider: () => authService.getToken(),
    onUnauthorized: () async {
      await authProvider.logout();
    },
  );

  // Gọi kiểm tra phiên đăng nhập 1 lần duy nhất tại đây (không cần await)
  authProvider.checkAuthStatus();

  runApp(
    ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const StudyMateApp(),
    ),
  );
}

class StudyMateApp extends StatelessWidget {
  const StudyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthProvider, int?>((auth) => auth.userId);

    return _UserSessionScope(
      key: ValueKey(userId),
      child: MaterialApp(
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
        home: const AuthGate(
          unauthenticatedChild: LoginScreen(),
          authenticatedChild: MainNavigationShell(),
        ),
      ),
    );
  }
}

class _UserSessionScope extends StatelessWidget {
  final Widget child;

  const _UserSessionScope({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActiveStudyContextProvider()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => QuizViewModel()),
        ChangeNotifierProvider(create: (_) => FlashcardViewModel()),
        ChangeNotifierProvider(create: (_) => AnalyticsViewModel()),
      ],
      child: child,
    );
  }
}