import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/models/attendance_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'month_selector_bar.dart';

/// Reusable history card for both RiwayatScreen and IzinScreen.
/// Displays attendance records (Hadir, Terlambat, Izin) with unified modern design.
class AttendanceHistoryCard extends StatelessWidget {
  final AttendanceModel item;

  const AttendanceHistoryCard({
    super.key,
    required this.item,
  });

  static String formatDisplayDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(rawDate);
      const dayNames = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      final dayName = dayNames[parsed.weekday - 1];
      final monthName = MonthSelectorBar.monthNames[parsed.month - 1];
      return '$dayName, ${parsed.day.toString().padLeft(2, '0')} $monthName ${parsed.year}';
    } catch (_) {
      return rawDate;
    }
  }

  String _formatTimeDisplay(String? time) {
    if (time == null || time.isEmpty) return '-';
    try {
      final timeOnly = time.contains(' ')
          ? time.split(' ').last
          : (time.contains('T') ? time.split('T').last : time);
      final parts = timeOnly.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')} WIB';
      }
      return '$time WIB';
    } catch (_) {
      return '$time WIB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIzin = item.isIzin;
    final isLate = item.isTerlambat;

    // Status styling & metadata
    final Color statusColor;
    final IconData statusIcon;
    final String title;
    final String badgeText;
    final Color badgeColor;

    if (isIzin) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Iconsax.document_text;
      title = 'Izin Tidak Hadir';
      badgeText = 'Tercatat';
      badgeColor = const Color(0xFF10B981);
    } else if (isLate) {
      statusColor = AppColors.error;
      statusIcon = Iconsax.clock;
      title = 'Presensi Terlambat';
      badgeText = 'Terlambat';
      badgeColor = AppColors.error;
    } else {
      statusColor = const Color(0xFF10B981);
      statusIcon = Iconsax.user_tick;
      title = 'Presensi Hadir';
      badgeText = 'Tepat Waktu';
      badgeColor = const Color(0xFF10B981);
    }

    final address = item.checkInAddress ?? item.checkOutAddress;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Icon + Title/Date + Badge ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            formatDisplayDate(item.attendanceDate),
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.captionSmall.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Body Section ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isIzin
                ? Text(
                    item.alasanIzin?.isNotEmpty == true
                        ? item.alasanIzin!
                        : 'Tidak ada alasan tertulis',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: (isLate
                                            ? AppColors.error
                                            : const Color(0xFF10B981))
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Iconsax.login,
                                    size: 14,
                                    color: isLate
                                        ? AppColors.error
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Masuk',
                                        style:
                                            AppTextStyles.captionSmall.copyWith(
                                          fontSize: 10,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      Text(
                                        _formatTimeDisplay(item.checkInTime),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isLate
                                              ? AppColors.error
                                              : AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Iconsax.logout,
                                    size: 14,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pulang',
                                        style:
                                            AppTextStyles.captionSmall.copyWith(
                                          fontSize: 10,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      Text(
                                        _formatTimeDisplay(item.checkOutTime),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (address != null && address.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Divider(
                          color: AppColors.inputBorder.withValues(alpha: 0.5),
                          height: 1,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Iconsax.location,
                              size: 13,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                address,
                                style: AppTextStyles.captionSmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
