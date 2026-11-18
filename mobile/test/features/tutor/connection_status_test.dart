import 'package:flutter_test/flutter_test.dart';
import 'package:studymate_ai/core/network/api_client.dart';
import 'package:studymate_ai/features/tutor/services/connection_status.dart';

void main() {
  group('TutorConnectionStatus', () {
    test('chỉ khóa tính năng AI khi đã chắc chắn mất kết nối', () {
      expect(TutorConnectionStatus.checking.isAiAvailable, isTrue);
      expect(TutorConnectionStatus.online.isAiAvailable, isTrue);
      expect(TutorConnectionStatus.noInternet.isAiAvailable, isFalse);
      expect(TutorConnectionStatus.serverUnreachable.isAiAvailable, isFalse);
    });

    test('hai kiểu mất kết nối có thông báo khác nhau', () {
      final noInternet = TutorConnectionStatus.noInternet.warningTitle;
      final serverDown = TutorConnectionStatus.serverUnreachable.warningTitle;

      expect(noInternet, isNotEmpty);
      expect(serverDown, isNotEmpty);
      expect(noInternet, isNot(serverDown));
      expect(TutorConnectionStatus.online.warningTitle, isEmpty);
    });
  });

  group('isConnectionFailure', () {
    test('mất mạng hoặc quá thời gian chờ là lỗi kết nối', () {
      expect(
        isConnectionFailure(
          ApiException(code: 'NETWORK_ERROR', message: 'Không có mạng'),
        ),
        isTrue,
      );
      expect(
        isConnectionFailure(ApiException(code: 'TIMEOUT', message: 'Quá giờ')),
        isTrue,
      );
    });

    test('lỗi bất ngờ không phải ApiException cũng coi là lỗi kết nối', () {
      expect(isConnectionFailure(Exception('socket closed')), isTrue);
    });

    test('Backend trả mã HTTP nghĩa là Backend vẫn đang chạy', () {
      expect(
        isConnectionFailure(
          ApiException(
            code: 'DAILY_QUOTA_EXCEEDED',
            message: 'Hết lượt',
            statusCode: 429,
          ),
        ),
        isFalse,
      );
      expect(
        isConnectionFailure(
          ApiException(code: 'HTTP_500', message: 'Lỗi', statusCode: 500),
        ),
        isFalse,
      );
    });

    test('lỗi AI giữa chừng không phải lỗi kết nối', () {
      expect(
        isConnectionFailure(
          ApiException(code: 'AI_STREAM_ERROR', message: 'AI lỗi'),
        ),
        isFalse,
      );
    });
  });
}
