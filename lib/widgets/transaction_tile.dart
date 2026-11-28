import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatefulWidget {
  final TransactionItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleFavorite;
  final bool isCompact;
  final bool hideAmounts;
  final int index;

  const TransactionTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleFavorite,
    this.isCompact = false,
    this.hideAmounts = false,
    this.index = 0,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isCompact = widget.isCompact;
    final hideAmounts = widget.hideAmounts;
    final dateFormat = DateFormat('d MMM, HH:mm', 'tr_TR');
    final isCreditCard = item.paymentType == PaymentType.creditCard;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // Staggered giris animasyon suresi (her eleman sirali kayarak gelir)
    final staggeredDuration = Duration(milliseconds: 220 + (widget.index.clamp(0, 8) * 35));

    return TweenAnimationBuilder<double>(
      duration: staggeredDuration,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animVal, child) {
        return Opacity(
          opacity: animVal,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - animVal)),
            child: child,
          ),
        );
      },
      child: RepaintBoundary(
        child: Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.crimson,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor, width: 0.8),
                ),
                title: Text(
                  'Harcamayı Sil',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.4,
                  ),
                ),
                content: Text(
                  '"${item.title}" kaydını silmek istediğinizden emin misiniz?',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx, false);
                    },
                    child: Text('Vazgeç', style: TextStyle(color: textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            HapticFeedback.mediumImpact();
            widget.onDelete();
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Material(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onTap();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: isCompact ? 9 : 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 0.7,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Mikro Durum Gostergesi
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isCreditCard ? AppColors.iceBlueMuted : AppColors.emeraldMuted,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            isCreditCard ? Icons.credit_card_rounded : Icons.payments_rounded,
                            color: isCreditCard ? AppColors.iceBlue : AppColors.emerald,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Baslik, Kategori ve Tarih
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: isCompact ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.isRecurring) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.autorenew_rounded, size: 13, color: AppColors.amber),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    item.category.title,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                  Text(
                                    ' • ',
                                    style: TextStyle(fontSize: 10, color: textMuted),
                                  ),
                                  Text(
                                    dateFormat.format(item.date),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textMuted,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  if (item.installmentCount > 1) ...[
                                    Text(
                                      ' • ',
                                      style: TextStyle(fontSize: 10, color: textMuted),
                                    ),
                                    Text(
                                      '${item.installmentCount} Taksit',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.iceBlue,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (!isCompact && item.tags.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: item.tags.take(3).map((tag) {
                                    return Text(
                                      tag.startsWith('#') ? tag : '#$tag',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w500,
                                        color: textMuted,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Tutar (Tabular) ve Hizli Islemler
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAmountText(textPrimary, textMuted, item, isCompact, hideAmounts),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: borderColor, width: 0.5),
                                  ),
                                  child: Text(
                                    item.cardName?.isNotEmpty == true
                                        ? item.cardName!
                                        : item.paymentType.displayName,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    widget.onToggleFavorite();
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Icon(
                                    item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                                    size: 14,
                                    color: item.isFavorite ? AppColors.amber : textMuted,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    widget.onDuplicate();
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 13,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountText(
    Color textPrimary,
    Color textMuted,
    TransactionItem item,
    bool isCompact,
    bool hideAmounts,
  ) {
    if (hideAmounts) {
      return Text(
        '₺••••',
        style: TextStyle(
          fontSize: isCompact ? 13 : 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      );
    }

    final formatted = NumberFormat.currency(locale: 'tr_TR', symbol: '').format(item.amount).trim();
    final parts = formatted.split(',');
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
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: textMuted,
            ),
          ),
          TextSpan(
            text: integerPart,
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: textPrimary,
            ),
          ),
          TextSpan(
            text: decimalPart,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
