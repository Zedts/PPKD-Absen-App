import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// "or continue with" / "or sign in with" divider from the HTML reference.
class SocialDivider extends StatelessWidget {
  final String text;

  const SocialDivider({super.key, this.text = 'or continue with'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.inputBorder, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(text, style: AppTextStyles.dividerText),
          ),
          const Expanded(
            child: Divider(color: AppColors.inputBorder, thickness: 1),
          ),
        ],
      ),
    );
  }
}
