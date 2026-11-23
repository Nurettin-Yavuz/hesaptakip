import 'dart:convert';

enum PaymentType {
  creditCard,
  cash;

  String get displayName {
    switch (this) {
      case PaymentType.creditCard:
        return 'Kredi Kartı';
      case PaymentType.cash:
        return 'Nakit';
    }
  }
}

enum ExpenseCategory {
  market('Market / Gıda', 'market', 'shopping_bag_outlined'),
  fatura('Faturalar / Sabit', 'fatura', 'receipt_long_outlined'),
  akaryakit('Ulaşım / Akaryakıt', 'akaryakit', 'local_gas_station_outlined'),
  restoran('Yeme / İçme', 'restoran', 'restaurant_outlined'),
  saglik('Sağlık / İlaç', 'saglik', 'local_hospital_outlined'),
  eglence('Eğlence / Sosyal', 'eglence', 'sports_esports_outlined'),
  giyim('Giyim / Alışveriş', 'giyim', 'checkroom_outlined'),
  egitim('Eğitim / Kitap', 'egitim', 'menu_book_outlined'),
  yatirim('Tasarruf / Yatırım', 'yatirim', 'savings_outlined'),
  diger('Diğer', 'diger', 'more_horiz_outlined');

  final String title;
  final String key;
  final String iconName;
  const ExpenseCategory(this.title, this.key, this.iconName);

  static ExpenseCategory fromKey(String? key) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.key == key,
      orElse: () => ExpenseCategory.diger,
    );
  }
}

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final PaymentType paymentType;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final int installmentCount; // 1: Tek çekim, >1: Taksitli
  final bool isRecurring;     // Düzenli/Aylık sabit ödeme mi?
  final String? cardName;     // Hangi kart veya hesap? (Örn: Bonus, Maximum, Ziraat)
  final bool isFavorite;      // Sık kullanılan şablon harcama
  final String? receiptPath;   // Fiş / Fatura görsel veya dokümanı

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.paymentType,
    required this.category,
    required this.date,
    this.note,
    this.installmentCount = 1,
    this.isRecurring = false,
    this.cardName,
    this.isFavorite = false,
    this.receiptPath,
  });

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    PaymentType? paymentType,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    int? installmentCount,
    bool? isRecurring,
    String? cardName,
    bool? isFavorite,
    String? receiptPath,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paymentType: paymentType ?? this.paymentType,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      installmentCount: installmentCount ?? this.installmentCount,
      isRecurring: isRecurring ?? this.isRecurring,
      cardName: cardName ?? this.cardName,
      isFavorite: isFavorite ?? this.isFavorite,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'paymentType': paymentType.name,
      'category': category.key,
      'date': date.toIso8601String(),
      'note': note,
      'installmentCount': installmentCount,
      'isRecurring': isRecurring,
      'cardName': cardName,
      'isFavorite': isFavorite,
      'receiptPath': receiptPath,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == map['paymentType'],
        orElse: () => PaymentType.cash,
      ),
      category: ExpenseCategory.fromKey(map['category'] as String?),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      installmentCount: (map['installmentCount'] as num?)?.toInt() ?? 1,
      isRecurring: map['isRecurring'] as bool? ?? false,
      cardName: map['cardName'] as String?,
      isFavorite: map['isFavorite'] as bool? ?? false,
      receiptPath: map['receiptPath'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionItem.fromJson(String source) =>
      TransactionItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AppSettings {
  final String currencySymbol;
  final int cutOffDay; // Hesap kesim günü (Örn: ayın 1'i veya 15'i)
  final double defaultMonthlyLimit;
  final bool enableDailyReminders;
  final bool hideSensitiveAmounts; // Gizlilik Modu (Tutarları *** yap)
  final double budgetAlertThreshold; // Bütçe % kaç aşılınca uyarsın? (Örn: %80)

  const AppSettings({
    this.currencySymbol = '₺',
    this.cutOffDay = 1,
    this.defaultMonthlyLimit = 30000.0,
    this.enableDailyReminders = true,
    this.hideSensitiveAmounts = false,
    this.budgetAlertThreshold = 80.0,
  });

  Map<String, dynamic> toMap() => {
    'currencySymbol': currencySymbol,
    'cutOffDay': cutOffDay,
    'defaultMonthlyLimit': defaultMonthlyLimit,
    'enableDailyReminders': enableDailyReminders,
    'hideSensitiveAmounts': hideSensitiveAmounts,
    'budgetAlertThreshold': budgetAlertThreshold,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    currencySymbol: map['currencySymbol'] as String? ?? '₺',
    cutOffDay: (map['cutOffDay'] as num?)?.toInt() ?? 1,
    defaultMonthlyLimit: (map['defaultMonthlyLimit'] as num?)?.toDouble() ?? 30000.0,
    enableDailyReminders: map['enableDailyReminders'] as bool? ?? true,
    hideSensitiveAmounts: map['hideSensitiveAmounts'] as bool? ?? false,
    budgetAlertThreshold: (map['budgetAlertThreshold'] as num?)?.toDouble() ?? 80.0,
  );

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  AppSettings copyWith({
    String? currencySymbol,
    int? cutOffDay,
    double? defaultMonthlyLimit,
    bool? enableDailyReminders,
    bool? hideSensitiveAmounts,
    double? budgetAlertThreshold,
  }) {
    return AppSettings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      cutOffDay: cutOffDay ?? this.cutOffDay,
      defaultMonthlyLimit: defaultMonthlyLimit ?? this.defaultMonthlyLimit,
      enableDailyReminders: enableDailyReminders ?? this.enableDailyReminders,
      hideSensitiveAmounts: hideSensitiveAmounts ?? this.hideSensitiveAmounts,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
    );
  }
}

class BudgetSummary {
  final double creditCardTotal;
  final double cashTotal;
  final double monthlyLimit;
  final int daysInMonth;
  final int currentDay;

  const BudgetSummary({
    required this.creditCardTotal,
    required this.cashTotal,
    required this.monthlyLimit,
    this.daysInMonth = 30,
    this.currentDay = 1,
  });

  double get grandTotal => creditCardTotal + cashTotal;

  double get creditCardRatio =>
      grandTotal > 0 ? (creditCardTotal / grandTotal) * 100 : 0.0;

  double get cashRatio =>
      grandTotal > 0 ? (cashTotal / grandTotal) * 100 : 0.0;

  double get remainingBudget => monthlyLimit - grandTotal;

  double get budgetUsageRatio =>
      monthlyLimit > 0 ? (grandTotal / monthlyLimit).clamp(0.0, 1.0) : 0.0;

  // Günlük Güvenli Harcama Limiti (Kalan Bütçe / Kalan Gün)
  double get dailySafeBudget {
    final remainingDays = (daysInMonth - currentDay + 1).clamp(1, 31);
    if (remainingBudget <= 0) return 0.0;
    return remainingBudget / remainingDays;
  }

  // Günlük Gerçekleşen Ortalama Harcama
  double get dailyAverageSpent {
    final passedDays = currentDay.clamp(1, 31);
    return grandTotal / passedDays;
  }

  // Ay Sonu Tahmini Harcama Projeksiyonu
  double get projectedMonthEndTotal => dailyAverageSpent * daysInMonth;

  // Bütçe Uyarı Seviyesi Kontrolü
  bool isAlertTriggered(double thresholdPercent) {
    if (monthlyLimit <= 0) return false;
    return (grandTotal / monthlyLimit) * 100 >= thresholdPercent;
  }
}
