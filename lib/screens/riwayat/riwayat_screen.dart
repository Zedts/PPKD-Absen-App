import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/models/attendance_model.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_wavy_header.dart';
import '../../widgets/common/attendance_history_card.dart';
import '../../widgets/common/month_selector_bar.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late DateTime _selectedMonth;
  int _selectedFilterIndex = 0;

  final List<String> _filters = ['Semua', 'Hadir', 'Izin', 'Terlambat'];



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
    context.read<AttendanceProvider>().fetchHistoryForMonth(_selectedMonth);
  }



  List<AttendanceModel> _getFilteredList(List<AttendanceModel> all) {
    switch (_selectedFilterIndex) {
      case 1: // Hadir
        return all.where((item) => item.isHadir).toList();
      case 2: // Izin
        return all.where((item) => item.isIzin).toList();
      case 3: // Terlambat
        return all.where((item) => item.isTerlambat).toList();
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

    final bottomPadding = MediaQuery.of(context).padding.bottom + 140;

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
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Month Selector ──────────────────────────────────────
                    MonthSelectorBar(
                      selectedMonth: _selectedMonth,
                      onMonthChanged: (newMonth) {
                        setState(() {
                          _selectedMonth = newMonth;
                        });
                        _fetchDataForSelectedMonth();
                      },
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
                    const SizedBox(height: 16),

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
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return AttendanceHistoryCard(
                            item: filteredList[index],
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

