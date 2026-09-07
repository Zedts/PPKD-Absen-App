import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A cohesive top wavy header widget bringing the vibrant blue gradient,
/// signature Pacifico & Lilita One typography, and organic curved wave
/// from the Auth screen to the main application screens.
class AppWavyHeader extends StatelessWidget {
  final String subtitle;
  final String title;
  final Widget? trailing;
  final double height;
  final Widget? bottomChild;

  const AppWavyHeader({
    super.key,
    required this.subtitle,
    required this.title,
    this.trailing,
    this.height = 180,
    this.bottomChild,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Extended blue background for pull-to-refresh overscroll (above the wave)
          Positioned(
            top: -1000,
            left: 0,
            right: 0,
            height: 1000 + 40,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                gradient: RadialGradient(
                  center: Alignment(-0.7, -0.4),
                  radius: 1.2,
                  colors: [AppColors.primaryLight, AppColors.primaryBlue],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),

          // Background with Auth screen radial gradient + gentle wave
          ClipPath(
            clipper: _HeaderWaveClipper(),
            child: Container(
              height: height,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                gradient: RadialGradient(
                  center: Alignment(-0.7, -0.4),
                  radius: 1.2,
                  colors: [AppColors.primaryLight, AppColors.primaryBlue],
                  stops: [0.0, 0.7],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, 0.3),
                    radius: 1.0,
                    colors: [
                      const Color(0xFF0D92BD).withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              subtitle,
                              style: AppTextStyles.accentPacifico.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: AppTextStyles.headingLilita.copyWith(
                                color: Colors.white,
                                fontSize: 24,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  if (bottomChild != null) ...[
                    const SizedBox(height: 12),
                    bottomChild!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smooth organic wave clipper matching the auth screen gentle curves.
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);

    // First curve dipping down then rising
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.55, size.height - 18);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Second curve smoothly finishing at right edge
    final secondControlPoint = Offset(size.width * 0.85, size.height - 36);
    final secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
