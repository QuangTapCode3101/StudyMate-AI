import 'package:flutter/material.dart';

enum AppButtonVariant {
  primary, // Nền xanh chữ trắng (VD: Nút "Học AI")
  outline, // Nền trong suốt viền xám (VD: Nút "Làm Quiz")
  white,   // Nền trắng chữ xanh (VD: Nút "Tiếp tục với AI Tutor" trên banner xanh)
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _textDarkColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final Color bgColor = switch (variant) {
      AppButtonVariant.primary => _primaryColor,
      AppButtonVariant.outline => Colors.transparent,
      AppButtonVariant.white => Colors.white,
    };

    final Color fgColor = switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.outline => _textDarkColor,
      AppButtonVariant.white => _primaryColor,
    };

    final BorderSide borderSide = variant == AppButtonVariant.outline
        ? const BorderSide(color: _borderColor, width: 1.2)
        : BorderSide.none;

    final Widget content = isLoading
        ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fgColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: borderSide,
          ),
        ),
        child: content,
      ),
    );
  }
}