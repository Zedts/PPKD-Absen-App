import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../widgets/auth/auth_background.dart';
import '../../widgets/common/google_sign_in_button.dart';
import '../../widgets/common/outline_button_widget.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/social_divider.dart';
import '../../widgets/common/toast_overlay.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';

/// The initial landing / welcome screen matching auth_screen.html
/// Displays "WELCOME BACK", Sign In (outline), Sign Up (solid), and Google button.
class WelcomeScreen extends StatelessWidget {
  static const String routeName = '/welcome';

  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      sheetHeightFraction: 0.58,
      topContent: Text(
        'WELCOME\nBACK',
        textAlign: TextAlign.center,
        style: AppTextStyles.displayLarge,
      ),
      bottomContent: Column(
        children: [
          OutlineButtonWidget(
            text: 'SIGN IN',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            text: 'SIGN UP',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          const SocialDivider(text: 'or continue with'),
          GoogleSignInButton(
            onPressed: () {
              ToastOverlay.show(context, 'Google Sign-In segera hadir');
            },
          ),
        ],
      ),
    );
  }
}
