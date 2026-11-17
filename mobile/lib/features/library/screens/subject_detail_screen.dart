import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/shared_models.dart';
import '../../../core/providers/active_context_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../library_style.dart';
import '../models/document_model.dart';
import '../viewmodels/subject_detail_viewmodel.dart';
import '../widgets/document_tile.dart';
import '../widgets/topic_action_card.dart';

/// SCR-03: Chi tiết môn học gồm "Tài liệu nguồn" và "Cây chủ đề kiến thức".
class SubjectDetailScreen extends StatelessWidget {
  final SubjectModel subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SubjectDetailViewModel(subjectId: subject.id!)..load(),
      child: _SubjectDetailView(subject: subject),
    );
  }
}

class _SubjectDetailView extends StatelessWidget {
  final SubjectModel subject;

  const _SubjectDetailView({required this.subject});

  /// SCR-03 được push lên trên khung 5 tab, nên sau khi báo Provider chuyển tab
  /// phải đóng màn hình này (popUntil về route gốc) thì mới thấy tab mới.
  void _studyWithAi(BuildContext context, TopicModel topic) {
    context.read<ActiveStudyContextProvider>().openAiTutorWithTopic(
          subjectId: topic.subjectId,
          topicId: topic.id!,
        );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _practiceQuiz(BuildContext context, TopicModel topic) {
    context.read<ActiveStudyContextProvider>().openQuizSetupWithTopic(
          subjectId: topic.subjectId,
          topicId: topic.id!,
        );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Nút "+ Thêm học liệu" mở SCR-04 (TASK-304, làm ở giai đoạn tích hợp).
  void _onAddDocument(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Màn hình thêm học liệu (SCR-04) sẽ có ở TASK-304'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubjectDetailViewModel>();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: LibraryStyle.primary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _onAddDocument(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm học liệu'),
              style: FilledButton.styleFrom(
                backgroundColor: LibraryStyle.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, SubjectDetailViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Có lỗi xảy ra',
            subtitle: viewModel.errorMessage,
            actionLabel: 'Thử lại',
            actionIcon: Icons.refresh,
            onActionPressed: viewModel.load,
          ),
        ),
      );
    }

    final topics = viewModel.topics;

    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            subject.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: LibraryStyle.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Tài liệu nguồn'),
          const SizedBox(height: 10),
          _DocumentGrid(documents: viewModel.documents),
          const SizedBox(height: 22),
          const _SectionTitle('Cây chủ đề kiến thức'),
          const SizedBox(height: 10),
          if (topics.isEmpty)
            const AppEmptyState(
              icon: Icons.account_tree_outlined,
              title: 'Chưa có chủ đề nào',
              subtitle: 'AI sẽ bóc tách chủ đề sau khi bạn thêm tài liệu.',
            )
          else
            for (final topic in topics) ...[
              TopicActionCard(
                topic: topic,
                expanded: viewModel.isExpanded(topic.id!),
                onToggle: () => viewModel.toggleTopic(topic.id!),
                onStudyWithAi: () => _studyWithAi(context, topic),
                onPracticeQuiz: () => _practiceQuiz(context, topic),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: LibraryStyle.textSecondary,
      ),
    );
  }
}

/// Tài liệu xếp lưới 2 hàng, cuộn ngang như mockup SCR-03.
class _DocumentGrid extends StatelessWidget {
  final List<DocumentModel> documents;

  const _DocumentGrid({required this.documents});

  static const double _tileHeight = 58;
  static const double _spacing = 10;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const AppEmptyState(
        icon: Icons.description_outlined,
        title: 'Chưa có tài liệu nào',
        subtitle: 'Tài liệu bạn thêm vào môn học này sẽ hiện ở đây.',
      );
    }

    final rows = documents.length > 1 ? 2 : 1;
    return SizedBox(
      height: rows * _tileHeight + (rows - 1) * _spacing,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: documents.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: rows,
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          mainAxisExtent: 230,
        ),
        itemBuilder: (_, index) => DocumentTile(document: documents[index]),
      ),
    );
  }
}
