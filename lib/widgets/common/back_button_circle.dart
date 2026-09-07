import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Circular translucent back button for auth screens, matching
/// the `.btn-back` style from auth_screen.html.
class BackButtonCircle extends StatelessWidget {
  final VoidCallback? onPressed;

  const BackButtonCircle({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.of(context).pop(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: const Icon(
            Iconsax.arrow_left,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
