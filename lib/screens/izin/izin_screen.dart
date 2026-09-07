import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/providers/attendance_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_wavy_header.dart';
import '../../widgets/common/attendance_history_card.dart';
import '../../widgets/common/month_selector_bar.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/toast_overlay.dart';

class IzinScreen extends StatefulWidget {
  const IzinScreen({super.key});

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<AttendanceProvider>().fetchHistoryForMonth(_selectedMonth);
  }

  void _showFormIzinModal(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final reasonController = TextEditingController();
    String? formError;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateText =
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.inputBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pengajuan Izin',
                          style: AppTextStyles.headingSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.close_circle, size: 22),
                          color: AppColors.textLight,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Input
                    Text(
                      'Tanggal Izin',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primaryBlue,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.inputBorder, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.calendar_1,
                                  size: 18,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  dateText,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Iconsax.arrow_down_1,
                              size: 16,
                              color: AppColors.textLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason Text Field
                    Text(
                      'Alasan Izin / Keterangan',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 4,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText:
                            'Jelaskan alasan izin secara jelas (misal: Sakit demam, keperluan administrasi)...',
                        hintStyle: AppTextStyles.bodyRegular.copyWith(
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (formError != null) ...[
                      const SizedBox(height: 8),
                      Text(formError!, style: AppTextStyles.errorText),
                    ],
                    const SizedBox(height: 20),

                    // Submit Button
                    PrimaryButton(
                      text: 'KIRIM PERIZINAN',
                      isLoading: isSubmitting,
                      onPressed: () async {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          setModalState(() {
                            formError = 'Alasan izin wajib diisi.';
                          });
                          return;
                        }

                        setModalState(() {
                          formError = null;
                          isSubmitting = true;
                        });

                        final provider = context.read<AttendanceProvider>();
                        final success = await provider.submitIzin(
                          date: selectedDate,
                          reason: reason,
                        );

                        setModalState(() {
                          isSubmitting = false;
                        });

                        if (context.mounted) {
                          if (success) {
                            final dateFormatted =
                                '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
                            await context
                                .read<NotificationProvider>()
                                .addNotification(
                                  title: 'Pengajuan Izin Berhasil',
                                  message:
                                      'Pengajuan izin untuk tanggal $dateFormatted telah berhasil dicatat.',
                                  type: 'izin',
                                );
                            if (context.mounted) {
                              Navigator.of(ctx).pop();
                              // Also refresh today data for hasIzinToday
                              provider.fetchToday();
                              _fetchData();
                              ToastOverlay.show(
                                context,
                                'Pengajuan izin berhasil dikirim!',
                              );
                            }
                          } else {
                            setModalState(() {
                              formError = provider.errorMessage ??
                                  'Gagal mengajukan izin.';
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final izinList = attendance.izinList;
    final isLoading = attendance.isLoading;

    final bottomPadding = MediaQuery.of(context).padding.bottom + 140;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchData();
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
              AppWavyHeader(
                subtitle: 'Daftar Perizinan,',
                title: 'IZIN',
                height: 175,
                trailing: ElevatedButton.icon(
                  onPressed: () => _showFormIzinModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Iconsax.add, size: 16, color: AppColors.primaryBlue),
                  label: Text(
                    'Ajukan',
                    style: AppTextStyles.buttonText.copyWith(
                      fontSize: 14,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
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
                        _fetchData();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content (Loading / Empty / List)
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  )
                else if (izinList.isEmpty)
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.document_text,
                              size: 28,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Pengajuan Izin',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tekan tombol "+ Ajukan Izin" di atas untuk membuat surat keterangan izin atau sakit.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                              fontSize: 13,
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
                    itemCount: izinList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return AttendanceHistoryCard(item: izinList[index]);
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
