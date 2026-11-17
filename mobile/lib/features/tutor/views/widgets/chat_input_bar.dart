import 'package:flutter/material.dart';

import '../tutor_style.dart';

/// Ô nhập câu hỏi tự do "Hỏi AI Tutor của bạn..." kèm nút gửi.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: TutorStyle.surface,
        border: Border(top: BorderSide(color: TutorStyle.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Hỏi AI Tutor của bạn...',
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
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send, size: 20),
            style: IconButton.styleFrom(backgroundColor: TutorStyle.primary),
            tooltip: 'Gửi',
          ),
        ],
      ),
    );
  }
}
