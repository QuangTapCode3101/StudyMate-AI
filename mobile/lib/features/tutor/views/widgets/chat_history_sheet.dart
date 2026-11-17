import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tutor_models.dart';
import '../../viewmodels/tutor_viewmodel.dart';
import '../tutor_style.dart';

/// MDL-03: Lịch sử các phiên chat của chủ đề đang chọn.
/// Cho phép tạo phiên mới, chuyển đổi giữa các phiên cũ và xóa lịch sử.
/// Cần được bọc trong ChangeNotifierProvider.value(value: tutorViewModel).
class ChatHistorySheet extends StatelessWidget {
  const ChatHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TutorViewModel>();
    final sessions = vm.sessions;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lịch sử trò chuyện',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TutorStyle.textDark,
                      ),
                    ),
                  ),
                  if (sessions.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearAll(context, vm),
                      child: const Text(
                        'Xóa tất cả',
                        style: TextStyle(color: TutorStyle.danger),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await vm.startNewSession();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Cuộc trò chuyện mới'),
                ),
              ),
            ),
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Chưa có cuộc trò chuyện nào cho chủ đề này.',
                    style: TextStyle(color: TutorStyle.textMuted),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isCurrent = session.id == vm.currentSession?.id;
                    return ListTile(
                      selected: isCurrent,
                      selectedTileColor: TutorStyle.primaryLight,
                      leading: Icon(
                        isCurrent
                            ? Icons.chat_bubble
                            : Icons.chat_bubble_outline,
                        color: isCurrent
                            ? TutorStyle.primary
                            : TutorStyle.textMuted,
                      ),
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_formatDate(session.createdAt)} • ${session.messageCount} tin nhắn',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: TutorStyle.textMuted,
                        tooltip: 'Xóa cuộc trò chuyện',
                        onPressed: () => _confirmDelete(context, vm, session),
                      ),
                      onTap: () async {
                        await vm.openSession(session.id!);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TutorViewModel vm,
    ChatSessionModel session,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Xóa cuộc trò chuyện?',
      message: 'Toàn bộ tin nhắn trong "${session.title}" sẽ bị xóa và không thể khôi phục.',
    );
    if (ok) {
      await vm.deleteSession(session.id!);
    }
  }

  Future<void> _confirmClearAll(BuildContext context, TutorViewModel vm) async {
    final ok = await _confirm(
      context,
      title: 'Xóa tất cả lịch sử?',
      message: 'Mọi cuộc trò chuyện của chủ đề này sẽ bị xóa và không thể khôi phục.',
    );
    if (ok) {
      await vm.clearTopicHistory();
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: TutorStyle.danger),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static String _formatDate(String isoTime) {
    final time = DateTime.tryParse(isoTime);
    if (time == null) {
      return '';
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.day)}/${two(time.month)}/${time.year} ${two(time.hour)}:${two(time.minute)}';
  }
}
