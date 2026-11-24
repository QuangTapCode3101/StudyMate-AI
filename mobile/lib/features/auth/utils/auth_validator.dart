class AuthValidator {
  AuthValidator._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _redeemCodeRegex = RegExp(r'^[A-Z0-9_-]{4,50}$');

  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Vui lòng nhập email.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Định dạng email không hợp lệ.';
    }
    return null;
  }

  /// Dùng cho màn hình Đăng nhập (chỉ check rỗng)
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    return null;
  }

  /// Dùng cho màn hình Đăng ký (khớp rule Backend: tối thiểu 6 ký tự)
  static String? validateRegisterPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    if (value.contains(' ')) {
      return 'Mật khẩu không được chứa khoảng trắng.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu.';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }

  static String? validateDisplayName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Vui lòng nhập tên hiển thị.';
    }
    if (trimmed.length < 2) {
      return 'Tên hiển thị phải có ít nhất 2 ký tự.';
    }
    if (trimmed.length > 100) {
      return 'Tên hiển thị tối đa 100 ký tự.';
    }
    return null;
  }

  /// Dùng cho ô nhập mã Redeem Code trong MDL-03
  static String? validateRedeemCode(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) {
      return 'Vui lòng nhập mã kích hoạt.';
    }
    if (!_redeemCodeRegex.hasMatch(normalized)) {
      return 'Mã chỉ gồm chữ, số, dấu gạch ngang/dưới (4–50 ký tự).';
    }
    return null;
  }
}