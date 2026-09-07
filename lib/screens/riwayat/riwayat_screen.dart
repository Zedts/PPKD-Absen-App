import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/models/attendance_model.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_wavy_header.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late DateTime _selectedMonth;
  int _selectedFilterIndex = 0;

  final List<String> _filters = ['Semua', 'Hadir', 'Izin', 'Terlambat'];

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataForSelectedMonth();
    });
  }

  void _fetchDataForSelectedMonth() {
    final start =
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-01';
    final lastDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final end =
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${lastDayOfMonth.toString().padLeft(2, '0')}';

    context.read<AttendanceProvider>().fetchHistory(start: start, end: end);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
    _fetchDataForSelectedMonth();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    if (next.isAfter(DateTime(now.year, now.month, 1))) return;

    setState(() {
      _selectedMonth = next;
    });
    _fetchDataForSelectedMonth();
  }

  String _formatDisplayDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(rawDate);
      final dayName = _dayNames[parsed.weekday - 1];
      final monthName = _monthNames[parsed.month - 1];
      return '$dayName, ${parsed.day.toString().padLeft(2, '0')} $monthName ${parsed.year}';
    } catch (_) {
      return rawDate;
    }
  }

  List<AttendanceModel> _getFilteredList(List<AttendanceModel> all) {
    switch (_selectedFilterIndex) {
      case 1: // Hadir
        return all
            .where((item) => (item.status ?? '').toLowerCase() == 'masuk')
            .toList();
      case 2: // Izin
        return all
            .where((item) => (item.status ?? '').toLowerCase() == 'izin')
            .toList();
      case 3: // Terlambat
        return all
            .where((item) => (item.status ?? '').toLowerCase() == 'terlambat')
            .toList();
      default: // Semua
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final isLoading = attendance.isLoading;
    final allList = attendance.historyList;
    final filteredList = _getFilteredList(allList);

    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchDataForSelectedMonth();
        },
        color: AppColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Wavy Header ──────────────────────────────────────
              const AppWavyHeader(
                subtitle: 'Log Kehadiran,',
                title: 'RIWAYAT PRESENSI',
                height: 175,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Month Selector ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.inputBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Iconsax.arrow_left_2, size: 18),
                            color: AppColors.textDark,
                            onPressed: _previousMonth,
                            splashRadius: 22,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.calendar_1,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.arrow_right_3, size: 18),
                            color: isCurrentMonth
                                ? AppColors.inputBorder
                                : AppColors.textDark,
                            onPressed: isCurrentMonth ? null : _nextMonth,
                            splashRadius: 22,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Filter Chips ────────────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(_filters.length, (index) {
                          final isSelected = _selectedFilterIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedFilterIndex = index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : AppColors.inputBorder,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: AppColors.primaryBlue
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: Text(
                                  _filters[index],
                                  style: AppTextStyles.captionSmall.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── History List Content ────────────────────────────────
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      )
                    else if (filteredList.isEmpty)
                      Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 48,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue
                                      .withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Iconsax.calendar_remove,
                                  color: AppColors.primaryBlue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum Ada Riwayat Presensi',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tidak ada catatan presensi pada periode ini.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return _HistoryDayCard(
                            formattedDate:
                                _formatDisplayDate(item.attendanceDate),
                            checkIn: item.checkInTime != null
                                ? '${item.checkInTime} WIB'
                                : '-',
                            checkOut: item.checkOutTime != null
                                ? '${item.checkOutTime} WIB'
                                : '-',
                            status: item.status ?? 'masuk',
                            address: item.checkInAddress,
                            reason: item.alasanIzin,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryDayCard extends StatelessWidget {
  final String formattedDate;
  final String checkIn;
  final String checkOut;
  final String status;
  final String? address;
  final String? reason;

  const _HistoryDayCard({
    required this.formattedDate,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    this.address,
    this.reason,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'masuk':
        return const Color(0xFF10B981);
      case 'terlambat':
        return const Color(0xFFF59E0B);
      case 'izin':
        return const Color(0xFF3B82F6);
      default:
        return AppColors.textLight;
    }
  }

  String _getStatusLabel() {
    switch (status.toLowerCase()) {
      case 'masuk':
        return 'Tepat Waktu';
      case 'terlambat':
        return 'Terlambat';
      case 'izin':
        return 'Izin';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusLabel = _getStatusLabel();
    final isIzin = status.toLowerCase() == 'izin';

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
          // Row Header: Date & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.captionSmall.copyWith(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isIzin && reason != null && reason!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Iconsax.info_circle,
                    size: 15,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Times: Check-in and Check-out
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.login,
                          size: 15,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Absen Masuk',
                            style: AppTextStyles.captionSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            checkIn,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.logout,
                          size: 15,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Absen Pulang',
                            style: AppTextStyles.captionSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            checkOut,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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

          if (address != null && address!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Iconsax.location,
                  size: 13,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address!,
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
    );
  }
}

