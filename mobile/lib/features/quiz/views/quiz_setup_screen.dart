import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/shared_models.dart';
import '../../../core/providers/active_context_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/mastery_badge.dart';
import '../../../core/widgets/section_header.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'active_quiz_screen.dart';

/// Màn hình SCR-06: Cấu hình Tạo đề Luyện tập Trắc nghiệm Kỹ thuật (Tab 4)
class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeContext = context.read<ActiveStudyContextProvider>();
      context.read<QuizViewModel>().initSetup(
            preferredSubjectId: activeContext.activeSubjectId,
            preferredTopicId: activeContext.activeTopicId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuizViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Luyện tập Trắc nghiệm',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: vm.isLoading && vm.subjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner giới thiệu
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Đề thi Chẩn đoán Lập trình',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Hệ thống AI tự động phân tích điểm yếu và sinh đề gồm 3 dạng câu hỏi IT chuyên sâu: Tìm lỗi code (Spot Bug), Dự đoán output và Khái niệm.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. CHỌN MÔN HỌC & CHỦ ĐỀ
                  const SectionHeader(
                    title: '1. Chọn môn học & Chủ đề',
                  ),
                  const SizedBox(height: 12),

                  // Dropdown chọn môn
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SubjectModel>(
                        isExpanded: true,
                        value: vm.selectedSubject,
                        hint: const Text('Chọn môn học'),
                        items: vm.subjects.map((sub) {
                          return DropdownMenuItem<SubjectModel>(
                            value: sub,
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book, color: Color(0xFF2563EB), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    sub.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  sub.programmingLanguage,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) vm.selectSubject(val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Danh sách chủ đề (Chips có MasteryBadge)
                  if (vm.topics.isNotEmpty) ...[
                    const Text(
                      'Chủ đề kiến thức:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: vm.topics.map((top) {
                        final isSelected = vm.selectedTopic?.id == top.id;
                        return ChoiceChip(
                          selected: isSelected,
                          onSelected: (_) => vm.selectTopic(top),
                          selectedColor: const Color(0xFFEFF6FF),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                top.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              MasteryBadge(score: top.masteryScore),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 2. CẤU HÌNH ĐỀ THI
                  const SectionHeader(
                    title: '2. Cấu hình bài thi',
                  ),
                  const SizedBox(height: 12),

                  // Số lượng câu hỏi
                  Row(
                    children: [
                      const Text(
                        'Số lượng câu hỏi:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const Spacer(),
                      ChoiceChip(
                        label: const Text('5 câu'),
                        selected: vm.questionCount == 5,
                        onSelected: (_) => vm.setQuestionCount(5),
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: vm.questionCount == 5 ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('10 câu'),
                        selected: vm.questionCount == 10,
                        onSelected: (_) => vm.setQuestionCount(10),
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: vm.questionCount == 10 ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Dạng câu hỏi kỹ thuật
                  const Text(
                    'Dạng câu hỏi kỹ thuật CNTT:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('🔍 Tìm lỗi code (Spot Bug)'),
                        selected: vm.selectedQuestionTypes.contains('SPOT_BUG'),
                        onSelected: (_) => vm.toggleQuestionType('SPOT_BUG'),
                        selectedColor: const Color(0xFFFEF3C7),
                        checkmarkColor: const Color(0xFFD97706),
                      ),
                      FilterChip(
                        label: const Text('⚡ Dự đoán kết quả (Output)'),
                        selected: vm.selectedQuestionTypes.contains('PREDICT_OUTPUT'),
                        onSelected: (_) => vm.toggleQuestionType('PREDICT_OUTPUT'),
                        selectedColor: const Color(0xFFEDE9FE),
                        checkmarkColor: const Color(0xFF7C3AED),
                      ),
                      FilterChip(
                        label: const Text('📖 Khái niệm (Concept)'),
                        selected: vm.selectedQuestionTypes.contains('CONCEPT'),
                        onSelected: (_) => vm.toggleQuestionType('CONCEPT'),
                        selectedColor: const Color(0xFFE0F2FE),
                        checkmarkColor: const Color(0xFF0284C7),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Độ khó
                  Row(
                    children: [
                      const Text(
                        'Độ khó:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const Spacer(),
                      ChoiceChip(
                        label: const Text('Dễ'),
                        selected: vm.difficulty == 'EASY',
                        onSelected: (_) => vm.setDifficulty('EASY'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Vừa'),
                        selected: vm.difficulty == 'MEDIUM',
                        onSelected: (_) => vm.setDifficulty('MEDIUM'),
                        selectedColor: const Color(0xFFEFF6FF),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Khó'),
                        selected: vm.difficulty == 'HARD',
                        onSelected: (_) => vm.setDifficulty('HARD'),
                      ),
                    ],
                  ),

                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vm.errorMessage!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Nút bắt đầu làm bài
                  AppButton(
                    label: 'Bắt đầu làm bài thi',
                    icon: Icons.play_arrow_rounded,
                    isFullWidth: true,
                    isLoading: vm.isLoading,
                    onPressed: vm.selectedTopic == null
                        ? null
                        : () async {
                            final success = await vm.startQuiz();
                            if (success && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ActiveQuizScreen(),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
    );
  }
}
