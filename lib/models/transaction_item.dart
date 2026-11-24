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
  final int installmentCount;
  final bool isRecurring;
  final String? cardName;
  final bool isFavorite;
  final String? receiptPath;
  final List<String> tags; // 1. Etiketleme Sistemi (Örn: #tatil, #is)

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
    this.tags = const [],
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
    List<String>? tags,
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
      tags: tags ?? this.tags,
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
      'tags': tags,
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
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionItem.fromJson(String source) =>
      TransactionItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

// 2. Tasarruf Hedefi Modeli
class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;

  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
  });

  double get progressRatio => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'targetDate': targetDate.toIso8601String(),
  };

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
    id: map['id'] as String,
    title: map['title'] as String,
    targetAmount: (map['targetAmount'] as num).toDouble(),
    currentAmount: (map['currentAmount'] as num).toDouble(),
    targetDate: DateTime.parse(map['targetDate'] as String),
  );

  String toJson() => json.encode(toMap());
  factory SavingsGoal.fromJson(String s) => SavingsGoal.fromMap(json.decode(s));
}

// 3. Kredi Kartı Cüzdan Modeli
class CreditCardInfo {
  final String id;
  final String cardName;
  final String bankName;
  final double cardLimit;
  final int cutOffDay;
  final int paymentDueDay;
  final String colorHex;

  const CreditCardInfo({
    required this.id,
    required this.cardName,
    required this.bankName,
    required this.cardLimit,
    required this.cutOffDay,
    required this.paymentDueDay,
    this.colorHex = '4F46E5',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'cardName': cardName,
    'bankName': bankName,
    'cardLimit': cardLimit,
    'cutOffDay': cutOffDay,
    'paymentDueDay': paymentDueDay,
    'colorHex': colorHex,
  };

  factory CreditCardInfo.fromMap(Map<String, dynamic> map) => CreditCardInfo(
    id: map['id'] as String,
    cardName: map['cardName'] as String,
    bankName: map['bankName'] as String,
    cardLimit: (map['cardLimit'] as num).toDouble(),
    cutOffDay: (map['cutOffDay'] as num).toInt(),
    paymentDueDay: (map['paymentDueDay'] as num).toInt(),
    colorHex: map['colorHex'] as String? ?? '4F46E5',
  );

  String toJson() => json.encode(toMap());
  factory CreditCardInfo.fromJson(String s) => CreditCardInfo.fromMap(json.decode(s));
}

class AppSettings {
  final String currencySymbol;
  final int cutOffDay;
  final double defaultMonthlyLimit;
  final bool enableDailyReminders;
  final bool hideSensitiveAmounts;
  final double budgetAlertThreshold;
  final Map<String, double> categoryBudgets; // 4. Kategori Bazlı Bütçe Limitleri
  final bool compactListView; // 5. Kompakt / Geniş Liste Görünüm Seçeneği

  const AppSettings({
    this.currencySymbol = '₺',
    this.cutOffDay = 1,
    this.defaultMonthlyLimit = 30000.0,
    this.enableDailyReminders = true,
    this.hideSensitiveAmounts = false,
    this.budgetAlertThreshold = 80.0,
    this.categoryBudgets = const {},
    this.compactListView = false,
  });

  Map<String, dynamic> toMap() => {
    'currencySymbol': currencySymbol,
    'cutOffDay': cutOffDay,
    'defaultMonthlyLimit': defaultMonthlyLimit,
    'enableDailyReminders': enableDailyReminders,
    'hideSensitiveAmounts': hideSensitiveAmounts,
    'budgetAlertThreshold': budgetAlertThreshold,
    'categoryBudgets': categoryBudgets,
    'compactListView': compactListView,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    currencySymbol: map['currencySymbol'] as String? ?? '₺',
    cutOffDay: (map['cutOffDay'] as num?)?.toInt() ?? 1,
    defaultMonthlyLimit: (map['defaultMonthlyLimit'] as num?)?.toDouble() ?? 30000.0,
    enableDailyReminders: map['enableDailyReminders'] as bool? ?? true,
    hideSensitiveAmounts: map['hideSensitiveAmounts'] as bool? ?? false,
    budgetAlertThreshold: (map['budgetAlertThreshold'] as num?)?.toDouble() ?? 80.0,
    categoryBudgets: (map['categoryBudgets'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ??
        const {},
    compactListView: map['compactListView'] as bool? ?? false,
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
    Map<String, double>? categoryBudgets,
    bool? compactListView,
  }) {
    return AppSettings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      cutOffDay: cutOffDay ?? this.cutOffDay,
      defaultMonthlyLimit: defaultMonthlyLimit ?? this.defaultMonthlyLimit,
      enableDailyReminders: enableDailyReminders ?? this.enableDailyReminders,
      hideSensitiveAmounts: hideSensitiveAmounts ?? this.hideSensitiveAmounts,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      compactListView: compactListView ?? this.compactListView,
    );
  }
}

class BudgetSummary {
  final double creditCardTotal;
  final double cashTotal;
  final double monthlyLimit;
  final int daysInMonth;
  final int currentDay;
  final double previousMonthTotal; // 6. Geçen Ayla Karşılaştırma Farkı

  const BudgetSummary({
    required this.creditCardTotal,
    required this.cashTotal,
    required this.monthlyLimit,
    this.daysInMonth = 30,
    this.currentDay = 1,
    this.previousMonthTotal = 0.0,
  });

  double get grandTotal => creditCardTotal + cashTotal;

  double get creditCardRatio =>
      grandTotal > 0 ? (creditCardTotal / grandTotal) * 100 : 0.0;

  double get cashRatio =>
      grandTotal > 0 ? (cashTotal / grandTotal) * 100 : 0.0;

  double get remainingBudget => monthlyLimit - grandTotal;

  double get budgetUsageRatio =>
      monthlyLimit > 0 ? (grandTotal / monthlyLimit).clamp(0.0, 1.0) : 0.0;

  double get dailySafeBudget {
    final remainingDays = (daysInMonth - currentDay + 1).clamp(1, 31);
    if (remainingBudget <= 0) return 0.0;
    return remainingBudget / remainingDays;
  }

  double get dailyAverageSpent {
    final passedDays = currentDay.clamp(1, 31);
    return grandTotal / passedDays;
  }

  double get projectedMonthEndTotal => dailyAverageSpent * daysInMonth;

  // 7. Geçen Aya Göre Değişim Oranı (%)
  double get monthOverMonthChangePercent {
    if (previousMonthTotal <= 0) return 0.0;
    return ((grandTotal - previousMonthTotal) / previousMonthTotal) * 100;
  }
}

enum HealthLevel {
  critical,
  warning,
  balanced,
  excellent,
}

class FinancialHealthScore {
  final int score;
  final HealthLevel level;
  final String statusText;
  final String advice;
  final double budgetDisciplineRatio;
  final double savingsScoreRatio;
  final double cardDependencyRatio;

  const FinancialHealthScore({
    required this.score,
    required this.level,
    required this.statusText,
    required this.advice,
    required this.budgetDisciplineRatio,
    required this.savingsScoreRatio,
    required this.cardDependencyRatio,
  });
}
