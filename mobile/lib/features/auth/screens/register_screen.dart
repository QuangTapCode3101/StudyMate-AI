import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/auth_validator.dart';
import '../widgets/auth_ui_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.read<AuthProvider>().clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthProvider>().register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );

    if (ok && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _backToLogin() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AuthScaffold(
          title: 'Đăng ký tài khoản mới!',
          showBackButton: true,
          formContent: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _displayNameController,
                  enabled: !auth.isLoading,
                  textInputAction: TextInputAction.next,
                  decoration: buildAuthInputDecoration(
                    hintText: 'Nhập tên của bạn',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  validator: AuthValidator.validateDisplayName,
                ),
                const SizedBox(height: 15),
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
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  enabled: !auth.isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
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
                  validator: AuthValidator.validateRegisterPassword,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !auth.isLoading,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => auth.isLoading ? null : _submit(),
                  decoration: buildAuthInputDecoration(
                    hintText: 'Nhập lại mật khẩu',
                    prefixIcon: Icons.lock_reset_rounded,
                    suffixIcon: IconButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  validator: (value) => AuthValidator.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                AuthErrorBanner(message: auth.errorMessage),
                const SizedBox(height: 24),
                AuthGradientButton(
                  label: 'Đăng ký',
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
                'Đã có tài khoản? ',
                style: TextStyle(
                  color: AuthBrandColors.darkInk,
                  fontSize: 14.5,
                ),
              ),
              GestureDetector(
                onTap: auth.isLoading ? null : _backToLogin,
                child: const Text(
                  'Đăng nhập',
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
