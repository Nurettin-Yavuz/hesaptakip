import 'package:flutter/material.dart';
import '../models/transaction_item.dart';

/// Tasarımcı ve Yazılımcı ortak üretimi: Apple Card & Neobank seviyesinde
/// Finansal Sağlık Skoru ve Akıllı Bütçe Nabzı Kartı.
class FinancialPulseCard extends StatefulWidget {
  final FinancialHealthScore healthScore;
  final bool hideAmounts;
  final VoidCallback? onTapDetails;

  const FinancialPulseCard({
    super.key,
    required this.healthScore,
    this.hideAmounts = false,
    this.onTapDetails,
  });

  @override
  State<FinancialPulseCard> createState() => _FinancialPulseCardState();
}

class _FinancialPulseCardState extends State<FinancialPulseCard> {
  bool _isExpanded = false;

  Color _getLevelColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return const Color(0xFF10B981);
      case HealthLevel.balanced:
        return const Color(0xFF4F46E5);
      case HealthLevel.warning:
        return const Color(0xFFF59E0B);
      case HealthLevel.critical:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getLevelIcon(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return Icons.verified_rounded;
      case HealthLevel.balanced:
        return Icons.insights_rounded;
      case HealthLevel.warning:
        return Icons.warning_amber_rounded;
      case HealthLevel.critical:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelColor = _getLevelColor(widget.healthScore.level);
    final score = widget.healthScore.score;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
            widget.onTapDetails?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst Başlık Satırı: İkon, Başlık ve Durum Rozeti
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getLevelIcon(widget.healthScore.level),
                        color: levelColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finansal Sağlık & Bütçe Nabzı',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Yapay Zeka Destekli Anlık Risk Analizi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: levelColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.healthScore.statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: levelColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gösterge Satırı: Dairesel Gösterge ve 3 Alt KPI
                Row(
                  children: [
                    // Sol: Dairesel Skor Göstergesi
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: widget.hideAmounts ? 0.75 : (score / 100.0),
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.hideAmounts ? '••' : '$score',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                '/100',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Sağ: 3 Alt Metrik Barı
                    Expanded(
                      child: Column(
                        children: [
                          _buildMetricBar(
                            title: 'Bütçe Disiplini',
                            ratio: widget.healthScore.budgetDisciplineRatio,
                            activeColor: const Color(0xFF4F46E5),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildMetricBar(
                            title: 'Tasarruf Gücü',
                            ratio: widget.healthScore.savingsScoreRatio,
                            activeColor: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildMetricBar(
                            title: 'Nakit/Kart Dengesi',
                            ratio: widget.healthScore.cardDependencyRatio,
                            activeColor: const Color(0xFF06B6D4),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Akıllı Tavsiye ve Detay Açılır Alanı
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: levelColor, width: 3.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: levelColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.healthScore.advice,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),

                // Genişletilmiş Detay Açıklaması
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Finansal Sağlık Skoru Nasıl Hesaplanır?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Bütçe Disiplini (%45): Aylık harcamanızın geçen gün sayısı ve belirlenen limit ile uyumu.\n'
                    '• Tasarruf Gücü (%30): Aktif tasarruf kumbaralarınızın hedefe ulaşma yüzdesi.\n'
                    '• Kredi Kartı Dengesi (%25): Harcamaların kredi kartına aşırı bağımlı olmaması ve nakit/kart dengesi.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBar({
    required String title,
    required double ratio,
    required Color activeColor,
    required bool isDark,
  }) {
    final percentText = widget.hideAmounts ? '••%' : '%${(ratio * 100).toStringAsFixed(0)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              percentText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),
        ),
      ],
    );
  }
}
