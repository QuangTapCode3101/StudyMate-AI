import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/models/shared_models.dart';
import '../../../core/network/api_client.dart';
import '../data/document_api_service.dart';
import '../data/library_repository.dart';
import '../services/pdf_text_extractor_service.dart';

enum DocumentSource { pdf, markdown, code }

enum AddDocumentStep { input, preview }

/// ViewModel của SCR-04 (Thêm học liệu): nhập nguồn -> AI phân tích -> xem
/// trước và sửa chủ đề -> lưu vào SQLite.
class AddDocumentViewModel extends ChangeNotifier {
  AddDocumentViewModel({SubjectModel? initialSubject})
      : _fixedSubject = initialSubject,
        subjectId = initialSubject?.id {
    for (final c in [
      titleController,
      markdownController,
      codeController,
      startPageController,
      endPageController,
    ]) {
      c.addListener(notifyListeners);
    }
  }

  final LibraryRepository _repository = LibraryRepository();
  final DocumentApiService _api = const DocumentApiService();
  final DocumentChunkerService _chunker = const DocumentChunkerService();

  final SubjectModel? _fixedSubject;
  bool _disposed = false;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController markdownController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController startPageController = TextEditingController();
  final TextEditingController endPageController = TextEditingController();

  List<SubjectModel> subjects = [];
  int? subjectId;

  DocumentSource source = DocumentSource.pdf;
  AddDocumentStep step = AddDocumentStep.input;

  Uint8List? _pdfBytes;
  String? pdfFileName;
  int pdfTotalPages = 0;

  bool isBusy = false;
  String? errorMessage;

  String summary = '';
  List<DocumentChunk> _chunks = [];
  List<ExtractedTopic> topics = [];
  int? remainingDaily;

  bool get isSubjectLocked => _fixedSubject != null;

  String get subjectName {
    if (_fixedSubject != null) return _fixedSubject.name;
    for (final s in subjects) {
      if (s.id == subjectId) return s.name;
    }
    return '';
  }

  int get startPage => int.tryParse(startPageController.text.trim()) ?? 0;
  int get endPage => int.tryParse(endPageController.text.trim()) ?? 0;

  bool get canAnalyze {
    if (subjectId == null || titleController.text.trim().isEmpty) return false;
    switch (source) {
      case DocumentSource.pdf:
        return _pdfBytes != null;
      case DocumentSource.markdown:
        return markdownController.text.trim().isNotEmpty;
      case DocumentSource.code:
        return codeController.text.trim().isNotEmpty;
    }
  }

  Future<void> loadSubjects() async {
    try {
      subjects = await _repository.getSubjectsWithStats();
    } catch (_) {
      errorMessage = 'Không tải được danh sách môn học.';
    }
    notifyListeners();
  }

  void setSubject(int? id) {
    subjectId = id;
    notifyListeners();
  }

  void setSource(DocumentSource value) {
    source = value;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> pickPdf() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (file == null) return; // người dùng huỷ chọn
      final bytes = await file.readAsBytes();
      final total = _chunker.readTotalPages(bytes);

      _pdfBytes = bytes;
      pdfFileName = file.name;
      pdfTotalPages = total;
      startPageController.text = '1';
      endPageController.text = (total < DocumentChunkerService.maxPagesPerRun
              ? total
              : DocumentChunkerService.maxPagesPerRun)
          .toString();
      if (titleController.text.trim().isEmpty) {
        titleController.text =
            file.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      }
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Không đọc được file PDF này. Hãy thử file khác.';
    }
    notifyListeners();
  }

  String _docType() => switch (source) {
        DocumentSource.pdf => 'PDF',
        DocumentSource.markdown => 'MARKDOWN',
        DocumentSource.code => 'CODE',
      };

  List<DocumentChunk> _buildChunks() {
    switch (source) {
      case DocumentSource.pdf:
        return _chunker.extractPdfChunks(
          _pdfBytes!,
          startPage: startPage,
          endPage: endPage,
        );
      case DocumentSource.markdown:
        return _chunker.chunkText(markdownController.text);
      case DocumentSource.code:
        return _chunker.chunkText(codeController.text);
    }
  }

  /// Cắt chunk -> gọi API -> chuyển sang bước xem trước.
  Future<void> analyze() async {
    if (isBusy || !canAnalyze) return;
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Nhường một khung hình để vòng quay loading kịp hiện trước khi đọc PDF.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final chunks = _buildChunks();
      if (chunks.isEmpty) {
        errorMessage = 'Không tìm thấy nội dung văn bản để phân tích.';
        return;
      }
      final result = await _api.extractTopics(
        subjectName: subjectName,
        documentTitle: titleController.text.trim(),
        chunks: chunks,
      );
      _chunks = chunks;
      summary = result.summary;
      topics = result.topics;
      remainingDaily = result.remainingDaily;
      step = AddDocumentStep.preview;
    } on ScannedPdfException catch (e) {
      errorMessage = e.message;
    } on InvalidPageRangeException catch (e) {
      errorMessage = e.message;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Không thể phân tích tài liệu, hãy thử lại.';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void backToInput() {
    step = AddDocumentStep.input;
    errorMessage = null;
    notifyListeners();
  }

  void renameTopic(int index, String name) {
    topics[index].name = name.trim();
    notifyListeners();
  }

  void removeTopic(int index) {
    topics.removeAt(index);
    notifyListeners();
  }

  /// Chủ đề thêm tay gắn với toàn bộ chunk để AI Tutor vẫn trích dẫn được.
  void addTopic(String name) {
    topics.add(ExtractedTopic(
      name: name.trim(),
      chunkIndices: [for (final c in _chunks) c.chunkIndex],
    ));
    notifyListeners();
  }

  /// Lưu tài liệu, các chunk và chủ đề trong một transaction. Trả về true nếu
  /// thành công.
  Future<bool> save() async {
    if (isBusy) return false;
    final valid = topics.where((t) => t.name.trim().isNotEmpty).toList();
    if (valid.isEmpty) {
      errorMessage = 'Cần có ít nhất 1 chủ đề để lưu.';
      notifyListeners();
      return false;
    }

    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveDocumentAndTopicsTransaction(
        subjectId: subjectId!,
        title: titleController.text.trim(),
        docType: _docType(),
        chunks: _chunks,
        topics: valid,
      );
      return true;
    } catch (_) {
      errorMessage = 'Không thể lưu tài liệu, hãy thử lại.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    titleController.dispose();
    markdownController.dispose();
    codeController.dispose();
    startPageController.dispose();
    endPageController.dispose();
    super.dispose();
  }
}
