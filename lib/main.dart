import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/transaction_controller.dart';
import 'models/transaction_item.dart';
import 'widgets/add_expense_sheet.dart';
import 'widgets/analytics_view.dart';
import 'widgets/ratio_indicator_card.dart';
import 'widgets/transaction_tile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const KrediKartiHesapTakipApp());
}

class KrediKartiHesapTakipApp extends StatelessWidget {
  const KrediKartiHesapTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hesap & Harcama Takibi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
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
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TransactionController _controller;
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TransactionController();
    _controller.initialize();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openAddExpenseSheet([TransactionItem? itemToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AddExpenseSheet(
          existingItem: itemToEdit,
          onSave: ({
            required String title,
            required double amount,
            required PaymentType paymentType,
            required ExpenseCategory category,
            required DateTime date,
            String? note,
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Aylık Limit Belirle',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Hedef Bütçe / Limit (₺)',
            hintText: 'Örn: 40000',
            prefixIcon: const Icon(Icons.currency_lira_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Color(0xFF64748B))),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final summary = _controller.summary;
        final transactions = _controller.filteredTransactions;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Harcama & Oran Takibi'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  labelColor: const Color(0xFF0F172A),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Harcamalar'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_outline_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Oran & Analiz'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. Harcama Listesi
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: RatioIndicatorCard(
                      summary: summary,
                      onEditLimit: _showEditLimitDialog,
                    ),
                  ),

                  // Filtre ve Arama Çubuğu
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: _controller.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: 'Başlık, kategori veya not ara...',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
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
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'Tümü (${_controller.allTransactions.length})',
                                  filter: FilterPaymentType.all,
                                ),
                                const SizedBox(width: 6),
                                _buildFilterChip(
                                  label: 'Kredi Kartı',
                                  filter: FilterPaymentType.creditCard,
                                  icon: Icons.credit_card_rounded,
                                ),
                                const SizedBox(width: 6),
                                _buildFilterChip(
                                  label: 'Nakit',
                                  filter: FilterPaymentType.cash,
                                  icon: Icons.payments_rounded,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Harcama Listesi
                  if (transactions.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'Kayıtlı harcama bulunamadı.\nSağ alttaki butondan yeni harcama ekleyebilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
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
                            item: item,
                            onTap: () => _openAddExpenseSheet(item),
                            onDelete: () => _controller.deleteTransaction(item.id),
                          );
                        },
                        childCount: transactions.length,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),

              // 2. Oran ve Analiz Tab
              AnalyticsView(controller: _controller),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddExpenseSheet(),
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 2,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Harcama Ekle',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required FilterPaymentType filter,
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
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            )
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
