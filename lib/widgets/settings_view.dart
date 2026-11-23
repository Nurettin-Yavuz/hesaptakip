import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/transaction_controller.dart';

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

          // 1. Kart: Bütçe ve Hesap Kesim Ayarları
          _buildSettingsCard(
            isDark: isDark,
            title: 'Bütçe & Kart Tercihleri',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF4F46E5)),
                title: const Text('Varsayılan Aylık Bütçe'),
                subtitle: Text('Şu anki: ₺${widget.controller.monthlyLimit.toStringAsFixed(0)}'),
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
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined, color: Color(0xFF4F46E5)),
                title: const Text('Kredi Kartı Hesap Kesim Günü'),
                subtitle: const Text('Ekstre döngünüzün başladığı gün (1-30)'),
                trailing: SizedBox(
                  width: 60,
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

          // 2. Kart: Güvenlik ve Gizlilik Modu
          _buildSettingsCard(
            isDark: isDark,
            title: 'Gizlilik ve Görünüm',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.visibility_off_outlined, color: Color(0xFF4F46E5)),
                title: const Text('Gizlilik Modu'),
                subtitle: const Text('Toplu alanlarda harcama tutarlarını gizle (*** ₺)'),
                value: settings.hideSensitiveAmounts,
                onChanged: (val) {
                  widget.controller.updateSettings(
                    settings.copyWith(hideSensitiveAmounts: val),
                  );
                },
              ),
              const Divider(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_active_outlined, color: Color(0xFF4F46E5)),
                title: const Text('Günlük Harcama Hatırlatıcısı'),
                subtitle: const Text('Akşamları günün ödemelerini kaydetmeyi hatırlat'),
                value: settings.enableDailyReminders,
                onChanged: (val) {
                  widget.controller.updateSettings(
                    settings.copyWith(enableDailyReminders: val),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Kart: Veri Yönetimi & Dışa Aktarma (Export CSV / JSON)
          _buildSettingsCard(
            isDark: isDark,
            title: 'Yedekleme ve Dışa Aktarma',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF10B981)),
                title: const Text('Excel / CSV Formatında İndir'),
                subtitle: const Text('Tüm harcamaları tablo olarak kopyala'),
                trailing: const Icon(Icons.copy_rounded, size: 20),
                onTap: () {
                  final csv = widget.controller.exportDataAsCsv();
                  Clipboard.setData(ClipboardData(text: csv));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CSV verisi panoya kopyalandı! Excel\'e yapıştırabilirsiniz.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.code_rounded, color: Color(0xFF38BDF8)),
                title: const Text('JSON Veri Yedeği Al'),
                subtitle: const Text('Tüm proje yedeğini JSON olarak kopyala'),
                trailing: const Icon(Icons.copy_rounded, size: 20),
                onTap: () {
                  final json = widget.controller.exportDataAsJson();
                  Clipboard.setData(ClipboardData(text: json));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('JSON yedeği panoya kopyalandı.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
                title: const Text('Tüm Veritabanını Temizle'),
                subtitle: const Text('Tüm harcamaları sıfırlar'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Veritabanını Sıfırla'),
                      content: const Text('Tüm kayıtlar silinecektir. Devam edilsin mi?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Vazgeç'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            widget.controller.clearAllTransactions();
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Evet, Sil'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 80),
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
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
