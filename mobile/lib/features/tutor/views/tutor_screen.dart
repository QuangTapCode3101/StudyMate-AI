import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/active_context_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/rate_limit_badge.dart';
import '../models/tutor_models.dart';
import '../repositories/tutor_repository.dart';
import '../viewmodels/tutor_viewmodel.dart';
import 'tutor_style.dart';
import 'widgets/chat_history_sheet.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/citation_viewer_sheet.dart';
import 'widgets/mini_quiz_sheet.dart';
import 'widgets/quick_action_chips.dart';
import 'widgets/topic_picker_sheet.dart';

/// SCR-05: Màn hình AI Tutor (tab thứ 3 của thanh điều hướng).
class TutorScreen extends StatelessWidget {
  const TutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TutorViewModel>(
      create: (_) => TutorViewModel()..init(),
      child: const _TutorView(),
    );
  }
}

class _TutorView extends StatefulWidget {
  const _TutorView();

  @override
  State<_TutorView> createState() => _TutorViewState();
}

class _TutorViewState extends State<_TutorView> {
  static const double _stickToBottomDistance = 120;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TutorRepository _repository = TutorRepository();

  int? _lastSyncedTopicId;
  bool _wasTabActive = false;
  int _lastMessageCount = 0;
  int _lastContentLength = 0;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Đồng bộ với thanh điều hướng (ActiveStudyContextProvider)
  // ---------------------------------------------------------------------------

  void _syncWithNavigation(
    ActiveStudyContextProvider nav,
    TutorViewModel vm,
  ) {
    final isActive = nav.currentTabIndex == 2;
    final topicId = nav.activeTopicId;

    final shouldRefresh = isActive && !_wasTabActive;
    _wasTabActive = isActive;

    final shouldSelect = topicId != null && topicId != _lastSyncedTopicId;
    if (shouldSelect) {
      _lastSyncedTopicId = topicId;
    }

    if (!shouldRefresh && !shouldSelect) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (shouldSelect) {
        await vm.selectTopic(topicId);
      }
      if (shouldRefresh && mounted) {
        await vm.refreshTopics();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Tự cuộn xuống cuối khi có tin nhắn mới / chữ chạy dần
  // ---------------------------------------------------------------------------

  void _scheduleAutoScroll(TutorViewModel vm) {
    final messages = vm.messages;
    final count = messages.length;
    final contentLength = messages.isEmpty ? 0 : messages.last.content.length;

    final countChanged = count != _lastMessageCount;
    final contentChanged = contentLength != _lastContentLength;
    _lastMessageCount = count;
    _lastContentLength = contentLength;

    if (!countChanged && !contentChanged) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final distance = position.maxScrollExtent - position.pixels;

      if (countChanged) {
        _scrollController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else if (distance < _stickToBottomDistance) {
        // Đang đọc ở cuối thì bám theo chữ mới; đang cuộn lên đọc thì không kéo.
        _scrollController.jumpTo(position.maxScrollExtent);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Hành động của người dùng
  // ---------------------------------------------------------------------------

  void _send(TutorViewModel vm) {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _inputController.clear();
    vm.sendUserMessage(text);
  }

  Future<void> _openTopicPicker(
    TutorViewModel vm,
    ActiveStudyContextProvider nav,
  ) async {
    final selected = await showModalBottomSheet<TutorContext>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TopicPickerSheet(
        topics: vm.topics,
        selectedTopicId: vm.topicContext?.topicId,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }
    // Cập nhật ngữ cảnh chung để các tab khác (Luyện tập...) cùng chủ đề.
    nav.openAiTutorWithTopic(
      subjectId: selected.subjectId,
      topicId: selected.topicId,
    );
  }

  Future<void> _openHistory(TutorViewModel vm) async {
    await vm.refreshSessions();
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider<TutorViewModel>.value(
        value: vm,
        child: const ChatHistorySheet(),
      ),
    );
  }

  Future<void> _openCitation(CitationModel citation) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CitationViewerSheet(
        citation: citation,
        repository: _repository,
      ),
    );
  }

  Future<void> _openMiniQuiz(TutorViewModel vm, ChatMessageModel message) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MiniQuizSheet(
        loadQuestions: () => vm.generateMiniQuiz(message.content),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Giao diện
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TutorViewModel>();
    final nav = context.watch<ActiveStudyContextProvider>();

    _syncWithNavigation(nav, vm);
    _scheduleAutoScroll(vm);

    final canInteract =
        vm.topicContext != null && !vm.isLoading && !vm.isStreaming;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(vm, nav),
            if (vm.topicContext != null)
              QuickActionChips(
                selected: vm.selectedMode,
                enabled: canInteract,
                onSelected: vm.sendQuickAction,
              ),
            Expanded(child: _buildBody(vm, nav)),
            if (vm.errorMessage != null) _buildErrorBanner(vm),
            ChatInputBar(
              controller: _inputController,
              enabled: canInteract,
              onSend: () => _send(vm),
              showStop: vm.canStop,
              onStop: vm.stopStreaming,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TutorViewModel vm, ActiveStudyContextProvider nav) {
    final topic = vm.topicContext;
    final hasTopics = vm.topics.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: TutorStyle.surface,
        border: Border(bottom: BorderSide(color: TutorStyle.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: hasTopics ? () => _openTopicPicker(vm, nav) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        topic?.displayTitle ?? 'Chọn chủ đề',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TutorStyle.textDark,
                        ),
                      ),
                    ),
                    if (hasTopics)
                      const Icon(
                        Icons.arrow_drop_down,
                        color: TutorStyle.textMuted,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          RateLimitBadge(
            remaining: vm.remainingQuota,
            maxQuota: vm.maxQuota,
            isOnline: vm.isBackendOnline,
            onTap: vm.refreshQuota,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử trò chuyện',
            onPressed: vm.topicContext == null ? null : () => _openHistory(vm),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TutorViewModel vm, ActiveStudyContextProvider nav) {
    if (vm.isLoading && vm.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppEmptyState(
            icon: Icons.smart_toy_outlined,
            title: 'Chưa có học liệu để hỏi AI',
            subtitle:
                'Hãy thêm tài liệu vào một chủ đề trong Thư viện, sau đó quay lại đây để học cùng AI Tutor.',
            actionLabel: 'Đến Thư viện',
            actionIcon: Icons.folder_open,
            onActionPressed: () => nav.setTabIndex(1),
          ),
        ),
      );
    }

    if (vm.messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: AppEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Bắt đầu cuộc trò chuyện',
            subtitle:
                'Chọn một gợi ý ở phía trên hoặc nhập câu hỏi về chủ đề này.',
          ),
        ),
      );
    }

    final quizIndex = vm.latestAiMessageIndex;
    final messages = vm.messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final message = messages[index];
        return ChatMessageBubble(
          key: ValueKey('msg_${message.id ?? 'tmp'}_$index'),
          message: message,
          showMiniQuizButton: index == quizIndex && !vm.isStreaming,
          onCitationTap: _openCitation,
          onMiniQuizTap: () => _openMiniQuiz(vm, message),
        );
      },
    );
  }

  Widget _buildErrorBanner(TutorViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      color: TutorStyle.dangerLight,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: TutorStyle.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vm.errorMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: TutorStyle.textDark,
              ),
            ),
          ),
          if (vm.canRetry)
            TextButton(
              onPressed: vm.retry,
              child: const Text('Thử lại'),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Đóng',
            onPressed: vm.dismissError,
          ),
        ],
      ),
    );
  }
}
