import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_notification_model.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Opens the unified SQFlite-backed custom notification modal.
/// Accessible identically from Home and Profile screens.
void showNotificationModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _NotificationModalContent(),
  );
}

class _NotificationModalContent extends StatelessWidget {
  const _NotificationModalContent();

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;
    final unreadCount = notifProvider.unreadCount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Text(
                'Notifikasi',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount Baru',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (notifications.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    await notifProvider.deleteAllNotifications();
                  },
                  icon: const Icon(Iconsax.trash, size: 15, color: AppColors.error),
                  label: Text(
                    'Hapus Semua',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              IconButton(
                icon: const Icon(Iconsax.close_circle, size: 22),
                color: AppColors.textLight,
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.inputBorder, height: 1),
          const SizedBox(height: 12),

          // List or Empty State
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: notifications.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _NotificationTile(
                        item: item,
                        onTap: () => notifProvider.markAsRead(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.notification_bing,
              color: AppColors.primaryBlue,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Notifikasi',
            style: AppTextStyles.headingLilita.copyWith(
              fontSize: 18,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Semua riwayat presensi masuk, pulang, dan perizinan Anda akan tercatat di sini.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel item;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final iconData = _getIcon(item.type);
    final iconColor = _getColor(item.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? AppColors.primaryBlue.withValues(alpha: 0.6)
                : AppColors.inputBorder,
            width: isUnread ? 1.5 : 1.0,
          ),
          // Glow effect on unread notification items
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Glow unread dot
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isUnread
                          ? AppColors.textDark.withValues(alpha: 0.8)
                          : AppColors.textLight,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.formattedTimestamp,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'welcome':
        return Iconsax.star_1;
      case 'check_in':
      case 'masuk':
        return Iconsax.login_1;
      case 'check_out':
      case 'pulang':
        return Iconsax.logout_1;
      case 'izin':
        return Iconsax.document_text;
      default:
        return Iconsax.notification;
    }
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'welcome':
        return AppColors.warning;
      case 'check_in':
      case 'masuk':
        return AppColors.success;
      case 'check_out':
      case 'pulang':
        return AppColors.primaryBlue;
      case 'izin':
        return const Color(0xFFE67E22);
      default:
        return AppColors.primaryBlue;
    }
  }
}
