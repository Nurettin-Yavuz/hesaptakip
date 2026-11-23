import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedDay != null
                      ? '$selectedDay. Gün Harcamaları Filtrelendi'
                      : '1\'inden $daysInMonth\'ine Günlük Takip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectedDay != null) ...[
                InkWell(
                  onTap: () => onSelectDay?.call(selectedDay!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Filtreyi Temizle', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Bugün: $currentDay',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Yatay Kayan Günlük Harcama Barları (1 - 30/31 Günler)
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final spent = dailyMap[day] ?? 0.0;
                final isToday = day == currentDay;
                final isSelected = day == selectedDay;
                final hasSpent = spent > 0;
                final barHeightRatio = maxSpent > 0 ? (spent / maxSpent).clamp(0.12, 1.0) : 0.08;

                return InkWell(
                  onTap: () => onSelectDay?.call(day),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasSpent)
                          Text(
                            currencyFormat.format(spent),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                        const SizedBox(height: 4),

                        // Harcama Sütunu
                        Container(
                          width: 14,
                          height: 44 * barHeightRatio,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : (hasSpent
                                    ? (isToday ? const Color(0xFF4F46E5) : const Color(0xFF818CF8))
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            borderRadius: BorderRadius.circular(4),
                            border: isToday
                                ? Border.all(color: Colors.white, width: 1.5)
                                : (isSelected ? Border.all(color: const Color(0xFF10B981), width: 1.5) : null),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Gün Numarası
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : (isToday
                                  ? BoxDecoration(
                                      color: const Color(0xFF4F46E5),
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                  : null),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: (isToday || isSelected) ? FontWeight.w800 : FontWeight.w600,
                              color: (isToday || isSelected)
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
    );
  }
}
