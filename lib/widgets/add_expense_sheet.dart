import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';

class AddExpenseSheet extends StatefulWidget {
  final TransactionItem? existingItem;
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
  }) onSave;

  const AddExpenseSheet({
    super.key,
    this.existingItem,
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

  late PaymentType _paymentType;
  late ExpenseCategory _category;
  late DateTime _selectedDate;
  int _installmentCount = 1;
  bool _isRecurring = false;

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
    _paymentType = item?.paymentType ?? PaymentType.creditCard;
    _category = item?.category ?? ExpenseCategory.market;
    _selectedDate = item?.date ?? DateTime.now();
    _installmentCount = item?.installmentCount ?? 1;
    _isRecurring = item?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _cardNameController.dispose();
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ödeme Türü Seçici
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _paymentType = PaymentType.creditCard),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _paymentType == PaymentType.creditCard
                              ? const Color(0xFF4F46E5)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card_rounded,
                              size: 16,
                              color: _paymentType == PaymentType.creditCard
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Kredi Kartı',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: _paymentType == PaymentType.creditCard
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _paymentType = PaymentType.cash),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _paymentType == PaymentType.cash
                              ? const Color(0xFF059669)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 16,
                              color: _paymentType == PaymentType.cash
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Nakit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: _paymentType == PaymentType.cash
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Harcama Adı
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Harcama Başlığı',
                  hintText: 'Örn: Market, Kira, Akaryakıt',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen bir başlık giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Tutar Girişi
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tutar (₺)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.currency_lira_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen bir tutar giriniz';
                  }
                  final parsed = double.tryParse(val.replaceAll(',', '.').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Geçerli bir pozitif tutar giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Kategori Seçimi (isExpanded: true ile taşma önlenir)
              DropdownButtonFormField<ExpenseCategory>(
                value: _category,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: ExpenseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),

              // Kredi Kartı Ek Bilgileri (Banka/Kart ve Taksit)
              if (_paymentType == PaymentType.creditCard) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _cardNameController,
                        decoration: InputDecoration(
                          labelText: 'Banka / Kart',
                          hintText: 'Bonus, Axess...',
                          prefixIcon: const Icon(Icons.credit_card_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _installmentCount,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Taksit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                        ),
                        items: [1, 2, 3, 4, 6, 9, 12].map((count) {
                          return DropdownMenuItem(
                            value: count,
                            child: Text(
                              count == 1 ? 'Tek' : '$count Taksit',
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? const Color(0xFF475569) : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dateFormat.format(_selectedDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Düzenli Sabit Ödeme Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Düzenli / Sabit Ödeme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Kira veya abonelik gibi her ay tekrarlanır', style: TextStyle(fontSize: 11)),
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),

              // Not Girişi
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Ek Not (Opsiyonel)',
                  hintText: 'Detay veya açıklama',
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),

              // Kaydet Butonu
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Değişiklikleri Kaydet' : 'Harcamayı Ekle',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
