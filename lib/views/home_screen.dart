import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/theme_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/day_tracking_timeline.dart';
import '../widgets/month_selector_bar.dart';
import '../widgets/ratio_indicator_card.dart';
import '../widgets/transaction_tile.dart';
import 'analytics_view.dart';
import 'settings_view.dart';


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
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
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
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        title: Text(
          'Aylık Limit Belirle',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.4,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
            child: Text('Vazgeç', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(textController.text.trim()) ??
                  _controller.monthlyLimit;
              _controller.updateMonthlyLimit(newLimit);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
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
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _controller.currentSortOrder == order;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18) : null,
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
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentNavIndex),
                  child: IndexedStack(
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
                              fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  width: 0.8,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  width: 0.8,
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
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                                  label: Text('Sabitler (${_controller.recurringTransactions.length})'),
                                  backgroundColor: _controller.showOnlyRecurring
                                      ? AppColors.amber
                                      : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _controller.showOnlyRecurring
                                        ? Colors.white
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: _controller.showOnlyRecurring
                                          ? AppColors.amber
                                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                      width: 0.8,
                                    ),
                                  ),
                                  onPressed: _controller.toggleOnlyRecurring,
                                ),
                                const SizedBox(width: 6),
                                ActionChip(
                                  avatar: Icon(
                                    Icons.pie_chart_outline_rounded,
                                    size: 15,
                                    color: _controller.showOnlyInstallments
                                        ? Colors.white
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                                  label: Text('Taksitli (${_controller.installmentTransactions.length})'),
                                  backgroundColor: _controller.showOnlyInstallments
                                      ? AppColors.iceBlue
                                      : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _controller.showOnlyInstallments
                                        ? Colors.white
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: _controller.showOnlyInstallments
                                          ? AppColors.iceBlue
                                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                      width: 0.8,
                                    ),
                                  ),
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
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, val, child) {
                          return Opacity(
                            opacity: val,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - val)),
                              child: child,
                            ),
                          );
                        },
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
                                  'Henüz Harcama Kaydı Yok',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Bu aya ait herhangi bir harcama bulunmuyor. Yeni bir harcama ekleyerek bütçenizi yönetmeye başlayabilirsiniz.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _openAddExpenseSheet();
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Harcama Ekle'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
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
                            index: index,
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
          ),
          ),
          ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentNavIndex,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentNavIndex = index);
            },
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.list_alt_rounded),
                selectedIcon: Icon(Icons.list_alt_rounded, color: AppColors.primary),
                label: 'Harcamalar',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.pie_chart_rounded, color: AppColors.primary),
                label: 'Oran & Analiz',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
                label: 'Ayarlar',
              ),
            ],
          ),
          floatingActionButton: _currentNavIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _openAddExpenseSheet();
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Harcama Ekle',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2),
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
      onSelected: (_) {
        HapticFeedback.selectionClick();
        _controller.setFilter(filter);
      },
      avatar: icon != null
          ? Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            )
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        width: 0.8,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
