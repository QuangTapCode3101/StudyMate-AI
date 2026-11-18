import 'package:flutter/material.dart';

/// Bảng màu dùng riêng cho module Library (cùng tông với các widget trong lib/core/).
class LibraryStyle {
  LibraryStyle._();

  static const Color primary = Color(0xFF2563EB);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color codeBg = Color(0xFF0F172A);

  /// Màu thanh tiến độ ở SCR-02 theo mockup: đỏ (<50), xanh dương (50-79), xanh lá (>=80).
  static Color progressColor(num score) {
    if (score <= 0) return const Color(0xFF94A3B8); // Chưa học
    if (score < 50) return const Color(0xFFEF4444);
    if (score < 80) return primary;
    return const Color(0xFF16A34A);
  }
}
