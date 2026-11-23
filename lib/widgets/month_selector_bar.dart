import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelectorBar extends StatelessWidget {
  final DateTime selectedMonth;
  final List<DateTime> availableMonths;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthSelectorBar({
    super.key,
    required this.selectedMonth,
    required this.availableMonths,
    required this.onMonthChanged,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthFormat = DateFormat('MMMM yyyy', 'tr_TR');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            onPressed: onPrevious,
            tooltip: 'Önceki Ay',
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _showMonthPickerSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        monthFormat.format(selectedMonth),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            onPressed: onNext,
            tooltip: 'Sonraki Ay',
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ],
      ),
    );
  }

  void _showMonthPickerSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final format = DateFormat('MMMM yyyy', 'tr_TR');

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Ay Seçiniz',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableMonths.length,
                  itemBuilder: (ctx, index) {
                    final m = availableMonths[index];
                    final isSelected = m.year == selectedMonth.year && m.month == selectedMonth.month;
                    return ListTile(
                      title: Text(
                        format.format(m),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                          : null,
                      onTap: () {
                        onMonthChanged(m);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
