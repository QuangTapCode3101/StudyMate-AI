import '../../../core/network/api_client.dart';

/// Tình trạng kết nối của tính năng AI Tutor.
enum TutorConnectionStatus {
  /// Chưa kiểm tra xong (vừa mở màn hình). Vẫn cho dùng bình thường.
  checking,

  /// Backend phản hồi bình thường.
  online,

  /// Máy không có mạng.
  noInternet,

  /// Có mạng nhưng Backend không phản hồi (Backend tắt, sai địa chỉ, quá thời gian chờ).
  serverUnreachable;

  /// Chỉ khóa tính năng AI khi đã chắc chắn mất kết nối.
  bool get isAiAvailable =>
      this == TutorConnectionStatus.checking ||
      this == TutorConnectionStatus.online;

  String get warningTitle {
    switch (this) {
      case TutorConnectionStatus.noInternet:
        return 'Máy đang không có mạng';
      case TutorConnectionStatus.serverUnreachable:
        return 'Không kết nối được máy chủ';
      case TutorConnectionStatus.checking:
      case TutorConnectionStatus.online:
        return '';
    }
  }

  String get warningDetail {
    switch (this) {
      case TutorConnectionStatus.noInternet:
        return 'Bạn vẫn xem được lịch sử trò chuyện, nhưng chưa thể dùng tính năng AI.';
      case TutorConnectionStatus.serverUnreachable:
        return 'Tính năng AI tạm thời không dùng được. Hãy kiểm tra Backend đã chạy chưa.';
      case TutorConnectionStatus.checking:
      case TutorConnectionStatus.online:
        return '';
    }
  }
}

/// `true` nếu lỗi cho thấy không nói chuyện được với Backend (mất mạng, hết thời gian chờ,
/// Backend tắt). Lỗi HTTP có mã trạng thái (400, 429, 500...) nghĩa là Backend vẫn đang chạy.
bool isConnectionFailure(Object error) {
  if (error is ApiException) {
    return error.statusCode == null &&
        (error.code == 'NETWORK_ERROR' || error.code == 'TIMEOUT');
  }
  return true;
}
