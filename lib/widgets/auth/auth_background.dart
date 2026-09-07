import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The blue gradient background + subtle wavy white sheet scaffold used by all auth screens.
///
/// [sheetHeightFraction] controls how much of the screen height the white sheet covers:
/// - Welcome: 0.52
/// - Sign In: 0.68
/// - Register: 0.75
class AuthBackground extends StatelessWidget {
  final double sheetHeightFraction;
  final Widget topContent;
  final Widget bottomContent;
  final Widget? floatingWidget; // e.g., back button

  const AuthBackground({
    super.key,
    required this.sheetHeightFraction,
    required this.topContent,
    required this.bottomContent,
    this.floatingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          final sheetHeight = totalHeight * sheetHeightFraction;
          final topHeight = totalHeight - sheetHeight;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              gradient: RadialGradient(
                center: Alignment(-0.7, -0.4),
                radius: 1.0,
                colors: [AppColors.primaryLight, AppColors.primaryBlue],
                stops: [0.0, 0.5],
              ),
            ),
            child: Stack(
              children: [
                // Second radial gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.7, 0.4),
                      radius: 1.0,
                      colors: [
                        Color(0x400D92BD), // primaryDark with alpha
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.5],
                    ),
                  ),
                ),

                // Top (blue area)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topHeight + 12, // slight overlap with wave crest
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Center(child: topContent),
                    ),
                  ),
                ),

                // White sheet with gentle, subtle wave
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: sheetHeight,
                  child: ClipPath(
                    clipper: _GentleWaveClipper(),
                    child: Container(
                      color: AppColors.white,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(30, 38, 30, 24),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: bottomContent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating widget (back button)
                ?floatingWidget,
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A natural, organic wave clipper mimicking realistic soft water/landscape curvature.
class _GentleWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;

    path.moveTo(0, 16);

    // First gentle natural undulation
    path.cubicTo(
      w * 0.15,
      6,
      w * 0.35,
      10,
      w * 0.50,
      20,
    );

    // Second gentle natural undulation
    path.cubicTo(
      w * 0.65,
      28,
      w * 0.85,
      8,
      w,
      14,
    );

    path.lineTo(w, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
