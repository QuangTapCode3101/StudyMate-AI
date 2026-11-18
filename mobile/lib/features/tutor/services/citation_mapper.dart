import '../models/tutor_models.dart';

String _normalizeLabel(String label) =>
    label.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Backend chỉ trả về nhãn trang dạng chuỗi (VD: ["Trang 12"]) ở gói tin `done`.
/// Hàm này đối chiếu với các đoạn nguồn đã gửi đi để tạo CitationModel đầy đủ
/// (docId, docTitle, pageLabel) theo đúng định dạng lưu của chat_messages.citations_json.
///
/// Nhãn nào AI "bịa" ra (không nằm trong các đoạn đã gửi) sẽ bị bỏ để chip
/// trích dẫn luôn mở được nội dung gốc thật.
List<CitationModel> mapCitationLabels(
  List<String> labels,
  List<SourceChunkModel> chunks,
) {
  final result = <CitationModel>[];
  final seen = <String>{};

  for (final rawLabel in labels) {
    final key = _normalizeLabel(rawLabel);
    for (final chunk in chunks) {
      if (_normalizeLabel(chunk.pageLabel) != key) {
        continue;
      }
      final uniqueKey = '${chunk.documentId}|$key';
      if (seen.add(uniqueKey)) {
        result.add(
          CitationModel(
            docId: chunk.documentId,
            docTitle: chunk.documentTitle,
            pageLabel: chunk.pageLabel,
          ),
        );
      }
      break;
    }
  }
  return result;
}
