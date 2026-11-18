import 'package:flutter_test/flutter_test.dart';
import 'package:studymate_ai/features/tutor/models/tutor_models.dart';

void main() {
  group('ChatSessionModel.copyWith', () {
    test('đổi tên phiên nhưng giữ nguyên các trường còn lại', () {
      const original = ChatSessionModel(
        id: 7,
        subjectId: 1,
        topicId: 2,
        title: 'Tên cũ',
        createdAt: '2026-11-18T10:00:00.000',
        messageCount: 4,
      );

      final renamed = original.copyWith(title: 'Tên mới');

      expect(renamed.title, 'Tên mới');
      expect(renamed.id, 7);
      expect(renamed.subjectId, 1);
      expect(renamed.topicId, 2);
      expect(renamed.createdAt, '2026-11-18T10:00:00.000');
      expect(renamed.messageCount, 4);
    });

    test('không truyền title thì giữ nguyên tên', () {
      const original = ChatSessionModel(
        id: 1,
        subjectId: 1,
        topicId: 1,
        title: 'Giữ nguyên',
        createdAt: '2026-11-18T10:00:00.000',
      );

      expect(original.copyWith().title, 'Giữ nguyên');
    });
  });
}
