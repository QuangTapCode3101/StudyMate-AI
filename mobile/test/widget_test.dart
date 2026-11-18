// Basic smoke test for StudyMate AI app.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studymate_ai/core/providers/active_context_provider.dart';
import 'package:studymate_ai/features/dashboard/viewmodels/home_viewmodel.dart';
import 'package:studymate_ai/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ActiveStudyContextProvider()),
          ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ],
        child: const StudyMateApp(),
      ),
    );

    expect(find.byType(StudyMateApp), findsOneWidget);
  });
}
