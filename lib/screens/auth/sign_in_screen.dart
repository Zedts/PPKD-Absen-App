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
import '../../widgets/common/google_sign_in_button.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/social_divider.dart';
import '../../widgets/common/toast_overlay.dart';
import '../main_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Sign In screen matching auth_screen.html
class SignInScreen extends StatefulWidget {
  static const String routeName = '/sign-in';

  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmailDebounced(String value) {
    setState(() {
      _emailError = Validators.validateEmail(value);
    });
  }

  void _validatePasswordDebounced(String value) {
    setState(() {
      _passwordError = Validators.validatePassword(value);
    });
  }

  bool _validateAll() {
    final emailErr = Validators.validateEmail(_emailController.text);
    final passErr = Validators.validatePassword(_passwordController.text);

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    return emailErr == null && passErr == null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_validateAll()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ToastOverlay.show(context, 'Masuk berhasil!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } else {
      final errorMsg = authProvider.errorMessage ?? 'Email atau password salah';
      ToastOverlay.show(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AuthBackground(
      sheetHeightFraction: 0.68,
      floatingWidget: const BackButtonCircle(),
      topContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Hello,', style: AppTextStyles.accentMedium),
          const SizedBox(height: 2),
          Text('SIGN IN', style: AppTextStyles.displayLarge),
        ],
      ),
      bottomContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Email Input
            CustomTextField(
              controller: _emailController,
              hintText: 'Joydeo@gmail.com',
              prefixIcon: Iconsax.sms,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              onDebounceChanged: _validateEmailDebounced,
              suffixWidget: _emailError == null && _emailController.text.isNotEmpty
                  ? const Icon(
                      Icons.check,
                      color: AppColors.primaryBlue,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(height: 18),

            // Password Input
            CustomTextField(
              controller: _passwordController,
              hintText: 'Password',
              prefixIcon: Iconsax.lock,
              obscureText: _obscurePassword,
              errorText: _passwordError,
              onDebounceChanged: _validatePasswordDebounced,
              suffixWidget: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ),
            ),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.forgotPassword,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sign In Button
            PrimaryButton(
              text: 'SIGN IN',
              isLoading: isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 12),

            // Social divider
            const SocialDivider(text: 'or sign in with'),

            // Google button
            GoogleSignInButton(
              onPressed: () {
                ToastOverlay.show(context, 'Google Sign-In segera hadir');
              },
            ),
            const SizedBox(height: 16),

            // Bottom sign up link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have account? ", style: AppTextStyles.bodySmall),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text('Sign up', style: AppTextStyles.linkText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
