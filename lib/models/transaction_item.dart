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
  market('Market / Gıda', 'market'),
  fatura('Faturalar / Sabit', 'fatura'),
  akaryakit('Ulaşım / Akaryakıt', 'akaryakit'),
  restoran('Yeme / İçme', 'restoran'),
  saglik('Sağlık / İlaç', 'saglik'),
  eglence('Eğlence / Sosyal', 'eglence'),
  giyim('Giyim / Alışveriş', 'giyim'),
  diger('Diğer', 'diger');

  final String title;
  final String key;
  const ExpenseCategory(this.title, this.key);

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

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.paymentType,
    required this.category,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'paymentType': paymentType.name,
      'category': category.key,
      'date': date.toIso8601String(),
      'note': note,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionItem.fromJson(String source) =>
      TransactionItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

class BudgetSummary {
  final double creditCardTotal;
  final double cashTotal;
  final double monthlyLimit;

  const BudgetSummary({
    required this.creditCardTotal,
    required this.cashTotal,
    required this.monthlyLimit,
  });

  double get grandTotal => creditCardTotal + cashTotal;

  double get creditCardRatio =>
      grandTotal > 0 ? (creditCardTotal / grandTotal) * 100 : 0.0;

  double get cashRatio =>
      grandTotal > 0 ? (cashTotal / grandTotal) * 100 : 0.0;

  double get remainingBudget => monthlyLimit - grandTotal;

  double get budgetUsageRatio =>
      monthlyLimit > 0 ? (grandTotal / monthlyLimit).clamp(0.0, 1.0) : 0.0;
}
