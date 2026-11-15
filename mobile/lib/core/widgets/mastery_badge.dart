import 'package:flutter/material.dart';

class MasteryBadge extends StatelessWidget {
  final int score;

  const MasteryBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    if (score == 0) {
      bgColor = const Color(0xFFF1F5F9); // Xám nhạt
      textColor = const Color(0xFF64748B); // Xám đậm
      label = 'Chưa học';
    } else if (score < 50) {
      bgColor = const Color(0xFFFEE2E2); // Đỏ nhạt
      textColor = const Color(0xFFEF4444); // Đỏ đậm
      label = '$score% Cần ôn lại';
    } else if (score < 80) {
      bgColor = const Color(0xFFFEF3C7); // Vàng nhạt
      textColor = const Color(0xFFD97706); // Vàng đậm
      label = '$score% Khá';
    } else {
      bgColor = const Color(0xFFDCFCE7); // Xanh nhạt
      textColor = const Color(0xFF16A34A); // Xanh đậm
      label = '$score% Nắm vững';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}