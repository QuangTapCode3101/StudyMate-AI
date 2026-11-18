import 'package:flutter/material.dart';

import '../tutor_style.dart';

/// Ô nhập câu hỏi tự do "Hỏi AI Tutor của bạn..." kèm nút gửi.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.showStop = false,
    this.onStop,
    this.focusNode,
    this.isEditing = false,
    this.onCancelEdit,
    this.hintText,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  /// Đang nhận câu trả lời: nút Gửi đổi thành nút Dừng.
  final bool showStop;
  final VoidCallback? onStop;
  final FocusNode? focusNode;

  /// Đang sửa câu hỏi đã gửi: hiện dải "Đang sửa câu hỏi" kèm nút Hủy.
  final bool isEditing;
  final VoidCallback? onCancelEdit;

  /// Gợi ý thay thế (ví dụ khi mất kết nối). Null thì dùng gợi ý mặc định.
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: TutorStyle.surface,
        border: Border(top: BorderSide(color: TutorStyle.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isEditing) _buildEditStrip(),
          _buildInputRow(),
        ],
      ),
    );
  }

  Widget _buildEditStrip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, size: 16, color: TutorStyle.primary),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Đang sửa câu hỏi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TutorStyle.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancelEdit,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: hintText ??
                  (isEditing
                      ? 'Sửa câu hỏi của bạn...'
                      : 'Hỏi AI Tutor của bạn...'),
              hintStyle: const TextStyle(color: TutorStyle.textMuted),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (showStop)
          IconButton.filled(
            onPressed: onStop,
            icon: const Icon(Icons.stop, size: 22),
            style: IconButton.styleFrom(backgroundColor: TutorStyle.danger),
            tooltip: 'Dừng câu trả lời',
          )
        else
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send, size: 20),
            style: IconButton.styleFrom(backgroundColor: TutorStyle.primary),
            tooltip: isEditing ? 'Gửi lại câu hỏi' : 'Gửi',
          ),
      ],
    );
  }
}
