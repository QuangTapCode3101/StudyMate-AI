import 'package:flutter/material.dart';

import '../../models/tutor_models.dart';
import '../../repositories/tutor_repository.dart';
import '../tutor_style.dart';

/// MDL-01: Đối chiếu nguồn trích dẫn.
/// Hiển thị nguyên văn document_chunks.content của trang được trích dẫn
/// và cho phép chuyển qua lại các trang khác của cùng tài liệu.
class CitationViewerSheet extends StatefulWidget {
  const CitationViewerSheet({
    super.key,
    required this.citation,
    required this.repository,
  });

  final CitationModel citation;
  final TutorRepository repository;

  @override
  State<CitationViewerSheet> createState() => _CitationViewerSheetState();
}

class _CitationViewerSheetState extends State<CitationViewerSheet> {
  List<SourceChunkModel> _chunks = [];
  int _index = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final chunks =
          await widget.repository.getChunksOfDocument(widget.citation.docId);
      if (!mounted) {
        return;
      }
      final found =
          chunks.indexWhere((c) => c.pageLabel == widget.citation.pageLabel);
      setState(() {
        _chunks = chunks;
        _index = found < 0 ? 0 : found;
        _isLoading = false;
        _error = chunks.isEmpty
            ? 'Không tìm thấy nội dung gốc của tài liệu này.'
            : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Không đọc được nội dung tài liệu gốc.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: TutorStyle.textMuted),
                    ),
                  ),
                )
              else ...[
                Flexible(child: _buildContent()),
                const SizedBox(height: 12),
                _buildPager(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasChunks = _chunks.isNotEmpty;
    final current = hasChunks ? _chunks[_index] : null;
    final pageText = current == null
        ? widget.citation.pageLabel
        : '${current.pageLabel} (${_index + 1}/${_chunks.length})';

    return Row(
      children: [
        const Icon(Icons.description_outlined, color: TutorStyle.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đối chiếu nguồn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TutorStyle.textDark,
                ),
              ),
              Text(
                '${widget.citation.docTitle} • $pageText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: TutorStyle.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TutorStyle.border),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          _chunks[_index].content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: TutorStyle.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildPager() {
    final canGoBack = _index > 0;
    final canGoNext = _index < _chunks.length - 1;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: canGoBack ? () => setState(() => _index--) : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chevron_left, size: 20),
                Text('Trang trước'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: canGoNext ? () => setState(() => _index++) : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Trang sau'),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
