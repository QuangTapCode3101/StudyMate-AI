import 'package:flutter/material.dart';
import '../../../core/models/shared_models.dart';
import '../library_style.dart';

/// Thẻ môn học trong SCR-02: icon thư mục + tên, nhãn ngôn ngữ, số tài liệu/chủ đề,
/// thanh tiến độ và dòng "Tiến độ: x%". Nhấn giữ để xóa môn học.
class SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final progress = subject.avgMasteryScore.clamp(0, 100).toDouble();
    final color = LibraryStyle.progressColor(progress);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LibraryStyle.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder, color: LibraryStyle.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: LibraryStyle.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subject.programmingLanguage,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LibraryStyle.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${subject.docCount} tài liệu • ${subject.topicCount} chủ đề',
                style: const TextStyle(
                  fontSize: 13,
                  color: LibraryStyle.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tiến độ: ${progress.round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  color: LibraryStyle.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
