import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography system matching auth_screen.html reference.
///
/// - Lilita One: display / button titles
/// - Pacifico: accent headings ("Hello,", "Create your")
/// - Plus Jakarta Sans: body text, inputs, labels
class AppTextStyles {
  AppTextStyles._();

  // ── Display (Lilita One) ──────────────────────────────────────────────

  static TextStyle displayLarge = GoogleFonts.lilitaOne(
    fontSize: 36,
    letterSpacing: 1,
    height: 1.1,
    color: AppColors.white,
  );

  static TextStyle buttonText = GoogleFonts.lilitaOne(
    fontSize: 20,
    letterSpacing: 1,
    color: AppColors.white,
  );

  static TextStyle linkText = GoogleFonts.lilitaOne(
    fontSize: 16,
    letterSpacing: 0.5,
    color: AppColors.primaryBlue,
  );

  // ── Accent (Pacifico) ─────────────────────────────────────────────────

  static TextStyle accentHeading = GoogleFonts.pacifico(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: Colors.white.withValues(alpha: 0.9),
  );

  static TextStyle accentMedium = GoogleFonts.pacifico(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: Colors.white.withValues(alpha: 0.9),
  );

  static TextStyle headingSmall = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static TextStyle forgotPassword = GoogleFonts.pacifico(
    fontSize: 16,
    color: AppColors.primaryBlue,
  );

  // ── Body (Plus Jakarta Sans) ──────────────────────────────────────────

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static TextStyle bodyRegular = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static TextStyle errorText = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );

  static TextStyle dividerText = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  static TextStyle googleButton = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textDark,
  );

  static TextStyle navLabel = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );
}
