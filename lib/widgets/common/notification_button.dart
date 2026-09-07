import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import 'notification_modal.dart';

/// A circular header button with a reactive badge counter (capped at 99+).
/// Tapping it opens the unified SQFlite-backed custom notification modal.
class NotificationButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;

  const NotificationButton({
    super.key,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor = AppColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final badgeText = notifProvider.badgeText;
    final hasUnread = notifProvider.unreadCount > 0;

    return InkWell(
      onTap: onTap ?? () => showNotificationModal(context),
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 4,
                  spreadRadius: -1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Icon(Iconsax.notification, color: iconColor, size: 20),
          ),
          if (hasUnread)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.45),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    badgeText,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
