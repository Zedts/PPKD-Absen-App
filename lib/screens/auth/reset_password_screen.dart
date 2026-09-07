import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../widgets/auth/auth_background.dart';
import '../../widgets/common/back_button_circle.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/toast_overlay.dart';
import 'sign_in_screen.dart';

/// Reset Password screen — user enters OTP received in email and sets a new password.
class ResetPasswordScreen extends StatefulWidget {
  static const String routeName = '/reset-password';

  final String? initialEmail;

  const ResetPasswordScreen({super.key, this.initialEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _emailError;
  String? _otpError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateEmailDebounced(String value) {
    setState(() {
      _emailError = Validators.validateEmail(value);
    });
  }

  void _validateOtpDebounced(String value) {
    setState(() {
      _otpError = value.trim().isEmpty ? 'Kode OTP wajib diisi' : null;
    });
  }

  void _validateNewPasswordDebounced(String value) {
    setState(() {
      _newPasswordError = Validators.validatePassword(value);
      if (_confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordError = Validators.validateConfirmPassword(
          _confirmPasswordController.text,
          value,
        );
      }
    });
  }

  void _validateConfirmDebounced(String value) {
    setState(() {
      _confirmPasswordError = Validators.validateConfirmPassword(
        value,
        _newPasswordController.text,
      );
    });
  }

  bool _validateAll() {
    final emailErr = Validators.validateEmail(_emailController.text);
    final otpErr =
        _otpController.text.trim().isEmpty ? 'Kode OTP wajib diisi' : null;
    final passErr = Validators.validatePassword(_newPasswordController.text);
    final confErr = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _newPasswordController.text,
    );

    setState(() {
      _emailError = emailErr;
      _otpError = otpErr;
      _newPasswordError = passErr;
      _confirmPasswordError = confErr;
    });

    return emailErr == null &&
        otpErr == null &&
        passErr == null &&
        confErr == null;
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_validateAll()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
      _otpController.text.trim(),
      _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      ToastOverlay.show(
        context,
        'Password berhasil diatur ulang! Silakan masuk.',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } else {
      final errorMsg =
          authProvider.errorMessage ?? 'Gagal mengatur ulang password.';
      ToastOverlay.show(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AuthBackground(
      sheetHeightFraction: 0.72,
      floatingWidget: const BackButtonCircle(),
      topContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('New', style: AppTextStyles.accentMedium),
          const SizedBox(height: 2),
          Text('PASSWORD', style: AppTextStyles.displayLarge),
        ],
      ),
      bottomContent: Column(
        children: [
            // Email Input
            CustomTextField(
              controller: _emailController,
              hintText: 'Email',
              prefixIcon: Iconsax.sms,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              onDebounceChanged: _validateEmailDebounced,
            ),
            const SizedBox(height: 16),

            // OTP Input
            CustomTextField(
              controller: _otpController,
              hintText: 'Kode OTP',
              prefixIcon: Iconsax.key,
              keyboardType: TextInputType.number,
              errorText: _otpError,
              onDebounceChanged: _validateOtpDebounced,
            ),
            const SizedBox(height: 16),

            // New Password Input
            CustomTextField(
              controller: _newPasswordController,
              hintText: 'Password Baru',
              prefixIcon: Iconsax.lock,
              obscureText: _obscureNew,
              errorText: _newPasswordError,
              onDebounceChanged: _validateNewPasswordDebounced,
              suffixWidget: GestureDetector(
                onTap: () => setState(() => _obscureNew = !_obscureNew),
                child: Icon(
                  _obscureNew ? Iconsax.eye_slash : Iconsax.eye,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm New Password Input
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: 'Konfirmasi Password Baru',
              prefixIcon: Iconsax.lock,
              obscureText: _obscureConfirm,
              errorText: _confirmPasswordError,
              onDebounceChanged: _validateConfirmDebounced,
              suffixWidget: GestureDetector(
                onTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                child: Icon(
                  _obscureConfirm ? Iconsax.eye_slash : Iconsax.eye,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reset Button
            PrimaryButton(
              text: 'RESET PASSWORD',
              isLoading: isLoading,
              onPressed: _handleResetPassword,
            ),
            const SizedBox(height: 16),

            // Cancel / Back to login
            GestureDetector(
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              ),
              child: Text(
                'Batal & Masuk',
                style: AppTextStyles.linkText,
              ),
            ),
          ],
        ),
      );
    }
  }
