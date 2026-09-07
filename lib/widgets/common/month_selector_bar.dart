import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Reusable month selector bar with previous/next navigation and month display.
class MonthSelectorBar extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final DateTime? maxMonth;

  const MonthSelectorBar({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
    this.maxMonth,
  });

  static const List<String> monthNames = [
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final effectiveMax = maxMonth ?? DateTime(now.year, now.month, 1);
    final isCurrentMonth = selectedMonth.year == effectiveMax.year &&
        selectedMonth.month == effectiveMax.month;

    return Container(
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
            onPressed: () {
              final prev =
                  DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
              onMonthChanged(prev);
            },
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
                '${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}',
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
            color: isCurrentMonth ? AppColors.inputBorder : AppColors.textDark,
            onPressed: isCurrentMonth
                ? null
                : () {
                    final next = DateTime(
                        selectedMonth.year, selectedMonth.month + 1, 1);
                    if (!next.isAfter(effectiveMax)) {
                      onMonthChanged(next);
                    }
                  },
            splashRadius: 22,
          ),
        ],
      ),
    );
  }
}
