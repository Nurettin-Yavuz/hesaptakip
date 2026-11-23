import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';

class StorageService {
  static const String _transactionsKey = 'app_transactions_list';
  static const String _monthlyLimitKey = 'app_monthly_budget_limit';

  Future<List<TransactionItem>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_transactionsKey);
    if (jsonList == null || jsonList.isEmpty) {
      return _getInitialMockData();
    }

    try {
      return jsonList
          .map((item) => TransactionItem.fromJson(item))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return _getInitialMockData();
    }
  }

  Future<void> saveTransactions(List<TransactionItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => item.toJson()).toList();
    await prefs.setStringList(_transactionsKey, jsonList);
  }

  Future<double> loadMonthlyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_monthlyLimitKey) ?? 35000.0;
  }

  Future<void> saveMonthlyLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monthlyLimitKey, limit);
  }

  List<TransactionItem> _getInitialMockData() {
    final now = DateTime.now();
    return [
      TransactionItem(
        id: '1',
        title: 'Migros Market',
        amount: 2450.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.market,
        date: now.subtract(const Duration(hours: 4)),
        note: 'Haftalık mutfak alışverişi',
      ),
      TransactionItem(
        id: '2',
        title: 'Shell Petrol',
        amount: 1750.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.akaryakit,
        date: now.subtract(const Duration(days: 1, hours: 2)),
        note: 'Yakıt ikmali',
      ),
      TransactionItem(
        id: '3',
        title: 'Semt Pazarı',
        amount: 850.0,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.market,
        date: now.subtract(const Duration(days: 2)),
        note: 'Meyve sebze',
      ),
      TransactionItem(
        id: '4',
        title: 'Elektrik & Doğalgaz',
        amount: 3200.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.fatura,
        date: now.subtract(const Duration(days: 3)),
        note: 'Kış faturası',
      ),
      TransactionItem(
        id: '5',
        title: 'Taksi ve Otopark',
        amount: 450.0,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.akaryakit,
        date: now.subtract(const Duration(days: 4)),
        note: 'Şehir içi ulaşım',
      ),
      TransactionItem(
        id: '6',
        title: 'Eczane & Vitamin',
        amount: 620.0,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.saglik,
        date: now.subtract(const Duration(days: 5)),
        note: 'Rutin sağlık',
      ),
      TransactionItem(
        id: '7',
        title: 'Akşam Yemeği',
        amount: 1950.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.restoran,
        date: now.subtract(const Duration(days: 6)),
        note: 'Dışarıda aile yemeği',
      ),
    ];
  }
}
