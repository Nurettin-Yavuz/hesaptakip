import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_item.dart';
import '../services/storage_service.dart';

enum FilterPaymentType { all, creditCard, cash }
enum SortOrder { dateDesc, dateAsc, amountDesc, amountAsc }

class TransactionController extends ChangeNotifier {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<TransactionItem> _transactions = [];
  AppSettings _settings = const AppSettings();
  double _monthlyLimit = 30000.0;
  bool _isLoading = true;

  FilterPaymentType _selectedFilter = FilterPaymentType.all;
  String _searchQuery = '';
  ExpenseCategory? _selectedCategoryFilter;
  SortOrder _currentSortOrder = SortOrder.dateDesc;
  bool _showOnlyRecurring = false;
  bool _showOnlyInstallments = false;

  // Seçili Ay Takibi (Ayın 1'inden son gününe kadar dinamik ay filtresi)
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  TransactionController({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  bool get isLoading => _isLoading;
  AppSettings get settings => _settings;
  double get monthlyLimit => _monthlyLimit;
  FilterPaymentType get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  ExpenseCategory? get selectedCategoryFilter => _selectedCategoryFilter;
  DateTime get selectedMonth => _selectedMonth;
  SortOrder get currentSortOrder => _currentSortOrder;
  bool get showOnlyRecurring => _showOnlyRecurring;
  bool get showOnlyInstallments => _showOnlyInstallments;

  List<TransactionItem> get allTransactions => List.unmodifiable(_transactions);

  // Favori / Hızlı Harcama Şablonları
  List<TransactionItem> get favoriteTemplates {
    return _transactions.where((t) => t.isFavorite).toList();
  }

  // Aktif Taksitli Harcamalar
  List<TransactionItem> get installmentTransactions {
    return currentMonthTransactions.where((t) => t.installmentCount > 1).toList();
  }

  // Sabit / Tekrarlayan Harcamalar
  List<TransactionItem> get recurringTransactions {
    return currentMonthTransactions.where((t) => t.isRecurring).toList();
  }

  // Seçili aya ait harcamalar
  List<TransactionItem> get currentMonthTransactions {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    return _transactions.where((item) {
      return item.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
          item.date.isBefore(endOfMonth.add(const Duration(seconds: 1)));
    }).toList();
  }

  // Filtrelenmiş ve Sıralanmış Harcamalar
  List<TransactionItem> get filteredTransactions {
    var list = currentMonthTransactions.where((item) {
      // 1. Ödeme Türü Filtresi
      final matchesFilter = switch (_selectedFilter) {
        FilterPaymentType.all => true,
        FilterPaymentType.creditCard => item.paymentType == PaymentType.creditCard,
        FilterPaymentType.cash => item.paymentType == PaymentType.cash,
      };
      if (!matchesFilter) return false;

      // 2. Kategori Filtresi
      if (_selectedCategoryFilter != null && item.category != _selectedCategoryFilter) {
        return false;
      }

      // 3. Taksit ve Tekrarlayan filtreleri
      if (_showOnlyRecurring && !item.isRecurring) return false;
      if (_showOnlyInstallments && item.installmentCount <= 1) return false;

      // 4. Arama Sorgusu
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase().trim();
      final titleMatch = item.title.toLowerCase().contains(query);
      final noteMatch = item.note?.toLowerCase().contains(query) ?? false;
      final cardMatch = item.cardName?.toLowerCase().contains(query) ?? false;
      final categoryMatch = item.category.title.toLowerCase().contains(query);

      return titleMatch || noteMatch || cardMatch || categoryMatch;
    }).toList();

    // Sıralama
    switch (_currentSortOrder) {
      case SortOrder.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOrder.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOrder.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOrder.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return list;
  }

  // Bütçe Özeti (Seçili ay için)
  BudgetSummary get summary {
    double ccTotal = 0;
    double cashTotal = 0;

    for (final item in currentMonthTransactions) {
      if (item.paymentType == PaymentType.creditCard) {
        ccTotal += item.amount;
      } else {
        cashTotal += item.amount;
      }
    }

    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentRealMonth = now.year == _selectedMonth.year && now.month == _selectedMonth.month;
    final currentDay = isCurrentRealMonth ? now.day : daysInMonth;

    return BudgetSummary(
      creditCardTotal: ccTotal,
      cashTotal: cashTotal,
      monthlyLimit: _monthlyLimit,
      daysInMonth: daysInMonth,
      currentDay: currentDay,
    );
  }

  // Kategori Dağılımı
  Map<ExpenseCategory, double> get categoryDistribution {
    final map = <ExpenseCategory, double>{};
    for (final item in currentMonthTransactions) {
      map[item.category] = (map[item.category] ?? 0.0) + item.amount;
    }
    return map;
  }

  // Kart / Banka Bazlı Harcama Dağılımı
  Map<String, double> get cardDistribution {
    final map = <String, double>{};
    for (final item in currentMonthTransactions) {
      if (item.paymentType == PaymentType.creditCard) {
        final card = item.cardName?.trim().isNotEmpty == true ? item.cardName!.trim() : 'Diğer Kartlar';
        map[card] = (map[card] ?? 0.0) + item.amount;
      }
    }
    return map;
  }

  // Gün Gün (1'den 30/31'e) Harcama Dağılımı
  Map<int, double> get dailyExpenditureMap {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final map = <int, double>{};
    for (int i = 1; i <= daysInMonth; i++) {
      map[i] = 0.0;
    }
    for (final item in currentMonthTransactions) {
      final day = item.date.day;
      map[day] = (map[day] ?? 0.0) + item.amount;
    }
    return map;
  }

  // Geçmiş Ayların Listesi
  List<DateTime> get availableMonths {
    final set = <String, DateTime>{};
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = '${m.year}-${m.month}';
      set[key] = m;
    }
    for (final item in _transactions) {
      final m = DateTime(item.date.year, item.date.month, 1);
      final key = '${m.year}-${m.month}';
      set[key] = m;
    }
    final list = set.values.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _transactions = await _storageService.loadTransactions();
    _monthlyLimit = await _storageService.loadMonthlyLimit();
    _settings = await _storageService.loadSettings();

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    notifyListeners();
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    notifyListeners();
  }

  void setFilter(FilterPaymentType filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(ExpenseCategory? category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    _currentSortOrder = order;
    notifyListeners();
  }

  void toggleOnlyRecurring() {
    _showOnlyRecurring = !_showOnlyRecurring;
    notifyListeners();
  }

  void toggleOnlyInstallments() {
    _showOnlyInstallments = !_showOnlyInstallments;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _transactions.indexWhere((e) => e.id == id);
    if (index != -1) {
      final current = _transactions[index];
      _transactions[index] = current.copyWith(isFavorite: !current.isFavorite);
      notifyListeners();
      await _storageService.saveTransactions(_transactions);
    }
  }

  Future<void> duplicateTransaction(String id) async {
    final item = _transactions.firstWhere((e) => e.id == id);
    await addTransaction(
      title: '${item.title} (Kopya)',
      amount: item.amount,
      paymentType: item.paymentType,
      category: item.category,
      date: DateTime.now(),
      note: item.note,
      installmentCount: item.installmentCount,
      isRecurring: item.isRecurring,
      cardName: item.cardName,
    );
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required PaymentType paymentType,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
    int installmentCount = 1,
    bool isRecurring = false,
    String? cardName,
    bool isFavorite = false,
  }) async {
    final newItem = TransactionItem(
      id: _uuid.v4(),
      title: title.trim(),
      amount: amount,
      paymentType: paymentType,
      category: category,
      date: date,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      installmentCount: installmentCount,
      isRecurring: isRecurring,
      cardName: cardName?.trim().isEmpty == true ? null : cardName?.trim(),
      isFavorite: isFavorite,
    );

    _transactions.insert(0, newItem);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
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

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _storageService.saveSettings(newSettings);
  }

  // JSON Dışa Aktarma (Export)
  String exportDataAsJson() {
    final map = {
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': _transactions.map((e) => e.toMap()).toList(),
      'monthlyLimit': _monthlyLimit,
      'settings': _settings.toMap(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  // CSV Dışa Aktarma (Excel uyumlu)
  String exportDataAsCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Tarih,Baslik,Tutar,OdemeTuru,Kategori,Taksit,Kart,Sabit,Not');
    for (final item in _transactions) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.date);
      buffer.writeln(
        '"$dateStr","${item.title}",${item.amount},"${item.paymentType.displayName}","${item.category.title}",${item.installmentCount},"${item.cardName ?? ''}","${item.isRecurring ? 'Evet' : 'Hayir'}","${item.note ?? ''}"',
      );
    }
    return buffer.toString();
  }
}
