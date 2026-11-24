import 'package:flutter/material.dart';

class AuthBrandColors {
  static const Color orange = Color(0xFFF97316);
  static const Color coral = Color(0xFFFB7185);
  static const Color pink = Color(0xFFF43F5E);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color darkInk = Color(0xFF1E293B);
  static const Color borderWarm = Color(0xFFD6B8A8);

  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [orange, coral, pink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Tạo hiệu ứng chuyển trang mượt (Fade + Slide nhẹ) giữa Login và Register
Route<T> buildSmoothAuthRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Khung nền đồng bộ theo bảng màu logo StudyMate AI và tự kéo giãn đầy màn hình
class AuthScaffold extends StatelessWidget {
  final String title;
  final Widget formContent;
  final Widget bottomLink;
  final bool showBackButton;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.formContent,
    required this.bottomLink,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: Stack(
        children: [
          // Các mảng màu mềm theo dải cam - san hô - xanh ngọc của logo
          Positioned(
            top: -70,
            right: -60,
            child: _SoftBlob(
              size: 230,
              colors: [
                AuthBrandColors.orange.withOpacity(0.32),
                AuthBrandColors.coral.withOpacity(0.18),
              ],
            ),
          ),
          Positioned(
            top: 90,
            left: -80,
            child: _SoftBlob(
              size: 190,
              colors: [
                AuthBrandColors.orange.withOpacity(0.16),
                Colors.transparent,
              ],
            ),
          ),
          Positioned(
            bottom: -75,
            left: -55,
            child: _SoftBlob(
              size: 240,
              colors: [
                AuthBrandColors.orange.withOpacity(0.28),
                AuthBrandColors.teal.withOpacity(0.22),
              ],
            ),
          ),
          Positioned(
            bottom: -50,
            right: -60,
            child: _SoftBlob(
              size: 210,
              colors: [
                AuthBrandColors.teal.withOpacity(0.22),
                AuthBrandColors.coral.withOpacity(0.16),
              ],
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showBackButton)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                                color: AuthBrandColors.darkInk,
                                tooltip: 'Quay lại',
                              ),
                            )
                          else
                            const SizedBox(height: 12),

                          // Logo mascot StudyMate AI
                          Center(
                            child: Hero(
                              tag: 'studymate_brand_logo',
                              child: Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AuthBrandColors.orange.withOpacity(0.22),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    'assets/images/logo.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: const BoxDecoration(
                                        gradient: AuthBrandColors.primaryButtonGradient,
                                      ),
                                      child: const Icon(
                                        Icons.smart_toy_rounded,
                                        color: Colors.white,
                                        size: 52,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AuthBrandColors.primaryButtonGradient.createShader(bounds),
                            child: const Text(
                              'StudyMate AI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: AuthBrandColors.darkInk,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Nội dung Form
                          formContent,

                          const Spacer(),
                          const SizedBox(height: 20),

                          // Liên kết chuyển đổi ở đáy màn hình
                          Center(child: bottomLink),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _SoftBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

/// Decoration chuẩn chỉ dùng placeholder (hintText), không label ngoài
InputDecoration buildAuthInputDecoration({
  required String hintText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: Colors.grey.shade500,
      fontSize: 15,
    ),
    filled: true,
    fillColor: Colors.white.withOpacity(0.95),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600, size: 21),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AuthBrandColors.borderWarm, width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AuthBrandColors.borderWarm, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AuthBrandColors.orange, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AuthBrandColors.pink, width: 1.4),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AuthBrandColors.pink, width: 1.8),
    ),
  );
}

/// Nút hành động chính dạng pill gradient + hiệu ứng loading mượt
class AuthGradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthGradientButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.75 : 1.0,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AuthBrandColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AuthBrandColors.orange.withOpacity(0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        label,
                        key: ValueKey(label),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Khung hiển thị lỗi từ server xuất hiện/biến mất mượt mà
class AuthErrorBanner extends StatelessWidget {
  final String? message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: (message == null || message!.isEmpty)
          ? const SizedBox.shrink(key: ValueKey('empty_error'))
          : Container(
              key: ValueKey(message),
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AuthBrandColors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AuthBrandColors.pink.withOpacity(0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AuthBrandColors.pink,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message!,
                      style: const TextStyle(
                        color: AuthBrandColors.pink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}