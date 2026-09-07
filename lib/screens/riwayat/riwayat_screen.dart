import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Log Kehadiran',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Riwayat Presensi',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),

              // Month Selector Box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar_2,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'September 2026',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Iconsax.arrow_down_1,
                      color: AppColors.textLight,
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Attendance History List
              _HistoryDayCard(
                date: 'Senin, 07 Sep 2026',
                checkIn: '07:48 WIB',
                checkOut: '16:02 WIB',
                status: 'Tepat Waktu',
                statusColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _HistoryDayCard(
                date: 'Jumat, 04 Sep 2026',
                checkIn: '07:55 WIB',
                checkOut: '16:30 WIB',
                status: 'Tepat Waktu',
                statusColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _HistoryDayCard(
                date: 'Kamis, 03 Sep 2026',
                checkIn: '08:12 WIB',
                checkOut: '16:05 WIB',
                status: 'Terlambat',
                statusColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _HistoryDayCard(
                date: 'Rabu, 02 Sep 2026',
                checkIn: '-',
                checkOut: '-',
                status: 'Izin',
                statusColor: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 12),
              _HistoryDayCard(
                date: 'Selasa, 01 Sep 2026',
                checkIn: '07:50 WIB',
                checkOut: '16:00 WIB',
                status: 'Tepat Waktu',
                statusColor: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryDayCard extends StatelessWidget {
  final String date;
  final String checkIn;
  final String checkOut;
  final String status;
  final Color statusColor;

  const _HistoryDayCard({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.login,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Absen Masuk',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          checkIn,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.logout,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Absen Pulang',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          checkOut,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
