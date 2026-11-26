import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/active_context_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/mastery_badge.dart';
import '../../../../core/widgets/section_header.dart';
import '../../models/analytics_data_model.dart';
import '../../viewmodels/analytics_viewmodel.dart';

class AnalyticsDashboardTab extends StatelessWidget {
  const AnalyticsDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnalyticsViewModel>();
    final navProvider = context.read<ActiveStudyContextProvider>();

    if (vm.isLoading && vm.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Đã xảy ra lỗi',
            subtitle: vm.errorMessage,
            actionLabel: 'Thử lại',
            onActionPressed: () => vm.loadAnalytics(),
          ),
        ),
      );
    }

    final dashboard = vm.data;
    if (dashboard == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadAnalytics(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. Lưới 4 ô KPI tổng hợp
          _KpiGridSection(kpi: dashboard.kpi),
          const SizedBox(height: 24),

          // 2. Bản đồ độ thông thạo chủ đề (Xếp từ yếu đến mạnh)
          const SectionHeader(title: 'Bản đồ năng lực theo chủ đề'),
          const SizedBox(height: 12),
          if (dashboard.topicMasteryList.isEmpty)
            const AppEmptyState(
              icon: Icons.account_tree_outlined,
              title: 'Chưa có chủ đề nào',
              subtitle: 'Hãy thêm tài liệu ở Thư viện hoặc nạp dữ liệu mẫu để xem bản đồ năng lực.',
            )
          else
            ...dashboard.topicMasteryList.map(
              (topic) => _TopicMasteryCard(
                topic: topic,
                onReviewNowTap: () => navProvider.openAiTutorWithTopic(
                  subjectId: topic.subjectId,
                  topicId: topic.topicId,
                ),
                onQuizTap: () => navProvider.openQuizSetupWithTopic(
                  subjectId: topic.subjectId,
                  topicId: topic.topicId,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 3. Lịch sử làm Quiz gần đây
          const SectionHeader(title: 'Lịch sử làm Quiz gần đây'),
          const SizedBox(height: 12),
          if (dashboard.recentAttempts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Chưa có lịch sử làm bài. Hãy sang tab Luyện tập để thử sức!',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            )
          else
            ...dashboard.recentAttempts.map(
              (attempt) => _QuizAttemptCard(attempt: attempt),
            ),
        ],
      ),
    );
  }
}

class _KpiGridSection extends StatelessWidget {
  final AnalyticsKpiModel kpi;

  const _KpiGridSection({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final accuracyText = '${kpi.accuracyPercentage.toStringAsFixed(0)}%';
    final strongTopicText = '${kpi.strongTopicsCount}/${kpi.totalTopicsCount}';
    final flashcardSubText = kpi.dueFlashcardsCount > 0
        ? '${kpi.dueFlashcardsCount} thẻ cần ôn'
        : 'Đã ôn hết hôm nay';

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _KpiStatCard(
          icon: Icons.quiz_outlined,
          iconColor: const Color(0xFF2563EB),
          label: 'Câu đã làm',
          value: '${kpi.totalQuestionsAnswered}',
          subLabel: 'Đúng ${kpi.totalCorrectAnswers} câu',
        ),
        _KpiStatCard(
          icon: Icons.track_changes_outlined,
          iconColor: const Color(0xFF16A34A),
          label: 'Tỷ lệ đúng',
          value: accuracyText,
          subLabel: 'Trung bình tích lũy',
        ),
        _KpiStatCard(
          icon: Icons.verified_outlined,
          iconColor: const Color(0xFF7C3AED),
          label: 'Chủ đề vững',
          value: strongTopicText,
          subLabel: 'Đạt từ 80% trở lên',
        ),
        _KpiStatCard(
          icon: Icons.style_outlined,
          iconColor: const Color(0xFFD97706),
          label: 'Thẻ Flashcard',
          value: '${kpi.totalFlashcardsCount}',
          subLabel: flashcardSubText,
        ),
      ],
    );
  }
}

class _KpiStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subLabel;

  const _KpiStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            subLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _TopicMasteryCard extends StatelessWidget {
  final TopicMasteryItem topic;
  final VoidCallback onReviewNowTap;
  final VoidCallback onQuizTap;

  const _TopicMasteryCard({
    required this.topic,
    required this.onReviewNowTap,
    required this.onQuizTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color progressColor = topic.masteryScore >= 80
        ? const Color(0xFF16A34A)
        : (topic.masteryScore >= 50
              ? const Color(0xFFD97706)
              : const Color(0xFFEF4444));

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  topic.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              MasteryBadge(score: topic.masteryScore),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            topic.topicName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (topic.masteryScore.clamp(0, 100)) / 100.0,
              minHeight: 7,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Đã luyện: ${topic.quizCount} lần Quiz',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (topic.isWeak) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Làm Quiz',
                  variant: AppButtonVariant.outline,
                  onPressed: onQuizTap,
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Ôn ngay',
                  icon: Icons.bolt,
                  variant: AppButtonVariant.primary,
                  onPressed: onReviewNowTap,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizAttemptCard extends StatelessWidget {
  final QuizAttemptHistoryItem attempt;

  const _QuizAttemptCard({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final bool isPassed = attempt.score >= 50;
    final Color scoreColor = attempt.score >= 80
        ? const Color(0xFF16A34A)
        : (isPassed ? const Color(0xFFD97706) : const Color(0xFFEF4444));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: scoreColor.withValues(alpha: 0.12),
          child: Text(
            '${attempt.score}%',
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          attempt.subjectName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          'Đúng ${attempt.correctCount}/${attempt.totalQuestions} câu • ${attempt.durationSeconds}s',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ),
    );
  }
}
