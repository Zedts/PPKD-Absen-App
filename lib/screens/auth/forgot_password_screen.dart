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
import 'reset_password_screen.dart';

/// Forgot Password screen — requests an OTP for password recovery.
class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgot-password';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmailDebounced(String value) {
    setState(() {
      _emailError = Validators.validateEmail(value);
    });
  }

  Future<void> _handleSendOtp() async {
    FocusScope.of(context).unfocus();

    final err = Validators.validateEmail(_emailController.text);
    if (err != null) {
      setState(() => _emailError = err);
      return;
    }

    final email = _emailController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(email);

    if (!mounted) return;

    if (success) {
      ToastOverlay.show(context, 'Kode OTP telah dikirim ke email Anda!');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(initialEmail: email),
        ),
      );
    } else {
      final errorMsg =
          authProvider.errorMessage ?? 'Gagal mengirim OTP. Periksa email Anda.';
      ToastOverlay.show(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AuthBackground(
      sheetHeightFraction: 0.58,
      floatingWidget: const BackButtonCircle(),
      topContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Reset your', style: AppTextStyles.accentMedium),
          const SizedBox(height: 2),
          Text('PASSWORD', style: AppTextStyles.displayLarge),
        ],
      ),
      bottomContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masukkan email yang terdaftar untuk menerima kode verifikasi OTP.',
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Email Input
          CustomTextField(
            controller: _emailController,
            hintText: 'Joydeo@gmail.com',
            prefixIcon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onDebounceChanged: _validateEmailDebounced,
          ),
          const SizedBox(height: 32),

          // Send Button
          PrimaryButton(
            text: 'KIRIM KODE OTP',
            isLoading: isLoading,
            onPressed: _handleSendOtp,
          ),
          const SizedBox(height: 20),

          // Back to login link
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'Kembali ke Sign In',
                style: AppTextStyles.linkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
