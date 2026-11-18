import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../viewmodels/flashcard_viewmodel.dart';
import 'flashcard_review_screen.dart';

/// Sub-tab 1 của SCR-09: Danh sách các Bộ thẻ Flashcard theo môn học & số thẻ đến hạn
class FlashcardDecksTab extends StatefulWidget {
  const FlashcardDecksTab({super.key});

  @override
  State<FlashcardDecksTab> createState() => _FlashcardDecksTabState();
}

class _FlashcardDecksTabState extends State<FlashcardDecksTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardViewModel>().loadDecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FlashcardViewModel>();

    if (vm.isLoading && vm.deckStats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.deckStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 12),
              Text(
                vm.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Thử lại',
                variant: AppButtonVariant.outline,
                onPressed: vm.loadDecks,
              ),
            ],
          ),
        ),
      );
    }

    final totalDue = vm.totalDueToday;

    return RefreshIndicator(
      onRefresh: vm.loadDecks,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner tổng quan số thẻ cần ôn hôm nay
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: totalDue > 0
                      ? [const Color(0xFF2563EB), const Color(0xFF1E40AF)]
                      : [const Color(0xFF16A34A), const Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (totalDue > 0 ? const Color(0xFF2563EB) : const Color(0xFF16A34A))
                        .withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      totalDue > 0 ? Icons.psychology : Icons.check_circle_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalDue > 0
                              ? '$totalDue thẻ đến hạn ôn tập hôm nay'
                              : 'Bạn đã ôn hết toàn bộ thẻ hôm nay!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalDue > 0
                              ? 'Thuật toán SM-2 nhắc nhở bạn củng cố kiến thức trước khi bị lãng quên.'
                              : 'Trí nhớ của bạn đang ở trạng thái tốt nhất. Hãy quay lại vào ngày mai!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Danh sách các bộ thẻ theo môn học
            const SectionHeader(
              title: 'Các bộ thẻ theo môn học',
            ),
            const SizedBox(height: 12),

            if (vm.deckStats.isEmpty)
              const AppEmptyState(
                icon: Icons.style_outlined,
                title: 'Chưa có bộ thẻ nào',
                subtitle: 'Hãy hoàn thành các bài thi Quiz để tự động tạo Flashcard từ các câu làm sai.',
              )
            else
              ...vm.deckStats.map((deck) {
                final hasDue = deck.dueCards > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasDue
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFFE2E8F0),
                      width: hasDue ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book, color: Color(0xFF2563EB), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deck.subjectName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  deck.programmingLanguage,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge số thẻ đến hạn
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasDue
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hasDue ? '${deck.dueCards} cần ôn' : 'Đã xong',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: hasDue
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng số thẻ: ${deck.totalCards} thẻ',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          AppButton(
                            label: hasDue ? 'Ôn tập ngay' : 'Đã hoàn thành',
                            variant: hasDue
                                ? AppButtonVariant.primary
                                : AppButtonVariant.outline,
                            icon: hasDue ? Icons.play_arrow_rounded : Icons.check,
                            onPressed: !hasDue
                                ? null
                                : () async {
                                    final success = await vm.startReviewSession(
                                      subjectId: deck.subjectId,
                                      subjectName: deck.subjectName,
                                    );
                                    if (success && context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const FlashcardReviewScreen(),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
