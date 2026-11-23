import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_item.dart';
import '../services/storage_service.dart';

enum FilterPaymentType { all, creditCard, cash }

class TransactionController extends ChangeNotifier {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<TransactionItem> _transactions = [];
  double _monthlyLimit = 30000.0;
  bool _isLoading = true;
  FilterPaymentType _selectedFilter = FilterPaymentType.all;
  String _searchQuery = '';

  TransactionController({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  bool get isLoading => _isLoading;
  double get monthlyLimit => _monthlyLimit;
  FilterPaymentType get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  List<TransactionItem> get allTransactions => List.unmodifiable(_transactions);

  List<TransactionItem> get filteredTransactions {
    return _transactions.where((item) {
      final matchesFilter = switch (_selectedFilter) {
        FilterPaymentType.all => true,
        FilterPaymentType.creditCard =>
          item.paymentType == PaymentType.creditCard,
        FilterPaymentType.cash => item.paymentType == PaymentType.cash,
      };

      if (!matchesFilter) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase().trim();
      final titleMatch = item.title.toLowerCase().contains(query);
      final noteMatch = item.note?.toLowerCase().contains(query) ?? false;
      final categoryMatch = item.category.title.toLowerCase().contains(query);

      return titleMatch || noteMatch || categoryMatch;
    }).toList();
  }

  BudgetSummary get summary {
    double ccTotal = 0;
    double cashTotal = 0;

    for (final item in _transactions) {
      if (item.paymentType == PaymentType.creditCard) {
        ccTotal += item.amount;
      } else {
        cashTotal += item.amount;
      }
    }

    return BudgetSummary(
      creditCardTotal: ccTotal,
      cashTotal: cashTotal,
      monthlyLimit: _monthlyLimit,
    );
  }

  Map<ExpenseCategory, double> get categoryDistribution {
    final map = <ExpenseCategory, double>{};
    for (final item in _transactions) {
      map[item.category] = (map[item.category] ?? 0.0) + item.amount;
    }
    return map;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _transactions = await _storageService.loadTransactions();
    _monthlyLimit = await _storageService.loadMonthlyLimit();
    _isLoading = false;
    notifyListeners();
  }

  void setFilter(FilterPaymentType filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required PaymentType paymentType,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  }) async {
    final newItem = TransactionItem(
      id: _uuid.v4(),
      title: title.trim(),
      amount: amount,
      paymentType: paymentType,
      category: category,
      date: date,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );

    _transactions.insert(0, newItem);
    notifyListeners();
    await _storageService.saveTransactions(_transactions);
  }

  Future<void> updateTransaction(TransactionItem updatedItem) async {
    final index = _transactions.indexWhere((e) => e.id == updatedItem.id);
    if (index != -1) {
      _transactions[index] = updatedItem;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      await _storageService.saveTransactions(_transactions);
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((e) => e.id == id);
    notifyListeners();
    await _storageService.saveTransactions(_transactions);
  }

  Future<void> clearAllTransactions() async {
    _transactions.clear();
    notifyListeners();
    await _storageService.clearAllData();
  }

  Future<void> updateMonthlyLimit(double newLimit) async {
    _monthlyLimit = newLimit;
    notifyListeners();
    await _storageService.saveMonthlyLimit(newLimit);
  }
}
