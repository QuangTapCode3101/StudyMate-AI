import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/code_snippet_box.dart';
import '../viewmodels/flashcard_viewmodel.dart';

/// Màn hình SCR-10: Màn hình Ôn tập Lật thẻ Spaced Repetition (SM-2) Toàn màn hình
class FlashcardReviewScreen extends StatelessWidget {
  const FlashcardReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FlashcardViewModel>();

    // Màn hình hoàn thành khi ôn hết thẻ
    if (vm.isSessionCompleted) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Hoàn tất ôn tập'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tuyệt vời! Bạn đã hoàn thành!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bạn vừa củng cố ${vm.reviewedCount} thẻ ghi nhớ theo thuật toán SM-2. Thuật toán sẽ tự động tính toán thời điểm nhắc nhở bạn vào những ngày tới.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Quay về danh sách bộ thẻ',
                  icon: Icons.check,
                  isFullWidth: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final card = vm.currentCard;
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ôn tập thẻ')),
        body: const Center(child: Text('Không tìm thấy thẻ ôn tập.')),
      );
    }

    final currentIndex = vm.currentIndex;
    final totalCards = vm.totalSessionCards;
    final progress = (currentIndex + 1) / totalCards;
    final isRevealed = vm.isBackRevealed;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thẻ ${currentIndex + 1} / $totalCards',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
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
          children: [
            // Thẻ Flashcard chính (Card tương tác chạm để lật)
            InkWell(
              onTap: vm.revealBack,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isRevealed
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                    width: isRevealed ? 1.8 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isRevealed
                          ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag Mặt trước
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'MẶT TRƯỚC - CÂU HỎI & CODE KHUYẾT',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          'EF: ${card.easeFactor}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nội dung câu hỏi mặt trước
                    Text(
                      card.frontText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.4,
                      ),
                    ),

                    // Đoạn code khuyết mặt trước
                    if (card.frontCode != null && card.frontCode!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      CodeSnippetBox(
                        code: card.frontCode!,
                        language: 'dart',
                        showLineNumbers: false,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Vùng Mặt sau (Ẩn cho đến khi chạm thẻ)
                    if (!isRevealed)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app_outlined, color: Color(0xFF64748B), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Chạm vào thẻ để xem đáp án',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      const Divider(color: Color(0xFFE2E8F0), thickness: 1.2),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MẶT SAU - ĐÁP ÁN & GIẢI THÍCH',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        card.backText,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF1E293B),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isRevealed
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đánh giá mức độ ghi nhớ (Thuật toán SM-2):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // 1. Again (q=1)
                      Expanded(
                        child: _Sm2Button(
                          label: 'Again',
                          intervalLabel: '1 ngày',
                          color: const Color(0xFFDC2626),
                          bgColor: const Color(0xFFFEE2E2),
                          onPressed: () => vm.submitRating(1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2. Hard (q=3)
                      Expanded(
                        child: _Sm2Button(
                          label: 'Hard',
                          intervalLabel: '3 ngày',
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFEF3C7),
                          onPressed: () => vm.submitRating(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3. Good (q=4)
                      Expanded(
                        child: _Sm2Button(
                          label: 'Good',
                          intervalLabel: card.interval == 0 ? '1 ngày' : '${(card.interval * card.easeFactor).round()} ngày',
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEFF6FF),
                          onPressed: () => vm.submitRating(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 4. Easy (q=5)
                      Expanded(
                        child: _Sm2Button(
                          label: 'Easy',
                          intervalLabel: '7+ ngày',
                          color: const Color(0xFF16A34A),
                          bgColor: const Color(0xFFDCFCE7),
                          onPressed: () => vm.submitRating(5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _Sm2Button extends StatelessWidget {
  final String label;
  final String intervalLabel;
  final Color color;
  final Color bgColor;
  final VoidCallback onPressed;

  const _Sm2Button({
    required this.label,
    required this.intervalLabel,
    required this.color,
    required this.bgColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              intervalLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
