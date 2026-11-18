import 'package:flutter/material.dart';

import '../../services/connection_status.dart';
import '../tutor_style.dart';

/// Thanh cảnh báo màu cam khi mất mạng hoặc Backend không chạy.
/// Khi hiện thanh này, tính năng AI bị khóa nhưng vẫn xem được lịch sử chat.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.status,
    required this.isChecking,
    required this.onRetry,
  });

  final TutorConnectionStatus status;
  final bool isChecking;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final icon = status == TutorConnectionStatus.noInternet
        ? Icons.wifi_off
        : Icons.cloud_off;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: const BoxDecoration(
        color: TutorStyle.warningLight,
        border: Border(bottom: BorderSide(color: TutorStyle.warningBorder)),
      ),
      child: Row(
        children: [
          Icon(icon, color: TutorStyle.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.warningTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: TutorStyle.warningText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.warningDetail,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: TutorStyle.warningText,
                  ),
                ),
              ],
            ),
          ),
          if (isChecking)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: onRetry,
              child: const Text('Kiểm tra lại'),
            ),
        ],
      ),
    );
  }
}
