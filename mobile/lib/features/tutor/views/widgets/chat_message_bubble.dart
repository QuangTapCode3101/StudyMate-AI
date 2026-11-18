import 'package:flutter/material.dart';

import '../../../../core/widgets/source_citation_chip.dart';
import '../../models/tutor_models.dart';
import '../tutor_style.dart';
import 'markdown_code_view.dart';

/// Bong bóng tin nhắn: người dùng căn phải (nền xanh), AI căn trái kèm avatar,
/// nội dung Markdown + khối code, các chip trích dẫn nguồn và nút Kiểm tra nhanh.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.showMiniQuizButton,
    required this.onCitationTap,
    required this.onMiniQuizTap,
    this.onEditTap,
    this.miniQuizEnabled = true,
  });

  final ChatMessageModel message;
  final bool showMiniQuizButton;
  final ValueChanged<CitationModel> onCitationTap;
  final VoidCallback onMiniQuizTap;

  /// Khác null chỉ ở câu hỏi mới nhất của người dùng (cho phép sửa); null thì ẩn nút bút chì.
  final VoidCallback? onEditTap;

  /// Tắt (làm mờ) nút Kiểm tra nhanh khi đang mất kết nối.
  final bool miniQuizEnabled;

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _buildUserBubble(context) : _buildAiBubble(context);
  }

  Widget _buildUserBubble(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: TutorStyle.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(
        message.content,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
      ),
    );

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(left: onEditTap == null ? 48 : 16, bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (onEditTap != null)
              IconButton(
                onPressed: onEditTap,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: TutorStyle.textMuted,
                tooltip: 'Sửa câu hỏi',
                visualDensity: VisualDensity.compact,
              ),
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context) {
    final hasContent = message.content.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: TutorStyle.primaryLight,
            child: Icon(Icons.smart_toy, size: 18, color: TutorStyle.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isStreaming
                      ? 'AI Tutor • đang trả lời...'
                      : 'AI Tutor • ${_timeAgo(message.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TutorStyle.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TutorStyle.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: TutorStyle.border),
                  ),
                  child: hasContent
                      ? MarkdownCodeView(data: message.content)
                      : const _TypingIndicator(),
                ),
                if (message.citations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final citation in message.citations)
                        SourceCitationChip(
                          documentTitle: citation.docTitle,
                          pageLabel: citation.pageLabel,
                          onTap: () => onCitationTap(citation),
                        ),
                    ],
                  ),
                ],
                if (showMiniQuizButton) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: miniQuizEnabled ? onMiniQuizTap : null,
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('Kiểm tra nhanh 3 câu về phần này'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TutorStyle.primary,
                        side: const BorderSide(color: TutorStyle.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Vừa xong", "3 phút trước", "2 giờ trước" hoặc ngày giờ nếu đã lâu.
  static String _timeAgo(String isoTime) {
    final time = DateTime.tryParse(isoTime);
    if (time == null) {
      return '';
    }
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.day)}/${two(time.month)} ${two(time.hour)}:${two(time.minute)}';
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10),
        Text(
          'AI đang soạn câu trả lời...',
          style: TextStyle(fontSize: 13, color: TutorStyle.textMuted),
        ),
      ],
    );
  }
}
