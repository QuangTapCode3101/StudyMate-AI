import 'package:flutter/material.dart';
import '../../../core/models/shared_models.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/mastery_badge.dart';
import '../library_style.dart';

/// Thẻ chủ đề trong SCR-03: tên + MasteryBadge + chip từ khóa monospace.
/// Nhấn vào thẻ để mở/đóng 2 nút [Học với AI] và [Luyện Quiz].
class TopicActionCard extends StatelessWidget {
  final TopicModel topic;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onStudyWithAi;
  final VoidCallback onPracticeQuiz;

  const TopicActionCard({
    super.key,
    required this.topic,
    required this.expanded,
    required this.onToggle,
    required this.onStudyWithAi,
    required this.onPracticeQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LibraryStyle.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      topic.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LibraryStyle.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MasteryBadge(score: topic.masteryScore),
                ],
              ),
              if (topic.keywords.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final keyword in topic.keywords)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          keyword,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: LibraryStyle.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topCenter,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: '[Học với AI]',
                                onPressed: onStudyWithAi,
                                isFullWidth: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppButton(
                                label: '[Luyện Quiz]',
                                variant: AppButtonVariant.outline,
                                onPressed: onPracticeQuiz,
                                isFullWidth: true,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
