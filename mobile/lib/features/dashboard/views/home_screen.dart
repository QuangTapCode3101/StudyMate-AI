import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/active_context_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/mastery_badge.dart';
import '../../../core/widgets/rate_limit_badge.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/account_sheet.dart';
import '../../auth/widgets/redeem_code_sheet.dart';
import '../models/dashboard_data_model.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadDashboard();
    });
  }

  Future<void> _openRedeemCode(BuildContext context) async {
    final vm = context.read<HomeViewModel>();
    final wasPremium = context.read<AuthProvider>().isPremium;

    await RedeemCodeSheet.show(context);

    if (!context.mounted) return;
    if (!wasPremium && context.read<AuthProvider>().isPremium) {
      await vm.loadDashboard();
    }
  }

  Future<void> _showAccountSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AccountSheet(
        onRedeemTap: () {
          Navigator.of(context).pop();
          _openRedeemCode(context);
        },
        onLogoutTap: () async {
          Navigator.of(context).pop();
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Đăng xuất'),
              content: const Text(
                'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Huỷ'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await context.read<AuthProvider>().logout();
          }
        },
      ),
    );
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    HomeViewModel vm,
    String currentName,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initialName: currentName),
    );

    if (newName == null) return;
    await vm.updateDisplayName(newName);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final auth = context.watch<AuthProvider>();
    final navProvider = context.read<ActiveStudyContextProvider>();
    final data = vm.summary;

    final effectiveName = vm.displayName.isNotEmpty
        ? vm.displayName
        : (auth.user?.displayName ?? '');
    final avatarLetter = effectiveName.isNotEmpty
        ? effectiveName.trim()[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Header: Tầng 1 (Lời chào + Quota + Avatar), Tầng 2 (Tên user)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vm.timeGreeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: auth.isPremium
                                ? null
                                : () => _openRedeemCode(context),
                            borderRadius: BorderRadius.circular(20),
                            child: RateLimitBadge(
                              remaining: vm.remainingQuota,
                              maxQuota: vm.maxQuota,
                              isOnline: vm.isBackendOnline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => _showAccountSheet(context),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: auth.isPremium
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFDBEAFE),
                                border: Border.all(
                                  color: auth.isPremium
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF2563EB),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                avatarLetter,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: auth.isPremium
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showEditNameDialog(context, vm, effectiveName),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            effectiveName.isEmpty
                                ? 'Hôm nay ôn tập gì nào? 👋'
                                : '$effectiveName 👋',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                  if (effectiveName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Hôm nay bạn muốn ôn tập gì?',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              if (vm.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (data == null || data.isEmpty)
                _buildEmptyState(vm)
              else ...[
                // 2. Hero Card: Tiếp tục học
                if (data.continueTopic != null)
                  _buildContinueStudyCard(
                    subjectName: data.activeSubjectName ?? 'Lập trình Flutter',
                    topicName: data.continueTopic!.name,
                    progress: data.continueTopic!.masteryScore,
                    onContinueTap: () {
                      navProvider.openAiTutorWithTopic(
                        subjectId: data.continueTopic!.subjectId,
                        topicId: data.continueTopic!.id!,
                      );
                    },
                  ),
                const SizedBox(height: 16),

                // 3. Banner vàng: Flashcard đến hạn ôn tập hôm nay
                _buildDueFlashcardBanner(
                  dueCount: data.dueFlashcardsCount,
                  onReviewTap: () {
                    navProvider.setTabIndex(4);
                  },
                ),
                const SizedBox(height: 24),

                // 4. Danh sách Chủ đề yếu cần ôn lại (< 50%)
                SectionHeader(
                  title: 'Chủ đề yếu cần ôn lại',
                  actionText: 'Xem tất cả',
                  onActionTap: () => navProvider.setTabIndex(1),
                ),
                const SizedBox(height: 8),
                if (data.weakTopics.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '🎉 Tuyệt vời! Không có chủ đề nào dưới 50% cần báo động.',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...data.weakTopics.map(
                    (item) => _buildWeakTopicCard(
                      item: item,
                      onQuizTap: () => navProvider.openQuizSetupWithTopic(
                        subjectId: item.topic.subjectId,
                        topicId: item.topic.id!,
                      ),
                      onAiTap: () => navProvider.openAiTutorWithTopic(
                        subjectId: item.topic.subjectId,
                        topicId: item.topic.id!,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueStudyCard({
    required String subjectName,
    required String topicName,
    required int progress,
    required VoidCallback onContinueTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIẾP TỤC HỌC',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subjectName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bài học: $topicName',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ: $progress%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppButton(
                label: 'Tiếp tục với AI Tutor',
                icon: Icons.auto_awesome,
                variant: AppButtonVariant.white,
                onPressed: onContinueTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDueFlashcardBanner({
    required int dueCount,
    required VoidCallback onReviewTap,
  }) {
    return InkWell(
      onTap: onReviewTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFFD97706),
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dueCount > 0
                    ? '$dueCount thẻ Flashcard đến hạn ôn tập hôm nay!'
                    : 'Bạn đã ôn hết thẻ Flashcard đến hạn hôm nay!',
                style: const TextStyle(
                  color: Color(0xFF78350F),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text(
              'Ôn ngay >',
              style: TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakTopicCard({
    required WeakTopicItem item,
    required VoidCallback onQuizTap,
    required VoidCallback onAiTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MasteryBadge(score: item.topic.masteryScore),
          const SizedBox(height: 10),
          Text(
            item.topic.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Môn: ${item.subjectName} • Từ khóa: ${item.topic.keywords.join(", ")}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Làm Quiz',
                variant: AppButtonVariant.outline,
                onPressed: onQuizTap,
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Học AI',
                variant: AppButtonVariant.primary,
                onPressed: onAiTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(HomeViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 48, color: Color(0xFF2563EB)),
          const SizedBox(height: 12),
          const Text(
            'Chưa có học liệu nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: vm.reloadDemoData,
            icon: const Icon(Icons.bolt),
            label: const Text('Nạp dữ liệu mẫu Lập trình Flutter'),
          ),
        ],
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  final String initialName;
  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tên hiển thị'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 24,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Nhập tên của bạn (để trống để ẩn)',
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}