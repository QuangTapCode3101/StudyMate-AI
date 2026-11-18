import 'package:flutter/material.dart';

import '../../../../core/widgets/mastery_badge.dart';
import '../../models/tutor_models.dart';
import '../tutor_style.dart';

/// Bảng chọn Môn học • Chủ đề (mở từ thanh chọn ngữ cảnh trên AppBar của SCR-05).
/// Trả về [TutorContext] được chọn qua Navigator.pop.
class TopicPickerSheet extends StatelessWidget {
  const TopicPickerSheet({
    super.key,
    required this.topics,
    required this.selectedTopicId,
  });

  final List<TutorContext> topics;
  final int? selectedTopicId;

  @override
  Widget build(BuildContext context) {
    // Gom chủ đề theo môn học, giữ nguyên thứ tự từ SQLite.
    final grouped = <String, List<TutorContext>>{};
    for (final topic in topics) {
      grouped.putIfAbsent(topic.subjectName, () => []).add(topic);
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Chọn chủ đề muốn học với AI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TutorStyle.textDark,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TutorStyle.textMuted,
                        ),
                      ),
                    ),
                    for (final topic in entry.value)
                      ListTile(
                        title: Text(
                          topic.topicName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: MasteryBadge(score: topic.masteryScore),
                          ),
                        ),
                        trailing: topic.topicId == selectedTopicId
                            ? const Icon(
                                Icons.check_circle,
                                color: TutorStyle.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(topic),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
