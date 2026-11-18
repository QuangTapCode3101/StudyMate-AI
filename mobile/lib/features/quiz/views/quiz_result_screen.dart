import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/code_snippet_box.dart';
import '../../../core/widgets/mastery_badge.dart';
import '../../../core/widgets/section_header.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'active_quiz_screen.dart';

/// Màn hình SCR-08: Kết quả Thi & Chẩn đoán Lỗ hổng Kiến thức
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuizViewModel>();

    final score = vm.score;
    final correctCount = vm.correctCount;
    final total = vm.totalQuestions;
    final wrongCount = vm.wrongQuestions.length;

    // Màu sắc theo thang điểm
    Color scoreColor = const Color(0xFF16A34A); // >= 80% Xanh
    String resultTitle = 'Tuyệt vời! Bạn đã nắm vững chủ đề này.';
    if (score < 50) {
      scoreColor = const Color(0xFFDC2626); // < 50% Đỏ
      resultTitle = 'Cần ôn luyện lại! Điểm thông thạo của bạn đang ở mức thấp.';
    } else if (score < 80) {
      scoreColor = const Color(0xFFD97706); // 50-79% Vàng
      resultTitle = 'Khá tốt! Bạn hãy củng cố các câu còn làm sai.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kết quả Luyện tập',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Thẻ Điểm số Tổng kết
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Vòng tròn điểm số
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scoreColor.withValues(alpha: 0.1),
                      border: Border.all(color: scoreColor, width: 4),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          '$correctCount/$total câu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    resultTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thời gian hoàn thành: ${vm.elapsedSeconds} giây',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Biến động Năng lực Chủ đề (Topic Mastery Impact)
            if (vm.selectedTopic != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biến động Năng lực Chủ đề:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vm.selectedTopic!.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        MasteryBadge(score: vm.topicMasteryBefore),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF94A3B8)),
                        ),
                        MasteryBadge(score: vm.topicMasteryAfter),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // 3. Nút bấm Tạo Flashcard từ các câu làm sai
            if (wrongCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bạn làm sai $wrongCount câu hỏi kỹ thuật.',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tạo ngay các câu làm sai thành bộ thẻ ôn tập ngắt quãng (SM-2) để ghi nhớ lỗ hổng kiến thức này lâu hơn.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: vm.isFlashcardCreated
                          ? '✓ Đã tạo ${vm.flashcardsAddedCount} thẻ vào Bộ nhớ SM-2'
                          : '+ Tạo Flashcard từ $wrongCount câu làm sai',
                      variant: vm.isFlashcardCreated
                          ? AppButtonVariant.outline
                          : AppButtonVariant.primary,
                      icon: vm.isFlashcardCreated ? Icons.check : Icons.add_to_photos_outlined,
                      isFullWidth: true,
                      isLoading: vm.isLoading,
                      onPressed: vm.isFlashcardCreated
                          ? null
                          : () async {
                              final count = await vm.createFlashcardsFromMistakes();
                              if (context.mounted && count > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã thêm thành công $count thẻ vào Bộ thẻ ôn tập SM-2!'),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 4. Danh sách Chi tiết Đối chiếu Từng câu
            const SectionHeader(
              title: 'Chi tiết bài làm & Giải thích',
            ),
            const SizedBox(height: 12),

            ...List.generate(vm.currentQuestions.length, (idx) {
              final q = vm.currentQuestions[idx];
              final userChoice = vm.userAnswers[idx] ?? -1;
              final isCorrect = userChoice == q.correctIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCorrect
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFECACA),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCorrect ? '✓ ĐÚNG' : '✗ SAI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCorrect
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Câu ${idx + 1}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      q.questionText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (q.codeSnippet != null && q.codeSnippet!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      CodeSnippetBox(
                        code: q.codeSnippet!,
                        language: 'dart',
                        showLineNumbers: q.questionType == 'SPOT_BUG',
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Đáp án người dùng chọn
                    Text(
                      'Bạn chọn: ${userChoice >= 0 && userChoice < q.options.length ? q.options[userChoice] : "Chưa chọn"}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đáp án đúng: ${q.options[q.correctIndex]}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    // Khối Giải thích
                    if (q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '💡 Giải thích: ${q.explanation}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // 5. Nút Điều hướng hoàn tất / làm lại
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Làm lại đề này',
                    variant: AppButtonVariant.outline,
                    icon: Icons.refresh,
                    onPressed: () async {
                      final success = await vm.startQuiz();
                      if (success && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActiveQuizScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Hoàn tất',
                    icon: Icons.check,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
