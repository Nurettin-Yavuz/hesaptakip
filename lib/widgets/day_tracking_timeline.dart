import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayTrackingTimeline extends StatelessWidget {
  final Map<int, double> dailyMap;
  final int daysInMonth;
  final int currentDay;
  final double monthlyLimit;

  const DayTrackingTimeline({
    super.key,
    required this.dailyMap,
    required this.daysInMonth,
    required this.currentDay,
    required this.monthlyLimit,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1\'inden $daysInMonth\'ine Günlük Harcama Takibi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Bugün: Gün $currentDay',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
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
                final hasSpent = spent > 0;
                final barHeightRatio = maxSpent > 0 ? (spent / maxSpent).clamp(0.12, 1.0) : 0.08;

                return Padding(
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
                          color: hasSpent
                              ? (isToday ? const Color(0xFF4F46E5) : const Color(0xFF818CF8))
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(4),
                          border: isToday
                              ? Border.all(color: Colors.white, width: 1.5)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Gün Numarası
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: isToday
                            ? BoxDecoration(
                                color: const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(4),
                              )
                            : null,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                            color: isToday
                                ? Colors.white
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
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
