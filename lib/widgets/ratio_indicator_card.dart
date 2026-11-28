import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme.dart';

class RatioIndicatorCard extends StatelessWidget {
  final BudgetSummary summary;
  final VoidCallback onEditLimit;
  final bool hideAmounts;

  const RatioIndicatorCard({
    super.key,
    required this.summary,
    required this.onEditLimit,
    this.hideAmounts = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ccRatio = summary.creditCardRatio;
    final cashRatio = summary.cashRatio;
    final momChange = summary.monthOverMonthChangePercent;

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Satır: Editoryal Mikro Başlık & Limit Butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'AYLIK TOPLAM HARCAMA',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (summary.previousMonthTotal > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: momChange <= 0 ? AppColors.emeraldMuted : AppColors.crimsonMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${momChange >= 0 ? '+' : ''}${momChange.toStringAsFixed(1)}% MoM',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: momChange <= 0 ? AppColors.emerald : AppColors.crimson,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onEditLimit();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 12, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Limit: ${NumberFormat.compactSimpleCurrency(locale: 'tr_TR', name: '₺').format(summary.monthlyLimit)}',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Büyük Zanaatkar Tutar (RichText ile Parçalı Format)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: summary.grandTotal),
            builder: (context, val, _) {
              if (hideAmounts) {
                return Text(
                  '₺••••',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                );
              }
              final parts = NumberFormat.currency(locale: 'tr_TR', symbol: '').format(val).trim().split(',');
              final integerPart = parts[0];
              final decimalPart = parts.length > 1 ? ',${parts[1]}' : ',00';

              return RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: '₺',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                    TextSpan(
                      text: integerPart,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        color: textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: decimalPart,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // Cerrahi İnce Oran Çubuğu (4dp Yükseklik)
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  if (summary.grandTotal == 0)
                    Expanded(
                      child: Container(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      ),
                    )
                  else ...[
                    Expanded(
                      flex: (ccRatio * 10).round().clamp(0, 1000),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        color: AppColors.iceBlue,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: (cashRatio * 10).round().clamp(0, 1000),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Ferah Dağılım Satırı: Kredi Kartı ve Nakit (Kutulu değil, editoryal satır)
          Row(
            children: [
              // Kredi Kartı
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.iceBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kart (%${ccRatio.toStringAsFixed(0)})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            hideAmounts
                                ? '₺••••'
                                : NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(summary.creditCardTotal),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 24,
                width: 0.8,
                color: borderColor,
              ),
              const SizedBox(width: 12),

              // Nakit Harcama
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nakit (%${cashRatio.toStringAsFixed(0)})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            hideAmounts
                                ? '₺••••'
                                : NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(summary.cashTotal),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Alt Çizgi Ayracı ve Kalan Bütçe Göstergesi
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: summary.remainingBudget >= 0 ? AppColors.emerald : AppColors.crimson,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          summary.remainingBudget >= 0 ? 'Kalan Bütçe' : 'Bütçe Aşımı',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hideAmounts
                      ? '₺••••'
                      : NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(summary.remainingBudget.abs()),
                  style: TextStyle(
                    color: summary.remainingBudget >= 0 ? AppColors.emerald : AppColors.crimson,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
