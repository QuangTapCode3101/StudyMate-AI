import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/shared_models.dart';
import '../../../core/widgets/app_button.dart';
import '../library_style.dart';
import '../services/pdf_text_extractor_service.dart';
import '../viewmodels/add_document_viewmodel.dart';

/// SCR-04: Thêm học liệu. Trả về `true` qua Navigator.pop khi đã lưu thành công
/// để màn hình trước làm mới dữ liệu.
///
/// Nếu truyền [subject] thì môn học được cố định (mở từ SCR-03); nếu để null
/// thì người dùng tự chọn môn (mở từ SCR-02).
class AddDocumentScreen extends StatelessWidget {
  final SubjectModel? subject;

  const AddDocumentScreen({super.key, this.subject});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          AddDocumentViewModel(initialSubject: subject)..loadSubjects(),
      child: const _AddDocumentView(),
    );
  }
}

class _AddDocumentView extends StatelessWidget {
  const _AddDocumentView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddDocumentViewModel>();
    final inPreview = vm.step == AddDocumentStep.preview;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: LibraryStyle.primary),
        title: const Text(
          'Thêm học liệu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: LibraryStyle.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (inPreview) ..._previewSection(context, vm) else ..._inputSection(context, vm),
            if (vm.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                vm.errorMessage!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Bước 1

  List<Widget> _inputSection(BuildContext context, AddDocumentViewModel vm) {
    return [
      const _FieldLabel('Môn học'),
      _subjectField(vm),
      const SizedBox(height: 16),
      const _FieldLabel('Loại học liệu'),
      Wrap(
        spacing: 8,
        children: [
          _sourceChip(vm, DocumentSource.pdf, 'File PDF'),
          _sourceChip(vm, DocumentSource.markdown, 'Ghi chú Markdown'),
          _sourceChip(vm, DocumentSource.code, 'Source Code'),
        ],
      ),
      const SizedBox(height: 16),
      const _FieldLabel('Tên tài liệu'),
      TextField(
        controller: vm.titleController,
        enabled: !vm.isBusy,
        decoration: _inputDecoration('VD: Slide_StateManagement'),
      ),
      const SizedBox(height: 16),
      ..._sourceBody(vm),
      const SizedBox(height: 20),
      AppButton(
        label: '✨ Phân tích bằng AI',
        onPressed: vm.canAnalyze && !vm.isBusy ? vm.analyze : null,
        isLoading: vm.isBusy,
        isFullWidth: true,
      ),
    ];
  }

  Widget _subjectField(AddDocumentViewModel vm) {
    if (vm.isSubjectLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: LibraryStyle.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.folder, color: LibraryStyle.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                vm.subjectName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: LibraryStyle.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (vm.subjects.isEmpty) {
      return const Text(
        'Chưa có môn học nào. Hãy quay lại Thư viện và thêm môn học trước.',
        style: TextStyle(color: LibraryStyle.textSecondary, fontSize: 13),
      );
    }
    return DropdownButtonFormField<int>(
      initialValue: vm.subjectId,
      isExpanded: true,
      decoration: _inputDecoration('Chọn môn học'),
      items: [
        for (final s in vm.subjects)
          DropdownMenuItem<int>(value: s.id, child: Text(s.name)),
      ],
      onChanged: vm.isBusy ? null : vm.setSubject,
    );
  }

  Widget _sourceChip(AddDocumentViewModel vm, DocumentSource value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: vm.source == value,
      onSelected: vm.isBusy ? null : (_) => vm.setSource(value),
    );
  }

  List<Widget> _sourceBody(AddDocumentViewModel vm) {
    switch (vm.source) {
      case DocumentSource.pdf:
        return [
          OutlinedButton.icon(
            onPressed: vm.isBusy ? null : vm.pickPdf,
            icon: const Icon(Icons.upload_file),
            label: Text(vm.pdfFileName == null ? 'Chọn file PDF' : 'Đổi file PDF'),
          ),
          if (vm.pdfFileName != null) ...[
            const SizedBox(height: 12),
            Text(
              '${vm.pdfFileName} • Tổng: ${vm.pdfTotalPages} trang',
              style: const TextStyle(color: LibraryStyle.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _pageField('Từ trang', vm.startPageController, vm.isBusy)),
                const SizedBox(width: 12),
                Expanded(child: _pageField('Đến trang', vm.endPageController, vm.isBusy)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Mỗi lần phân tích tối đa ${DocumentChunkerService.maxPagesPerRun} trang.',
              style: TextStyle(color: LibraryStyle.textSecondary, fontSize: 12),
            ),
          ],
        ];
      case DocumentSource.markdown:
        return [
          const _FieldLabel('Nội dung ghi chú'),
          TextField(
            controller: vm.markdownController,
            enabled: !vm.isBusy,
            minLines: 6,
            maxLines: 12,
            decoration: _inputDecoration('Dán ghi chú Markdown của bạn vào đây...'),
          ),
        ];
      case DocumentSource.code:
        return [
          const _FieldLabel('Source code'),
          TextField(
            controller: vm.codeController,
            enabled: !vm.isBusy,
            minLines: 6,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: _inputDecoration('Dán đoạn code của bạn vào đây...'),
          ),
        ];
    }
  }

  Widget _pageField(String label, TextEditingController controller, bool busy) {
    return TextField(
      controller: controller,
      enabled: !busy,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _inputDecoration(label),
    );
  }

  // ---------------------------------------------------------------- Bước 2

  List<Widget> _previewSection(BuildContext context, AddDocumentViewModel vm) {
    return [
      const Text(
        'Kết quả phân tích',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: LibraryStyle.textPrimary,
        ),
      ),
      if (vm.summary.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LibraryStyle.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            vm.summary,
            style: const TextStyle(color: LibraryStyle.textPrimary, height: 1.4),
          ),
        ),
      ],
      if (vm.remainingDaily != null) ...[
        const SizedBox(height: 8),
        Text(
          'Còn ${vm.remainingDaily} lượt AI hôm nay',
          style: const TextStyle(color: LibraryStyle.textSecondary, fontSize: 12),
        ),
      ],
      const SizedBox(height: 16),
      Text(
        'Chủ đề kiến thức (${vm.topics.length})',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: LibraryStyle.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < vm.topics.length; i++) _topicCard(context, vm, i),
      OutlinedButton.icon(
        onPressed: vm.isBusy
            ? null
            : () async {
                final name = await _askTopicName(context, title: 'Thêm chủ đề');
                if (name != null) vm.addTopic(name);
              },
        icon: const Icon(Icons.add),
        label: const Text('Thêm chủ đề'),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Quay lại',
              variant: AppButtonVariant.outline,
              onPressed: vm.isBusy ? null : vm.backToInput,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'Lưu tài liệu',
              isLoading: vm.isBusy,
              onPressed: vm.isBusy
                  ? null
                  : () async {
                      final ok = await vm.save();
                      if (ok && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
            ),
          ),
        ],
      ),
    ];
  }

  Widget _topicCard(BuildContext context, AddDocumentViewModel vm, int index) {
    final topic = vm.topics[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LibraryStyle.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: LibraryStyle.textPrimary,
                    ),
                  ),
                  if (topic.keywords.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final k in topic.keywords) _keywordChip(k),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sửa tên',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: vm.isBusy
                ? null
                : () async {
                    final name = await _askTopicName(
                      context,
                      title: 'Sửa tên chủ đề',
                      initial: topic.name,
                    );
                    if (name != null) vm.renameTopic(index, name);
                  },
          ),
          IconButton(
            tooltip: 'Xóa chủ đề',
            icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
            onPressed: vm.isBusy ? null : () => vm.removeTopic(index),
          ),
        ],
      ),
    );
  }

  Widget _keywordChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LibraryStyle.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: LibraryStyle.primary,
        ),
      ),
    );
  }

  Future<String?> _askTopicName(
    BuildContext context, {
    required String title,
    String initial = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _TopicNameDialog(title: title, initial: initial),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LibraryStyle.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LibraryStyle.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LibraryStyle.primary, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: LibraryStyle.textSecondary,
        ),
      ),
    );
  }
}

class _TopicNameDialog extends StatefulWidget {
  final String title;
  final String initial;

  const _TopicNameDialog({required this.title, required this.initial});

  @override
  State<_TopicNameDialog> createState() => _TopicNameDialogState();
}

class _TopicNameDialogState extends State<_TopicNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Tên chủ đề'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Lưu')),
      ],
    );
  }
}
