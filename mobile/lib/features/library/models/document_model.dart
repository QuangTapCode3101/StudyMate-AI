/// Tài liệu nguồn của một môn học (bảng `documents`).
/// Shared_models.dart (M1) chưa có lớp này nên M2 tự định nghĩa trong feature của mình.
class DocumentModel {
  final int? id;
  final int subjectId;
  final String title;
  final String docType; // 'PDF' | 'MARKDOWN' | 'CODE'
  final int totalChunks;
  final String createdAt;

  const DocumentModel({
    this.id,
    required this.subjectId,
    required this.title,
    required this.docType,
    required this.totalChunks,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'subject_id': subjectId,
        'title': title,
        'doc_type': docType,
        'total_chunks': totalChunks,
        'created_at': createdAt,
      };

  factory DocumentModel.fromMap(Map<String, dynamic> map) => DocumentModel(
        id: map['id'] as int?,
        subjectId: map['subject_id'] as int,
        title: map['title'] as String,
        docType: map['doc_type'] as String,
        totalChunks: (map['total_chunks'] as num?)?.toInt() ?? 0,
        createdAt: map['created_at'] as String,
      );
}
