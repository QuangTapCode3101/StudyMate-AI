import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/code_snippet_box.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'quiz_result_screen.dart';

/// Màn hình SCR-07: Phòng Làm bài Thi Trắc nghiệm Kỹ thuật (Toàn màn hình)
class ActiveQuizScreen extends StatelessWidget {
  const ActiveQuizScreen({super.key});

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy bài thi?'),
        content: const Text(
          'Bạn có chắc chắn muốn rời khỏi phòng thi? Toàn bộ kết quả bài làm hiện tại sẽ bị hủy và không được lưu lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục thi'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuizViewModel>();
    final q = vm.currentQuestion;

    if (q == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phòng thi')),
        body: const Center(child: Text('Không tìm thấy dữ liệu câu hỏi.')),
      );
    }

    final currentIndex = vm.currentQuestionIndex;
    final totalQuestions = vm.totalQuestions;
    final progress = (currentIndex + 1) / totalQuestions;
    final isLastQuestion = currentIndex == totalQuestions - 1;
    final selectedOption = vm.userAnswers[currentIndex];

    // Màu sắc theo dạng câu hỏi
    Color typeColor = const Color(0xFF2563EB);
    String typeLabel = 'Khái niệm (Concept)';
    if (q.questionType == 'SPOT_BUG') {
      typeColor = const Color(0xFFD97706);
      typeLabel = '🔍 Tìm lỗi code (Spot Bug)';
    } else if (q.questionType == 'PREDICT_OUTPUT') {
      typeColor = const Color(0xFF7C3AED);
      typeLabel = '⚡ Dự đoán kết quả (Output)';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop(context);
        if (shouldExit && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldExit = await _onWillPop(context);
              if (shouldExit && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Câu ${currentIndex + 1} / $totalQuestions',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
          actions: [
            // Đồng hồ đếm ngược
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: vm.remainingSeconds < 60
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: vm.remainingSeconds < 60
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: vm.remainingSeconds < 60
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vm.formattedTimer,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: vm.remainingSeconds < 60
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              minHeight: 4,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge dạng câu hỏi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Nội dung câu hỏi
              Text(
                q.questionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Khối Code Snippet nếu có
              if (q.codeSnippet != null && q.codeSnippet!.isNotEmpty) ...[
                CodeSnippetBox(
                  code: q.codeSnippet!,
                  language: 'dart',
                  showLineNumbers: q.questionType == 'SPOT_BUG',
                ),
                const SizedBox(height: 20),
              ],

              // Danh sách 4 thẻ đáp án
              const Text(
                'Chọn 1 đáp án đúng nhất:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),

              ...List.generate(q.options.length, (optIdx) {
                final isSelected = selectedOption == optIdx;
                final optLetter = String.fromCharCode(65 + optIdx); // A, B, C, D

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => vm.selectAnswer(optIdx),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFF1F5F9),
                            ),
                            child: Text(
                              optLetter,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              q.options[optIdx],
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              if (currentIndex > 0)
                Expanded(
                  child: AppButton(
                    label: 'Câu trước',
                    variant: AppButtonVariant.outline,
                    icon: Icons.chevron_left,
                    onPressed: vm.previousQuestion,
                  ),
                ),
              if (currentIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: isLastQuestion ? 'Nộp bài thi' : 'Câu tiếp theo',
                  icon: isLastQuestion ? Icons.check_circle_outline : Icons.chevron_right,
                  isLoading: vm.isLoading,
                  onPressed: () async {
                    if (isLastQuestion) {
                      // Nộp bài và sang màn hình SCR-08
                      await vm.submitQuiz();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QuizResultScreen(),
                          ),
                        );
                      }
                    } else {
                      vm.nextQuestion();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
