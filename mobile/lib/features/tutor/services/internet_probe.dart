import 'dart:async';
import 'dart:io';

/// Kiểm tra máy có ra được Internet hay không (tra DNS thử một tên miền phổ biến).
/// Chỉ dùng để phân biệt "máy mất mạng" với "Backend không chạy" khi Backend không phản hồi.
Future<bool> hasInternetAccess() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  } on TimeoutException {
    return false;
  }
}
