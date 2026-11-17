import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/shared_models.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../library_style.dart';
import '../viewmodels/library_viewmodel.dart';
import '../widgets/add_subject_dialog.dart';
import '../widgets/subject_card.dart';
import 'subject_detail_screen.dart';

/// SCR-02: Thư viện môn học. M1 chỉ cần đặt `LibraryScreen()` vào tab thứ 2.
/// Màn hình tự tạo LibraryViewModel nên không cần sửa main.dart.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryViewModel()..loadSubjects(),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onAddSubject() async {
    final viewModel = context.read<LibraryViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final input = await showAddSubjectDialog(context);
    if (input == null) return;

    final ok = await viewModel.addSubject(
      name: input.name,
      programmingLanguage: input.programmingLanguage,
    );
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? 'Đã thêm môn "${input.name}"'
          : 'Không thể thêm môn học, hãy thử lại'),
    ));
  }

  /// Nút "Tải tài liệu lên" mở SCR-04 (TASK-304, làm ở giai đoạn tích hợp).
  void _onUploadDocument() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Màn hình thêm học liệu (SCR-04) sẽ có ở TASK-304'),
    ));
  }

  Future<void> _onDeleteSubject(SubjectModel subject) async {
    final viewModel = context.read<LibraryViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Xóa môn học?'),
        content: Text(
          'Môn "${subject.name}" cùng toàn bộ tài liệu, chủ đề, lịch sử chat, '
          'câu hỏi và flashcard liên quan sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await viewModel.deleteSubject(subject.id!);
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? 'Đã xóa môn "${subject.name}"'
          : 'Không thể xóa môn học, hãy thử lại'),
    ));
  }

  Future<void> _openDetail(SubjectModel subject) async {
    final viewModel = context.read<LibraryViewModel>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectDetailScreen(subject: subject),
      ),
    );
    // Quay lại thì làm mới số liệu (tiến độ có thể đã đổi sau khi luyện quiz).
    if (mounted) await viewModel.loadSubjects(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddSubject,
        backgroundColor: LibraryStyle.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm môn học'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Thư viện môn học',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: LibraryStyle.textPrimary,
                ),
              ),
            ),
            _buildSearchRow(viewModel),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _onUploadDocument,
                  icon: const Icon(Icons.upload_outlined, size: 20),
                  label: const Text('Tải tài liệu lên'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFDBEAFE),
                    foregroundColor: LibraryStyle.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow(LibraryViewModel viewModel) {
    const outline = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: LibraryStyle.primary, width: 1.5),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: viewModel.setQuery,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm môn học, chủ đề...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: viewModel.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.setQuery('');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: outline,
                enabledBorder: outline,
                focusedBorder: outline,
              ),
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<LibrarySort>(
            tooltip: 'Sắp xếp',
            initialValue: viewModel.sort,
            onSelected: viewModel.setSort,
            itemBuilder: (_) => [
              for (final option in LibrarySort.values)
                PopupMenuItem(value: option, child: Text(option.label)),
            ],
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: LibraryStyle.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LibraryViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return _centered(
        AppEmptyState(
          icon: Icons.error_outline,
          title: 'Có lỗi xảy ra',
          subtitle: viewModel.errorMessage,
          actionLabel: 'Thử lại',
          actionIcon: Icons.refresh,
          onActionPressed: viewModel.loadSubjects,
        ),
      );
    }

    if (!viewModel.hasAnySubject) {
      return _centered(
        AppEmptyState(
          icon: Icons.folder_open_outlined,
          title: 'Chưa có môn học nào',
          subtitle: 'Tạo môn học đầu tiên để thêm tài liệu và học với AI.',
          actionLabel: 'Thêm môn học',
          actionIcon: Icons.add,
          onActionPressed: _onAddSubject,
        ),
      );
    }

    final subjects = viewModel.subjects;
    if (subjects.isEmpty) {
      return _centered(
        AppEmptyState(
          icon: Icons.search_off,
          title: 'Không tìm thấy môn học',
          subtitle: 'Thử từ khóa khác với "${viewModel.query.trim()}".',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadSubjects(showLoading: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        // Chừa chỗ dưới cùng để nút nổi không che thẻ cuối.
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
        itemCount: subjects.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return SubjectCard(
            subject: subject,
            onTap: () => _openDetail(subject),
            onLongPress: () => _onDeleteSubject(subject),
          );
        },
      ),
    );
  }

  Widget _centered(Widget child) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );
}
