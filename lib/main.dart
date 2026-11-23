import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/theme_controller.dart';
import 'controllers/transaction_controller.dart';
import 'models/transaction_item.dart';
import 'widgets/add_expense_sheet.dart';
import 'widgets/analytics_view.dart';
import 'widgets/day_tracking_timeline.dart';
import 'widgets/month_selector_bar.dart';
import 'widgets/ratio_indicator_card.dart';
import 'widgets/settings_view.dart';
import 'widgets/transaction_tile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const KrediKartiHesapTakipApp());
}

class KrediKartiHesapTakipApp extends StatefulWidget {
  const KrediKartiHesapTakipApp({super.key});

  @override
  State<KrediKartiHesapTakipApp> createState() => _KrediKartiHesapTakipAppState();
}

class _KrediKartiHesapTakipAppState extends State<KrediKartiHesapTakipApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.initialize();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Hesap & Harcama Takibi',
          debugShowCheckedModeBanner: false,
          themeMode: _themeController.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.light,
              surface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              iconTheme: IconThemeData(color: Color(0xFF0F172A)),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
              surface: const Color(0xFF1E293B),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F172A),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          home: HomeScreen(themeController: _themeController),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ThemeController themeController;

  const HomeScreen({super.key, required this.themeController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TransactionController _controller;
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TransactionController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openAddExpenseSheet([TransactionItem? itemToEdit]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AddExpenseSheet(
          existingItem: itemToEdit,
          registeredCards: _controller.creditCards,
          onSave: ({
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
          }) {
            if (itemToEdit != null) {
              _controller.updateTransaction(
                TransactionItem(
                  id: itemToEdit.id,
                  title: title,
                  amount: amount,
                  paymentType: paymentType,
                  category: category,
                  date: date,
                  note: note,
                  installmentCount: installmentCount,
                  isRecurring: isRecurring,
                  cardName: cardName,
                  isFavorite: isFavorite,
                  tags: tags,
                ),
              );
            } else {
              _controller.addTransaction(
                title: title,
                amount: amount,
                paymentType: paymentType,
                category: category,
                date: date,
                note: note,
                installmentCount: installmentCount,
                isRecurring: isRecurring,
                cardName: cardName,
                isFavorite: isFavorite,
                tags: tags,
              );
            }
          },
        );
      },
    );
  }

  void _showEditLimitDialog() {
    final textController = TextEditingController(
      text: _controller.monthlyLimit.toStringAsFixed(0),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Aylık Limit Belirle',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Hedef Bütçe / Limit (₺)',
            hintText: 'Örn: 30000',
            prefixIcon: const Icon(Icons.currency_lira_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(textController.text.trim()) ??
                  _controller.monthlyLimit;
              _controller.updateMonthlyLimit(newLimit);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sıralama Ölçütü',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSortTile('Tarihe Göre (En Yeni)', SortOrder.dateDesc),
            _buildSortTile('Tarihe Göre (En Eski)', SortOrder.dateAsc),
            _buildSortTile('Tutara Göre (En Yüksek)', SortOrder.amountDesc),
            _buildSortTile('Tutara Göre (En Düşük)', SortOrder.amountAsc),
            _buildSortTile('İsme Göre (A-Z)', SortOrder.titleAsc),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(String label, SortOrder order) {
    final isSelected = _controller.currentSortOrder == order;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? const Color(0xFF4F46E5) : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5)) : null,
      onTap: () {
        _controller.setSortOrder(order);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final summary = _controller.summary;
        final transactions = _controller.filteredTransactions;
        final settings = _controller.settings;
        final favorites = _controller.favoriteTemplates;
        final availableTags = _controller.availableTags;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Harcama & Bütçe'),
            actions: [
              IconButton(
                tooltip: settings.hideSensitiveAmounts ? 'Bakiyeleri Göster' : 'Bakiyeleri Gizle',
                onPressed: () {
                  _controller.updateSettings(
                    settings.copyWith(hideSensitiveAmounts: !settings.hideSensitiveAmounts),
                  );
                },
                icon: Icon(
                  settings.hideSensitiveAmounts ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: settings.hideSensitiveAmounts ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              IconButton(
                tooltip: 'Sırala',
                onPressed: _showSortOptions,
                icon: const Icon(Icons.sort_rounded),
              ),
              IconButton(
                tooltip: isDark ? 'Açık Temaya Geç' : 'Koyu Temaya Geç',
                onPressed: () => widget.themeController.toggleTheme(),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentNavIndex,
            children: [
              // 1. Ekran: Harcamalar & 1-30 Günlük Zaman Çizelgesi
              CustomScrollView(
                slivers: [
                  // Ay Değiştirici ve Seçici Çubuk
                  SliverToBoxAdapter(
                    child: MonthSelectorBar(
                      selectedMonth: _controller.selectedMonth,
                      availableMonths: _controller.availableMonths,
                      onMonthChanged: _controller.setSelectedMonth,
                      onPrevious: _controller.previousMonth,
                      onNext: _controller.nextMonth,
                    ),
                  ),

                  // Oran Kartı (Kredi Kartı vs Nakit + MoM Kıyaslama + Gizlilik Desteği)
                  SliverToBoxAdapter(
                    child: RatioIndicatorCard(
                      summary: summary,
                      onEditLimit: _showEditLimitDialog,
                      hideAmounts: settings.hideSensitiveAmounts,
                    ),
                  ),

                  // 1'inden 30'una Günlük Takip Çizelgesi (Tıklayarak Güne Göre Filtreleme)
                  SliverToBoxAdapter(
                    child: DayTrackingTimeline(
                      dailyMap: _controller.dailyExpenditureMap,
                      daysInMonth: summary.daysInMonth,
                      currentDay: summary.currentDay,
                      monthlyLimit: summary.monthlyLimit,
                      selectedDay: _controller.selectedDayFilter,
                      onSelectDay: _controller.setSelectedDayFilter,
                    ),
                  ),

                  // Favoriler / Sık Kullanılan Şablonlar Çubuğu (Varsa)
                  if (favorites.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(
                                  'Hızlı Harcama Şablonları',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 34,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: favorites.length,
                                itemBuilder: (ctx, i) {
                                  final fav = favorites[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: ActionChip(
                                      avatar: const Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFFF59E0B)),
                                      label: Text('${fav.title} (₺${fav.amount.toStringAsFixed(0)})'),
                                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      onPressed: () {
                                        _controller.duplicateTransaction(fav.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('"${fav.title}" bugünün tarihiyle eklendi.')),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Filtre ve Arama Çubuğu
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: _controller.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: 'Başlık, kart, kategori, #etiket veya not...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _controller.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Ödeme Türü ve Özellik Filtreleri
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'Tümü (${_controller.currentMonthTransactions.length})',
                                  filter: FilterPaymentType.all,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildFilterChip(
                                  label: 'Kredi Kartı',
                                  filter: FilterPaymentType.creditCard,
                                  icon: Icons.credit_card_rounded,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildFilterChip(
                                  label: 'Nakit',
                                  filter: FilterPaymentType.cash,
                                  icon: Icons.payments_rounded,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 6),
                                ActionChip(
                                  avatar: Icon(
                                    Icons.repeat_rounded,
                                    size: 15,
                                    color: _controller.showOnlyRecurring
                                        ? Colors.white
                                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                  label: Text('Sabitler (${_controller.recurringTransactions.length})'),
                                  backgroundColor: _controller.showOnlyRecurring
                                      ? const Color(0xFFF59E0B)
                                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _controller.showOnlyRecurring
                                        ? Colors.white
                                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onPressed: _controller.toggleOnlyRecurring,
                                ),
                                const SizedBox(width: 6),
                                ActionChip(
                                  avatar: Icon(
                                    Icons.pie_chart_outline_rounded,
                                    size: 15,
                                    color: _controller.showOnlyInstallments
                                        ? Colors.white
                                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                  label: Text('Taksitli (${_controller.installmentTransactions.length})'),
                                  backgroundColor: _controller.showOnlyInstallments
                                      ? const Color(0xFF6366F1)
                                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _controller.showOnlyInstallments
                                        ? Colors.white
                                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onPressed: _controller.toggleOnlyInstallments,
                                ),
                              ],
                            ),
                          ),

                          // Etiket Filtreleme Çubukları (Varsa)
                          if (availableTags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 30,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: availableTags.map((tag) {
                                  final isSelected = _controller.selectedTagFilter == tag;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: FilterChip(
                                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                                      selected: isSelected,
                                      onSelected: (_) => _controller.setSelectedTagFilter(tag),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Harcama Listesi
                  if (transactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 40,
                                color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Bu Ay İçin Harcama Yok',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Harcama ekleyebilir veya tek dokunuşla hazır demo verilerini yükleyebilirsiniz.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () => _controller.loadDemoData(),
                                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                                label: const Text('Örnek Demo Verileri Yükle'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = transactions[index];
                          return TransactionTile(
                            item: item,
                            onTap: () => _openAddExpenseSheet(item),
                            onDelete: () => _controller.deleteTransaction(item.id),
                            onDuplicate: () => _controller.duplicateTransaction(item.id),
                            onToggleFavorite: () => _controller.toggleFavorite(item.id),
                            isCompact: settings.compactListView,
                            hideAmounts: settings.hideSensitiveAmounts,
                          );
                        },
                        childCount: transactions.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),

              // 2. Ekran: Oranlar, Analiz & Cüzdan & Hedefler
              AnalyticsView(controller: _controller),

              // 3. Ekran: Ayarlar, Bütçe, Kesim Günü & Dışa Aktarma
              SettingsView(controller: _controller),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentNavIndex,
            onDestinationSelected: (index) => setState(() => _currentNavIndex = index),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            indicatorColor: const Color(0xFF4F46E5).withValues(alpha: 0.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.list_alt_rounded),
                selectedIcon: Icon(Icons.list_alt_rounded, color: Color(0xFF4F46E5)),
                label: 'Harcamalar',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.pie_chart_rounded, color: Color(0xFF4F46E5)),
                label: 'Oran & Analiz',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF4F46E5)),
                label: 'Ayarlar',
              ),
            ],
          ),
          floatingActionButton: _currentNavIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openAddExpenseSheet(),
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Harcama Ekle',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required FilterPaymentType filter,
    required bool isDark,
    IconData? icon,
  }) {
    final isSelected = _controller.selectedFilter == filter;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => _controller.setFilter(filter),
      avatar: icon != null
          ? Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            )
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected
            ? Colors.white
            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
      ),
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF4F46E5)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
