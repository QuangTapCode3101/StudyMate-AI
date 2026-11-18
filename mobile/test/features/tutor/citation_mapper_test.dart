import 'package:flutter_test/flutter_test.dart';
import 'package:studymate_ai/features/tutor/models/tutor_models.dart';
import 'package:studymate_ai/features/tutor/services/citation_mapper.dart';

void main() {
  const chunks = [
    SourceChunkModel(
      documentId: 1,
      documentTitle: 'Slide_StateManagement.pdf',
      chunkIndex: 1,
      pageLabel: 'Trang 12',
      content: 'Nội dung trang 12',
    ),
    SourceChunkModel(
      documentId: 1,
      documentTitle: 'Slide_StateManagement.pdf',
      chunkIndex: 2,
      pageLabel: 'Trang 13',
      content: 'Nội dung trang 13',
    ),
  ];

  group('mapCitationLabels', () {
    test('ghép nhãn trang với tài liệu gốc', () {
      final result = mapCitationLabels(['Trang 12'], chunks);

      expect(result.length, 1);
      expect(result.first.docId, 1);
      expect(result.first.docTitle, 'Slide_StateManagement.pdf');
      expect(result.first.pageLabel, 'Trang 12');
    });

    test('không phân biệt hoa thường và khoảng trắng thừa', () {
      final result = mapCitationLabels(['  trang   13 '], chunks);

      expect(result.length, 1);
      expect(result.first.pageLabel, 'Trang 13');
    });

    test('bỏ nhãn AI bịa ra và loại trùng lặp', () {
      final result = mapCitationLabels(
        ['Trang 99', 'Trang 12', 'Trang 12'],
        chunks,
      );

      expect(result.length, 1);
      expect(result.first.pageLabel, 'Trang 12');
    });

    test('danh sách rỗng trả về rỗng', () {
      expect(mapCitationLabels(const [], chunks), isEmpty);
    });
  });

  group('CitationModel JSON', () {
    test('mã hóa rồi giải mã giữ nguyên dữ liệu', () {
      const original = [
        CitationModel(docId: 1, docTitle: 'Slide.pdf', pageLabel: 'Trang 12'),
      ];

      final raw = CitationModel.encodeList(original);
      final decoded = CitationModel.decodeList(raw);

      expect(decoded.length, 1);
      expect(decoded.first.docId, 1);
      expect(decoded.first.docTitle, 'Slide.pdf');
      expect(decoded.first.pageLabel, 'Trang 12');
    });

    test('danh sách rỗng lưu NULL và dữ liệu hỏng không làm crash', () {
      expect(CitationModel.encodeList(const []), isNull);
      expect(CitationModel.decodeList(null), isEmpty);
      expect(CitationModel.decodeList('không phải json'), isEmpty);
    });
  });
}
