import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers/active_context_provider.dart';
import '../../../core/widgets/mastery_badge.dart';
import '../../../core/widgets/rate_limit_badge.dart';
import '../models/dashboard_data_model.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/section_header.dart';

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

  void _showServerConfigModal(BuildContext context, HomeViewModel vm) async {
    final currentUrl = await ApiClient.instance.getBaseUrl();
    final controller = TextEditingController(text: currentUrl);

    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cấu hình Backend & Rate Limit (Demo)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              vm.isBackendOnline ? '🟢 Đã kết nối Backend Node.js thành công' : '🔴 Chưa kết nối được Backend (Đang chạy chế độ Offline SQLite)',
              style: TextStyle(
                fontSize: 13,
                color: vm.isBackendOnline
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Backend Base URL',
                hintText: 'http://10.0.2.2:3000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await vm.resetBackendQuota();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset 20/20 lượt AI'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await ApiClient.instance.setBaseUrl(controller.text);
                      await vm.refreshQuotaStatus();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                    child: const Text('Lưu & Kiểm tra'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final navProvider = context.read<ActiveStudyContextProvider>();
    final data = vm.summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Header: Lời chào + RateLimitBadge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào Quảng! 👋',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sinh viên năm 3 • CNTT',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  RateLimitBadge(
                    remaining: vm.remainingQuota,
                    maxQuota: vm.maxQuota,
                    isOnline: vm.isBackendOnline,
                    onTap: () => _showServerConfigModal(context, vm),
                  ),
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
                    // Chuyển sang Tab 5 (Tiến độ / Ôn tập SM-2)
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

                const SizedBox(height: 20),

                // 5. Footer: Lịch sử học tập nhanh
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.deepOrange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Chuỗi 5 ngày học liên tiếp',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tổng thẻ: ${data.totalMasteredCards}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
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
