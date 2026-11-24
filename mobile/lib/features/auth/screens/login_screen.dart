import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/auth_validator.dart';
import '../widgets/auth_ui_components.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.read<AuthProvider>().clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    await context.read<AuthProvider>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _openRegister() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context).push(
      buildSmoothAuthRoute(const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AuthScaffold(
          title: 'Chào mừng bạn quay lại!',
          formContent: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  enabled: !auth.isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: buildAuthInputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  validator: AuthValidator.validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  enabled: !auth.isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => auth.isLoading ? null : _submit(),
                  decoration: buildAuthInputDecoration(
                    hintText: 'Mật khẩu',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  validator: AuthValidator.validateLoginPassword,
                ),
                AuthErrorBanner(message: auth.errorMessage),
                const SizedBox(height: 24),
                AuthGradientButton(
                  label: 'Đăng nhập',
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
          bottomLink: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Chưa có tài khoản? ',
                style: TextStyle(color: AuthBrandColors.darkInk, fontSize: 14.5),
              ),
              GestureDetector(
                onTap: auth.isLoading ? null : _openRegister,
                child: const Text(
                  'Đăng ký',
                  style: TextStyle(
                    color: AuthBrandColors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}