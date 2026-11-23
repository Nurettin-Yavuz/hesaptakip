import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_item.dart';
import '../services/storage_service.dart';

enum FilterPaymentType { all, creditCard, cash }
enum SortOrder { dateDesc, dateAsc, amountDesc, amountAsc, titleAsc }

class TransactionController extends ChangeNotifier {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<TransactionItem> _transactions = [];
  List<SavingsGoal> _savingsGoals = [];
  List<CreditCardInfo> _creditCards = [];
  AppSettings _settings = const AppSettings();
  double _monthlyLimit = 30000.0;
  bool _isLoading = true;

  FilterPaymentType _selectedFilter = FilterPaymentType.all;
  String _searchQuery = '';
  ExpenseCategory? _selectedCategoryFilter;
  SortOrder _currentSortOrder = SortOrder.dateDesc;
  bool _showOnlyRecurring = false;
  bool _showOnlyInstallments = false;
  int? _selectedDayFilter;
  String? _selectedTagFilter;

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
  int? get selectedDayFilter => _selectedDayFilter;
  String? get selectedTagFilter => _selectedTagFilter;

  List<TransactionItem> get allTransactions => List.unmodifiable(_transactions);
  List<SavingsGoal> get savingsGoals => List.unmodifiable(_savingsGoals);
  List<CreditCardInfo> get creditCards => List.unmodifiable(_creditCards);

  // Favori / Hızlı Harcama Şablonları
  List<TransactionItem> get favoriteTemplates {
    return _transactions.where((t) => t.isFavorite).toList();
  }

  // Aktif Taksitli Harcamalar
  List<TransactionItem> get installmentTransactions {
    return currentMonthTransactions.where((t) => t.installmentCount > 1).toList();
  }

  // Toplam Taksit Yükü (Seçili ay)
  double get installmentMonthlyTotal {
    return installmentTransactions.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Sabit / Tekrarlayan Harcamalar
  List<TransactionItem> get recurringTransactions {
    return currentMonthTransactions.where((t) => t.isRecurring).toList();
  }

  // Sabit Giderler Toplamı (Kira, abonelik vb.)
  double get recurringMonthlyTotal {
    return recurringTransactions.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Tüm Benzersiz Etiketler
  List<String> get availableTags {
    final set = <String>{};
    for (final t in _transactions) {
      set.addAll(t.tags);
    }
    return set.toList()..sort();
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

  // Bir önceki aya ait harcamalar (MoM kıyaslaması için)
  List<TransactionItem> get previousMonthTransactions {
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    final startOfPrevMonth = DateTime(prevMonth.year, prevMonth.month, 1);
    final endOfPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0, 23, 59, 59);

    return _transactions.where((item) {
      return item.date.isAfter(startOfPrevMonth.subtract(const Duration(seconds: 1))) &&
          item.date.isBefore(endOfPrevMonth.add(const Duration(seconds: 1)));
    }).toList();
  }

  double get previousMonthTotal {
    return previousMonthTransactions.fold(0.0, (sum, item) => sum + item.amount);
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

      // 3. Günlük Filtre (1'den 30'a tıklanan gün)
      if (_selectedDayFilter != null && item.date.day != _selectedDayFilter) {
        return false;
      }

      // 4. Etiket Filtresi
      if (_selectedTagFilter != null && !item.tags.contains(_selectedTagFilter)) {
        return false;
      }

      // 5. Taksit ve Tekrarlayan filtreleri
      if (_showOnlyRecurring && !item.isRecurring) return false;
      if (_showOnlyInstallments && item.installmentCount <= 1) return false;

      // 6. Çoklu Arama Sorgusu (Başlık, Not, Kart Adı, Kategori ve Etiketler)
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase().trim();
      final titleMatch = item.title.toLowerCase().contains(query);
      final noteMatch = item.note?.toLowerCase().contains(query) ?? false;
      final cardMatch = item.cardName?.toLowerCase().contains(query) ?? false;
      final categoryMatch = item.category.title.toLowerCase().contains(query);
      final tagMatch = item.tags.any((t) => t.toLowerCase().contains(query));

      return titleMatch || noteMatch || cardMatch || categoryMatch || tagMatch;
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
      case SortOrder.titleAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return list;
  }

  // Bütçe Özeti (Seçili ay için, MoM karşılaştırması dahil)
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
      previousMonthTotal: previousMonthTotal,
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

  // Harcama Şampiyonu Kategori (En çok harcanan kategori)
  MapEntry<ExpenseCategory, double>? get topExpenseCategory {
    final map = categoryDistribution;
    if (map.isEmpty) return null;
    var sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }

  // Ayın En Yüksek Tekil Harcaması (Peak Expense)
  TransactionItem? get peakExpense {
    if (currentMonthTransactions.isEmpty) return null;
    var sorted = List<TransactionItem>.from(currentMonthTransactions)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return sorted.first;
  }

  // Bu Haftanın Harcamaları ve Ortalaması
  double get thisWeekTotal {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return currentMonthTransactions
        .where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1))))
        .fold(0.0, (sum, item) => sum + item.amount);
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

  // Kredi Kartı Limit ve Doluluk Hesaplama (Her kart için)
  double getSpentAmountForCard(String cardName) {
    return currentMonthTransactions
        .where((t) => t.paymentType == PaymentType.creditCard && t.cardName == cardName)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Akıllı Finansal Koçluk Tavsiyesi
  String get financialAdvice {
    final s = summary;
    if (s.monthlyLimit <= 0) return 'Bütçe limiti belirleyerek akıllı finansal hedeflerinizi yönetin.';
    final ratio = s.budgetUsageRatio;
    final change = s.monthOverMonthChangePercent;

    if (ratio >= 1.0) {
      return 'Bütçe limitiniz aşıldı! Ayın geri kalanında zorunlu olmayan tüm kredi kartı ve nakit harcamalarınızı durdurmanız önerilir.';
    } else if (ratio >= (settings.budgetAlertThreshold / 100)) {
      return 'Dikkat: Aylık bütçenizin %${settings.budgetAlertThreshold.toStringAsFixed(0)} kadarı harcandı. Günlük güvenli tavan: ₺${s.dailySafeBudget.toStringAsFixed(0)}.';
    } else if (change > 20 && s.previousMonthTotal > 0) {
      return 'Harcama temponuz geçen aya göre %${change.toStringAsFixed(0)} daha yüksek seyrediyor. Kategori bazlı kısıtlamaları inceleyin.';
    } else if (ratio <= 0.4 && s.currentDay > 15) {
      return 'Mükemmel tasarruf performansı! Bu tempoda devam ederseniz bütçenizin önemli kısmını tasarruf hedeflerinize aktarabilirsiniz.';
    } else {
      return 'Harcamalarınız dengeli ilerliyor. Günlük güvenli limit dahilinde kalarak ayı başarıyla tamamlayabilirsiniz.';
    }
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
    _savingsGoals = await _storageService.loadSavingsGoals();
    _creditCards = await _storageService.loadCreditCards();

    // İlk açılışta varsayılan kartlar yoksa örnek 2 popüler kart ekle
    if (_creditCards.isEmpty) {
      _creditCards = [
        const CreditCardInfo(
          id: 'card-1',
          cardName: 'Bonus Platinum',
          bankName: 'Garanti BBVA',
          cardLimit: 50000.0,
          cutOffDay: 15,
          paymentDueDay: 25,
          colorHex: '10B981',
        ),
        const CreditCardInfo(
          id: 'card-2',
          cardName: 'World Eko',
          bankName: 'Yapı Kredi',
          cardLimit: 35000.0,
          cutOffDay: 1,
          paymentDueDay: 10,
          colorHex: '4F46E5',
        ),
      ];
      await _storageService.saveCreditCards(_creditCards);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _selectedDayFilter = null;
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    _selectedDayFilter = null;
    notifyListeners();
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    _selectedDayFilter = null;
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

  void setSelectedDayFilter(int? day) {
    if (_selectedDayFilter == day) {
      _selectedDayFilter = null;
    } else {
      _selectedDayFilter = day;
    }
    notifyListeners();
  }

  void setSelectedTagFilter(String? tag) {
    if (_selectedTagFilter == tag) {
      _selectedTagFilter = null;
    } else {
      _selectedTagFilter = tag;
    }
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
      tags: List.from(item.tags),
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
    List<String> tags = const [],
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
      tags: tags,
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

  // Tasarruf Hedefleri Yönetimi (Kumbaram)
  Future<void> addSavingsGoal({
    required String title,
    required double targetAmount,
    required DateTime targetDate,
    double initialAmount = 0.0,
  }) async {
    final goal = SavingsGoal(
      id: _uuid.v4(),
      title: title.trim(),
      targetAmount: targetAmount,
      currentAmount: initialAmount,
      targetDate: targetDate,
    );
    _savingsGoals.add(goal);
    notifyListeners();
    await _storageService.saveSavingsGoals(_savingsGoals);
  }

  Future<void> depositToSavingsGoal(String goalId, double depositAmount) async {
    final index = _savingsGoals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final current = _savingsGoals[index];
      _savingsGoals[index] = SavingsGoal(
        id: current.id,
        title: current.title,
        targetAmount: current.targetAmount,
        currentAmount: current.currentAmount + depositAmount,
        targetDate: current.targetDate,
      );
      notifyListeners();
      await _storageService.saveSavingsGoals(_savingsGoals);
    }
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    _savingsGoals.removeWhere((g) => g.id == goalId);
    notifyListeners();
    await _storageService.saveSavingsGoals(_savingsGoals);
  }

  // Kredi Kartı Cüzdanı Yönetimi
  Future<void> addCreditCard({
    required String cardName,
    required String bankName,
    required double cardLimit,
    required int cutOffDay,
    required int paymentDueDay,
    String colorHex = '4F46E5',
  }) async {
    final card = CreditCardInfo(
      id: _uuid.v4(),
      cardName: cardName.trim(),
      bankName: bankName.trim(),
      cardLimit: cardLimit,
      cutOffDay: cutOffDay,
      paymentDueDay: paymentDueDay,
      colorHex: colorHex,
    );
    _creditCards.add(card);
    notifyListeners();
    await _storageService.saveCreditCards(_creditCards);
  }

  Future<void> deleteCreditCard(String cardId) async {
    _creditCards.removeWhere((c) => c.id == cardId);
    notifyListeners();
    await _storageService.saveCreditCards(_creditCards);
  }

  Future<void> updateCategoryBudget(String categoryName, double budget) async {
    final updatedMap = Map<String, double>.from(_settings.categoryBudgets);
    if (budget <= 0) {
      updatedMap.remove(categoryName);
    } else {
      updatedMap[categoryName] = budget;
    }
    final newSettings = _settings.copyWith(categoryBudgets: updatedMap);
    await updateSettings(newSettings);
  }

  Future<void> toggleCompactView() async {
    final newSettings = _settings.copyWith(compactListView: !_settings.compactListView);
    await updateSettings(newSettings);
  }

  Future<void> clearAllTransactions() async {
    _transactions.clear();
    _savingsGoals.clear();
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
      'creditCards': _creditCards.map((e) => e.toMap()).toList(),
      'savingsGoals': _savingsGoals.map((e) => e.toMap()).toList(),
      'monthlyLimit': _monthlyLimit,
      'settings': _settings.toMap(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  // JSON Geri Yükleme (Restore)
  Future<bool> restoreDataFromJson(String jsonSource) async {
    try {
      final map = json.decode(jsonSource) as Map<String, dynamic>;
      if (map.containsKey('transactions')) {
        final rawTx = map['transactions'] as List<dynamic>;
        _transactions = rawTx.map((e) => TransactionItem.fromMap(e as Map<String, dynamic>)).toList();
        await _storageService.saveTransactions(_transactions);
      }
      if (map.containsKey('creditCards')) {
        final rawCards = map['creditCards'] as List<dynamic>;
        _creditCards = rawCards.map((e) => CreditCardInfo.fromMap(e as Map<String, dynamic>)).toList();
        await _storageService.saveCreditCards(_creditCards);
      }
      if (map.containsKey('savingsGoals')) {
        final rawGoals = map['savingsGoals'] as List<dynamic>;
        _savingsGoals = rawGoals.map((e) => SavingsGoal.fromMap(e as Map<String, dynamic>)).toList();
        await _storageService.saveSavingsGoals(_savingsGoals);
      }
      if (map.containsKey('monthlyLimit')) {
        _monthlyLimit = (map['monthlyLimit'] as num).toDouble();
        await _storageService.saveMonthlyLimit(_monthlyLimit);
      }
      if (map.containsKey('settings')) {
        _settings = AppSettings.fromMap(map['settings'] as Map<String, dynamic>);
        await _storageService.saveSettings(_settings);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Demo Veri Yükleme (Tek tıkla zengin demo veri)
  Future<void> loadDemoData() async {
    final now = DateTime.now();
    _transactions = [
      TransactionItem(
        id: _uuid.v4(),
        title: 'Migros Süpermarket',
        amount: 2450.00,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.market,
        date: DateTime(now.year, now.month, (now.day - 1).clamp(1, 28), 14, 30),
        note: 'Haftalık mutfak ve deterjan alışverişi',
        cardName: 'Bonus Platinum',
        tags: ['#mutfak', '#ev'],
        isFavorite: true,
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Shell Akaryakıt',
        amount: 1750.00,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.akaryakit,
        date: DateTime(now.year, now.month, (now.day - 2).clamp(1, 28), 18, 15),
        note: 'Dolu depo benzin alımı',
        cardName: 'Bonus Platinum',
        tags: ['#araba', '#ulasim'],
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Semt Pazarı & Şarküteri',
        amount: 850.00,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.market,
        date: DateTime(now.year, now.month, (now.day - 3).clamp(1, 28), 11, 45),
        note: 'Taze sebze ve peynir alımı',
        tags: ['#pazar', '#nakit'],
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Ev Kirası & Aidat',
        amount: 12500.00,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.fatura,
        date: DateTime(now.year, now.month, 1, 09, 00),
        note: 'Aylık kira transferi',
        isRecurring: true,
        tags: ['#sabit', '#kira'],
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Dyson Süpürge (3 Taksit)',
        amount: 3200.00,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.giyim,
        date: DateTime(now.year, now.month, (now.day - 5).clamp(1, 28), 16, 20),
        note: 'Taksit 1/3',
        installmentCount: 3,
        cardName: 'World Eko',
        tags: ['#elektronik', '#taksit'],
      ),
      TransactionItem(
        id: _uuid.v4(),
        title: 'Netflix & Spotify',
        amount: 299.90,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.eglence,
        date: DateTime(now.year, now.month, 5, 10, 00),
        note: 'Aylık dijital abonelikler',
        isRecurring: true,
        cardName: 'Bonus Platinum',
        tags: ['#dijital', '#abonelik'],
      ),
    ];

    _savingsGoals = [
      SavingsGoal(
        id: 'goal-1',
        title: 'Yaz Tatili Fonu',
        targetAmount: 40000.0,
        currentAmount: 18500.0,
        targetDate: DateTime(now.year, 7, 1),
      ),
      SavingsGoal(
        id: 'goal-2',
        title: 'Acil Durum Kumbarası',
        targetAmount: 50000.0,
        currentAmount: 32000.0,
        targetDate: DateTime(now.year, 12, 31),
      ),
    ];

    notifyListeners();
    await _storageService.saveTransactions(_transactions);
    await _storageService.saveSavingsGoals(_savingsGoals);
  }

  // CSV Dışa Aktarma (Excel uyumlu)
  String exportDataAsCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Tarih,Baslik,Tutar,OdemeTuru,Kategori,Taksit,Kart,Sabit,Etiketler,Not');
    for (final item in _transactions) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.date);
      final tagStr = item.tags.join(' ');
      buffer.writeln(
        '"$dateStr","${item.title}",${item.amount},"${item.paymentType.displayName}","${item.category.title}",${item.installmentCount},"${item.cardName ?? ''}","${item.isRecurring ? 'Evet' : 'Hayir'}","$tagStr","${item.note ?? ''}"',
      );
    }
    return buffer.toString();
  }
}
