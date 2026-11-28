import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_item.dart';

class SettingsView extends StatefulWidget {
  final TransactionController controller;

  const SettingsView({super.key, required this.controller});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _limitController;
  late TextEditingController _cutOffController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.controller.monthlyLimit.toStringAsFixed(0),
    );
    _cutOffController = TextEditingController(
      text: widget.controller.settings.cutOffDay.toString(),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    _cutOffController.dispose();
    super.dispose();
  }

  void _showCategoryBudgetDialog(BuildContext context) {
    final settings = widget.controller.settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: const Text('Kategori Bütçe Kotaları', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: ExpenseCategory.values.map((cat) {
              final currentLimit = settings.categoryBudgets[cat.name] ?? 0.0;
              final ctrl = TextEditingController(
                text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(cat.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          hintText: 'Limitsiz',
                          suffixText: ' ₺',
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          widget.controller.updateCategoryBudget(cat.name, parsed);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final jsonCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: const Text('JSON Yedekten Geri Yükle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Daha önce dışa aktardığınız JSON yedek metnini buraya yapıştırın:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: jsonCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '{"transactions": [...], ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (jsonCtrl.text.trim().isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final success = await widget.controller.restoreDataFromJson(jsonCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Veriler başarıyla geri yüklendi!' : 'Hata: Geçersiz JSON formatı!'),
                  ),
                );
              }
            },
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = widget.controller.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uygulama & Bütçe Ayarları',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Kart: Bütçe ve Kategori Kotaları
          _buildSettingsCard(
            isDark: isDark,
            title: 'Bütçe & Kart Tercihleri',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                title: const Text('Varsayılan Aylık Bütçe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: Text('Şu anki: ₺${widget.controller.monthlyLimit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                trailing: SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      isDense: true,
                      suffixText: ' ₺',
                    ),
                    onSubmitted: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        widget.controller.updateMonthlyLimit(parsed);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bütçe limiti güncellendi.')),
                        );
                      }
                    },
                  ),
                ),
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                title: const Text('Kategori Bütçe Kotaları', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  settings.categoryBudgets.isEmpty
                      ? 'Kategori bazlı limit belirlenmedi'
                      : '${settings.categoryBudgets.length} kategoride limit aktif',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => _showCategoryBudgetDialog(context),
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                title: const Text('Hesap Kesim Günü', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Ekstre döngünüzün başladığı gün', style: TextStyle(fontSize: 11)),
                trailing: SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _cutOffController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '1',
                    ),
                    onSubmitted: (val) {
                      final day = int.tryParse(val) ?? 1;
                      widget.controller.updateSettings(
                        settings.copyWith(cutOffDay: day.clamp(1, 31)),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Kart: Görünüm & Gizlilik Modu
          _buildSettingsCard(
            isDark: isDark,
            title: 'Görünüm ve Gizlilik',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.view_compact_outlined, color: AppColors.primary),
                title: const Text('Kompakt Liste Modu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Harcamaları tek satırlık yoğun liste halinde göster', style: TextStyle(fontSize: 11)),
                value: settings.compactListView,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  widget.controller.updateSettings(settings.copyWith(compactListView: val));
                },
              ),
              const Divider(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.visibility_off_outlined, color: AppColors.primary),
                title: const Text('Gizlilik Modu (Gizli Bakiye)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Toplu alanlarda harcama tutarlarını gizle (₺••••)', style: TextStyle(fontSize: 11)),
                value: settings.hideSensitiveAmounts,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  widget.controller.updateSettings(settings.copyWith(hideSensitiveAmounts: val));
                },
              ),
              const Divider(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                title: const Text('Günlük Hatırlatıcı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Günün harcamalarını kaydetmeyi hatırlat', style: TextStyle(fontSize: 11)),
                value: settings.enableDailyReminders,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  widget.controller.updateSettings(settings.copyWith(enableDailyReminders: val));
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Kart: Yedekleme, Dışa Aktarma ve Demo Veri
          _buildSettingsCard(
            isDark: isDark,
            title: 'Veri & Yedekleme Yönetimi',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF10B981)),
                title: const Text('CSV / Excel Olarak Dışa Aktar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Tüm harcamaları pano ve Excel formatına kopyala', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.copy_rounded, size: 16),
                onTap: () {
                  final csv = widget.controller.exportDataAsCsv();
                  Clipboard.setData(ClipboardData(text: csv));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV verisi panoya kopyalandı! Excel\'e yapıştırabilirsiniz.')),
                  );
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download_rounded, color: Color(0xFF6366F1)),
                title: const Text('JSON Tam Yedek Al', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Harcamalar, kartlar ve hedefleri JSON olarak kopyala', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.copy_rounded, size: 16),
                onTap: () {
                  final jsonStr = widget.controller.exportDataAsJson();
                  Clipboard.setData(ClipboardData(text: jsonStr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tam JSON yedek panoya kopyalandı!')),
                  );
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_rounded, color: Color(0xFF06B6D4)),
                title: const Text('JSON Yedekten Geri Yükle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Daha önce aldığınız yedeği geri yükleyin', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => _showRestoreDialog(context),
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B)),
                title: const Text('Örnek Demo Verileri Yükle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Gerçekçi harcamalar, kartlar ve birikim hedefleri ekle', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.add_task_rounded, size: 16, color: Color(0xFFF59E0B)),
                onTap: () async {
                  await widget.controller.loadDemoData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Örnek demo verileri ve kartlar başarıyla yüklendi!')),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 4. Kart: Tehlikeli Bölge (Sıfırla)
          _buildSettingsCard(
            isDark: isDark,
            title: 'Sıfırlama',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
                title: const Text(
                  'Tüm Verileri Sıfırla',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 13),
                ),
                subtitle: const Text('Tüm harcamaları ve ayarları yerel bellekten temizler', style: TextStyle(fontSize: 11)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      title: const Text('Tüm Verileri Sıfırla', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
                      content: const Text('Tüm kayıtlar silinecektir. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Vazgeç'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            widget.controller.clearAllTransactions();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tüm veriler temizlendi.')),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                          child: const Text('Evet, Sıfırla', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required String title,
    required List<Widget> children,
  }) {
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.iceBlue : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
