import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_item.dart';

class AnalyticsView extends StatelessWidget {
  final TransactionController controller;

  const AnalyticsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary;
    final categoryMap = controller.categoryDistribution;
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ödeme Türü Karşılaştırması',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tüm harcamalarınızın Kredi Kartı ve Nakit oran dağılımı.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                if (summary.grandTotal == 0)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Henüz analiz edilecek veri bulunmuyor.'),
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            color: const Color(0xFF4F46E5),
                            value: summary.creditCardTotal,
                            title: '%${summary.creditCardRatio.toStringAsFixed(1)}',
                            radius: 40,
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: const Color(0xFF10B981),
                            value: summary.cashTotal,
                            title: '%${summary.cashRatio.toStringAsFixed(1)}',
                            radius: 40,
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(
                        color: const Color(0xFF4F46E5),
                        label: 'Kredi Kartı',
                        amount: currencyFormat.format(summary.creditCardTotal),
                      ),
                      const SizedBox(width: 24),
                      _buildLegend(
                        color: const Color(0xFF10B981),
                        label: 'Nakit',
                        amount: currencyFormat.format(summary.cashTotal),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Kategori Bazlı Harcama Dağılımı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori Dağılımı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                if (categoryMap.isEmpty)
                  const Text('Henüz kategori verisi bulunmuyor.')
                else
                  ...categoryMap.entries.map((entry) {
                    final percent = summary.grandTotal > 0
                        ? (entry.value / summary.grandTotal) * 100
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              Text(
                                '${currencyFormat.format(entry.value)} (%${percent.toStringAsFixed(1)})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (percent / 100).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getCategoryColor(entry.key),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({
    required Color color,
    required String label,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getCategoryColor(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.market:
        return const Color(0xFF3B82F6);
      case ExpenseCategory.fatura:
        return const Color(0xFFF59E0B);
      case ExpenseCategory.akaryakit:
        return const Color(0xFFEF4444);
      case ExpenseCategory.restoran:
        return const Color(0xFF8B5CF6);
      case ExpenseCategory.saglik:
        return const Color(0xFF10B981);
      case ExpenseCategory.eglence:
        return const Color(0xFFEC4899);
      case ExpenseCategory.giyim:
        return const Color(0xFF06B6D4);
      case ExpenseCategory.diger:
        return const Color(0xFF64748B);
    }
  }
}
