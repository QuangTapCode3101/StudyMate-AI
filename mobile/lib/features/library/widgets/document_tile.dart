import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../library_style.dart';

/// Ô tài liệu nguồn trong SCR-03 (xếp lưới cuộn ngang): icon theo loại + tên + số trang/đoạn.
class DocumentTile extends StatelessWidget {
  final DocumentModel document;

  const DocumentTile({super.key, required this.document});

  (IconData, Color) get _iconStyle => switch (document.docType) {
        'PDF' => (Icons.picture_as_pdf, const Color(0xFFEF4444)),
        'MARKDOWN' => (Icons.description, const Color(0xFF475569)),
        'CODE' => (Icons.code, const Color(0xFF334155)),
        _ => (Icons.insert_drive_file, const Color(0xFF475569)),
      };

  String get _subtitle {
    final unit = document.docType == 'PDF' ? 'trang' : 'đoạn';
    return '${document.totalChunks} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconStyle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LibraryStyle.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LibraryStyle.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: LibraryStyle.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
