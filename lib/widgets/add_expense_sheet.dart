import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';

class AddExpenseSheet extends StatefulWidget {
  final TransactionItem? existingItem;
  final List<CreditCardInfo> registeredCards;
  final Function({
    required String title,
    required double amount,
    required PaymentType paymentType,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
    int installmentCount,
    bool isRecurring,
    String? cardName,
    bool isFavorite,
    List<String> tags,
  }) onSave;

  const AddExpenseSheet({
    super.key,
    this.existingItem,
    this.registeredCards = const [],
    required this.onSave,
  });

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _cardNameController;
  late TextEditingController _tagController;

  late PaymentType _paymentType;
  late ExpenseCategory _category;
  late DateTime _selectedDate;
  int _installmentCount = 1;
  bool _isRecurring = false;
  bool _isFavorite = false;
  late List<String> _tags;

  static const List<String> _quickTags = [
    '#market',
    '#ulasim',
    '#ev',
    '#tatil',
    '#is',
    '#yemek',
    '#fatura',
    '#hediye',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _amountController = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: item?.note ?? '');
    _cardNameController = TextEditingController(text: item?.cardName ?? '');
    _tagController = TextEditingController();
    _paymentType = item?.paymentType ?? PaymentType.creditCard;
    _category = item?.category ?? ExpenseCategory.market;
    _selectedDate = item?.date ?? DateTime.now();
    _installmentCount = item?.installmentCount ?? 1;
    _isRecurring = item?.isRecurring ?? false;
    _isFavorite = item?.isFavorite ?? false;
    _tags = List<String>.from(item?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _cardNameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (!mounted) return;
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      } else {
        setState(() {
          _selectedDate = picked;
        });
      }
    }
  }

  void _addTag(String rawTag) {
    var tag = rawTag.trim();
    if (tag.isEmpty) return;
    if (!tag.startsWith('#')) {
      tag = '#$tag';
    }
    if (!_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
    _tagController.clear();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(
            _amountController.text.replaceAll(',', '.').trim(),
          ) ??
          0.0;

      widget.onSave(
        title: _titleController.text.trim(),
        amount: amount,
        paymentType: _paymentType,
        category: _category,
        date: _selectedDate,
        note: _noteController.text.trim(),
        installmentCount: _installmentCount,
        isRecurring: _isRecurring,
        cardName: _cardNameController.text.trim(),
        isFavorite: _isFavorite,
        tags: _tags,
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Harcamayı Güncelle' : 'Yeni Harcama Ekle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ödeme Türü Seçimi: Kredi Kartı & Nakit
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _paymentType = PaymentType.creditCard),
                      icon: const Icon(Icons.credit_card_rounded, size: 17),
                      label: const Text('Kredi Kartı', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _paymentType == PaymentType.creditCard
                            ? const Color(0xFF4F46E5)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        foregroundColor: _paymentType == PaymentType.creditCard
                            ? Colors.white
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _paymentType = PaymentType.cash),
                      icon: const Icon(Icons.payments_rounded, size: 17),
                      label: const Text('Nakit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _paymentType == PaymentType.cash
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        foregroundColor: _paymentType == PaymentType.cash
                            ? Colors.white
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Harcama Başlığı
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Harcama Başlığı',
                  hintText: 'Örn: Migros Market, Shell Benzin',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 19),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen bir başlık giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Tutar Alanı
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tutar (₺)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.currency_lira_rounded, size: 19),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen tutar giriniz';
                  }
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Geçerli bir pozitif tutar giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Kategori Seçici
              DropdownButtonFormField<ExpenseCategory>(
                value: _category,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category_outlined, size: 19),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: ExpenseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat.title,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),

              // Kredi Kartı Detayları (Banka ve Taksit)
              if (_paymentType == PaymentType.creditCard) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: widget.registeredCards.isNotEmpty
                          ? DropdownButtonFormField<String>(
                              value: widget.registeredCards.any((c) => c.cardName == _cardNameController.text)
                                  ? _cardNameController.text
                                  : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Kayıtlı Kart',
                                prefixIcon: const Icon(Icons.credit_card, size: 17),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              hint: const Text('Kart Seçin', style: TextStyle(fontSize: 12)),
                              items: widget.registeredCards.map((card) {
                                return DropdownMenuItem(
                                  value: card.cardName,
                                  child: Text(card.cardName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _cardNameController.text = val);
                              },
                            )
                          : TextFormField(
                              controller: _cardNameController,
                              decoration: InputDecoration(
                                labelText: 'Banka / Kart',
                                hintText: 'Örn: Garanti Bonus',
                                prefixIcon: const Icon(Icons.credit_card, size: 17),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _installmentCount,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Taksit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        items: [1, 2, 3, 4, 6, 9, 12].map((count) {
                          return DropdownMenuItem(
                            value: count,
                            child: Text(
                              count == 1 ? 'Tek Çekim' : '$count Taksit',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _installmentCount = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Tarih Seçici
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'İşlem Tarihi',
                    prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
                  ),
                  child: Text(
                    dateFormat.format(_selectedDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Etiket Sistemi (#Tags)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        labelText: 'Etiket Ekle (#tatil, #iş)',
                        hintText: '#etiket',
                        prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () => _addTag(_tagController.text),
                        ),
                      ),
                      onSubmitted: _addTag,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Hızlı Etiket Önerileri
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _quickTags.map((tag) {
                  final isSelected = _tags.contains(tag);
                  return FilterChip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _tags.add(tag);
                        } else {
                          _tags.remove(tag);
                        }
                      });
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Düzenli/Aylık Sabit Ödeme Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Düzenli / Sabit Ödeme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Abonelik veya kira gibi her ay yinelenen gider', style: TextStyle(fontSize: 11)),
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),

              // Sık Kullanılan Harcama Şablonu (Favori) Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hızlı Şablon / Favorilere Ekle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Ana sayfada tek tıkla yeniden oluşturmak için sakla', style: TextStyle(fontSize: 11)),
                value: _isFavorite,
                onChanged: (val) => setState(() => _isFavorite = val),
              ),
              const SizedBox(height: 8),

              // Not Alanı
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Ek Not (Opsiyonel)',
                  hintText: 'Açıklama veya fiş notu...',
                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),

              // Kaydet Butonu
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isEditing ? 'Değişiklikleri Kaydet' : 'Harcamayı Ekle',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
