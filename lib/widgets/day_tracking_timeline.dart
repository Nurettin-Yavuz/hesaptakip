import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class DayTrackingTimeline extends StatelessWidget {
  final Map<int, double> dailyMap;
  final int daysInMonth;
  final int currentDay;
  final double monthlyLimit;
  final int? selectedDay;
  final ValueChanged<int>? onSelectDay;

  const DayTrackingTimeline({
    super.key,
    required this.dailyMap,
    required this.daysInMonth,
    required this.currentDay,
    required this.monthlyLimit,
    this.selectedDay,
    this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.compactSimpleCurrency(locale: 'tr_TR', name: '₺');
    final double maxSpent = dailyMap.values.fold(0.0, (max, v) => v > max ? v : max);

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedDay != null
                      ? '$selectedDay. Gün Harcamaları'
                      : 'GÜNLÜK AKIŞ (1-$daysInMonth)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectedDay != null) ...[
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelectDay?.call(selectedDay!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Sıfırla',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.crimson),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor, width: 0.6),
                ),
                child: Text(
                  'Bugün: $currentDay',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Yatay Kayan Günlük Harcama Barları (1 - 30/31 Günler)
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final spent = dailyMap[day] ?? 0.0;
                final isToday = day == currentDay;
                final isSelected = day == selectedDay;
                final hasSpent = spent > 0;

                // Normalize edilmiş çubuk yüksekliği (0.0 - 1.0)
                final double barRatio = maxSpent > 0 ? (spent / maxSpent).clamp(0.08, 1.0) : 0.08;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelectDay?.call(day);
                  },
                  child: Container(
                    width: 28,
                    margin: const EdgeInsets.only(right: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tutar etiketi (Sadece harcama varsa)
                        if (hasSpent)
                          Text(
                            currencyFormat.format(spent),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primary : textMuted,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                          )
                        else
                          const SizedBox(height: 10),
                        const SizedBox(height: 4),

                        // Çubuk
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isSelected ? 12 : 8,
                              height: 48 * barRatio,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (hasSpent
                                        ? (isToday ? AppColors.iceBlue : (isDark ? AppColors.darkBorder : AppColors.lightBorder))
                                        : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Gün Numarası
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: isToday
                              ? BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isToday
                                  ? Colors.white
                                  : (isSelected ? AppColors.primary : textSecondary),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
