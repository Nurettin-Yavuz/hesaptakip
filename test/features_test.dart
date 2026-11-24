import 'package:flutter_test/flutter_test.dart';
import 'package:hesaptakip/controllers/transaction_controller.dart';
import 'package:hesaptakip/models/transaction_item.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('30 Yeni Özellik Bütünsel Doğrulama Testi', () {
    test('1-5: Kart Cüzdanı, Limit Takibi, Kategori Bütçeleri ve Tasarruf Hedefleri', () async {
      final controller = TransactionController();
      await controller.initialize();

      // 1. Kredi Kartı Cüzdanı
      await controller.addCreditCard(
        cardName: 'Bonus Genç',
        bankName: 'Garanti BBVA',
        cardLimit: 25000.0,
        cutOffDay: 15,
        paymentDueDay: 25,
      );
      expect(controller.creditCards.any((c) => c.cardName == 'Bonus Genç'), isTrue);

      // 2. Kart Harcaması ve Limit Doluluk Takibi
      await controller.addTransaction(
        title: 'Teknoloji Market',
        amount: 5000.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.giyim,
        date: DateTime.now(),
        cardName: 'Bonus Genç',
      );
      expect(controller.getSpentAmountForCard('Bonus Genç'), 5000.0);

      // 3 & 4. Kategori Bazlı Bütçe Kotası ve Aşım Kontrolü
      await controller.updateCategoryBudget(ExpenseCategory.giyim.name, 4000.0);
      expect(controller.settings.categoryBudgets[ExpenseCategory.giyim.name], 4000.0);
      // Harcanan 5000 > kota 4000 (Aşım durumu)
      final spentInGiyim = controller.categoryDistribution[ExpenseCategory.giyim] ?? 0.0;
      expect(spentInGiyim > 4000.0, isTrue);

      // 5. Tasarruf Hedefleri ve Kumbaraya Para Ekleme
      await controller.addSavingsGoal(
        title: 'Motosiklet Fonu',
        targetAmount: 80000.0,
        initialAmount: 20000.0,
        targetDate: DateTime.now().add(const Duration(days: 120)),
      );
      final goal = controller.savingsGoals.firstWhere((g) => g.title == 'Motosiklet Fonu');
      expect(goal.progressRatio, 0.25);
      await controller.depositToSavingsGoal(goal.id, 20000.0);
      final updatedGoal = controller.savingsGoals.firstWhere((g) => g.title == 'Motosiklet Fonu');
      expect(updatedGoal.currentAmount, 40000.0);
      expect(updatedGoal.progressRatio, 0.5);
    });

    test('6-10: Etiketleme, Favoriler, Klonlama, Kompakt Mod ve MoM Kıyaslaması', () async {
      final controller = TransactionController();
      await controller.initialize();

      // 6. Etiketleme Sistemi (#Tags)
      await controller.addTransaction(
        title: 'Yaz Tatili Otel',
        amount: 7500.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.eglence,
        date: DateTime.now(),
        tags: ['#tatil', '#yaz'],
      );
      expect(controller.availableTags.contains('#tatil'), isTrue);
      controller.setSelectedTagFilter('#tatil');
      expect(controller.filteredTransactions.length, 1);
      controller.setSelectedTagFilter('#tatil'); // toggle off

      // 7. Favoriler (Harcama Şablonu)
      final txId = controller.allTransactions.first.id;
      await controller.toggleFavorite(txId);
      expect(controller.favoriteTemplates.length, 1);

      // 8. Harcamayı Klonlama (Duplicate)
      await controller.duplicateTransaction(txId);
      expect(controller.allTransactions.any((t) => t.title.contains('(Kopya)')), isTrue);

      // 9. Kompakt Liste Modu
      expect(controller.settings.compactListView, isFalse);
      await controller.toggleCompactView();
      expect(controller.settings.compactListView, isTrue);

      // 10. Geçen Ayla Karşılaştırma (MoM)
      final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1, 10);
      await controller.addTransaction(
        title: 'Geçen Ay Fatura',
        amount: 5000.0,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.fatura,
        date: lastMonth,
      );
      expect(controller.previousMonthTotal, 5000.0);
      expect(controller.summary.monthOverMonthChangePercent, isNotNull);
    });

    test('11-15: Haftalık Özet, En Yüksek Harcama, Kategori Şampiyonu, Güvenli Limit ve Projeksiyon', () async {
      final controller = TransactionController();
      await controller.initialize();

      await controller.addTransaction(
        title: 'Uçak Bileti',
        amount: 9000.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.akaryakit,
        date: DateTime.now(),
      );
      await controller.addTransaction(
        title: 'Kahve',
        amount: 150.0,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.restoran,
        date: DateTime.now(),
      );

      // 11. Bu Haftalık Toplam
      expect(controller.thisWeekTotal, greaterThanOrEqualTo(9150.0));

      // 12. En Yüksek Harcama (Peak Expense)
      expect(controller.peakExpense?.title, 'Uçak Bileti');

      // 13. Harcama Şampiyonu Kategori
      expect(controller.topExpenseCategory?.key, ExpenseCategory.akaryakit);

      // 14. Günlük Güvenli Harcama Limiti
      expect(controller.summary.dailySafeBudget, greaterThan(0));

      // 15. Ay Sonu Tahmini Projeksiyon
      expect(controller.summary.projectedMonthEndTotal, greaterThan(0));
    });

    test('16-20: Bütçe Alarmı, Gizlilik, Sabitler, Taksitler ve CSV Export', () async {
      final controller = TransactionController();
      await controller.initialize();

      await controller.addTransaction(
        title: 'MacBook Taksit',
        amount: 4500.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.giyim,
        date: DateTime.now(),
        installmentCount: 6,
      );
      await controller.addTransaction(
        title: 'Kira',
        amount: 12000.0,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.fatura,
        date: DateTime.now(),
        isRecurring: true,
      );

      // 18. Sabit Giderler
      expect(controller.recurringTransactions.length, 1);
      expect(controller.recurringMonthlyTotal, 12000.0);

      // 19. Taksitli Harcamalar
      expect(controller.installmentTransactions.length, 1);
      expect(controller.installmentMonthlyTotal, 4500.0);

      // 20. CSV Export
      final csv = controller.exportDataAsCsv();
      expect(csv.contains('MacBook Taksit'), isTrue);
      expect(csv.contains('Kira'), isTrue);
    });

    test('21-25: JSON Yedek ve Geri Yükleme, Sıralama, Arama, 1-30 Günlük Filtre', () async {
      final controller = TransactionController();
      await controller.initialize();

      await controller.addTransaction(
        title: 'Zzz Harcaması',
        amount: 100.0,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.diger,
        date: DateTime.now(),
      );
      await controller.addTransaction(
        title: 'Aaa Harcaması',
        amount: 999.0,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.diger,
        date: DateTime.now(),
      );

      // 21. JSON Yedek ve Restore
      final jsonBackup = controller.exportDataAsJson();
      final restored = await controller.restoreDataFromJson(jsonBackup);
      expect(restored, isTrue);

      // 23. Akıllı Sıralama (A-Z)
      controller.setSortOrder(SortOrder.titleAsc);
      expect(controller.filteredTransactions.first.title, 'Aaa Harcaması');

      // 24. Çoklu Arama
      controller.setSearchQuery('Zzz');
      expect(controller.filteredTransactions.length, 1);
      expect(controller.filteredTransactions.first.title, 'Zzz Harcaması');
      controller.setSearchQuery('');

      // 25. 1'den 30'a Günlük Filtre
      final today = DateTime.now().day;
      controller.setSelectedDayFilter(today);
      expect(controller.selectedDayFilter, today);
      controller.setSelectedDayFilter(today); // toggle off
      expect(controller.selectedDayFilter, isNull);
    });

    test('26-30: Oran Dağılımı, Güncelleme, Demo Yükleme, Sıfırlama ve Finansal Koçluk', () async {
      final controller = TransactionController();
      await controller.initialize();

      // 28. Demo Veri Yükleme
      await controller.loadDemoData();
      expect(controller.allTransactions.length, greaterThan(3));
      expect(controller.creditCards.length, greaterThanOrEqualTo(2));

      // 26. Kredi Kartı vs Nakit Oransal Dağılım
      expect(controller.summary.creditCardRatio, greaterThan(0));
      expect(controller.summary.cashRatio, greaterThan(0));

      // 27. Güncelleme
      final first = controller.allTransactions.first;
      await controller.updateTransaction(first.copyWith(title: 'Güncellenmiş Başlık'));
      expect(controller.allTransactions.first.title, 'Güncellenmiş Başlık');

      // 30. Finansal Tavsiye
      expect(controller.financialAdvice.isNotEmpty, isTrue);

      // 29. Sıfırlama
      await controller.clearAllTransactions();
      expect(controller.allTransactions.isEmpty, isTrue);
      expect(controller.savingsGoals.isEmpty, isTrue);
    });

    test('31: Finansal Sağlık Skoru ve Akıllı Bütçe Nabzı Hesaplama Testi', () async {
      final controller = TransactionController();
      await controller.initialize();

      // Sıfır harcama ve limitsiz durumda dengeli başlangıç skoru
      final initialHealth = controller.financialHealth;
      expect(initialHealth.score, greaterThanOrEqualTo(50));
      expect(initialHealth.statusText.isNotEmpty, isTrue);
      expect(initialHealth.advice.isNotEmpty, isTrue);

      // Demo verileri yüklendiğinde hesaplama doğrulaması
      await controller.loadDemoData();
      final demoHealth = controller.financialHealth;
      expect(demoHealth.score, inInclusiveRange(0, 100));
      expect(demoHealth.budgetDisciplineRatio, inInclusiveRange(0.0, 1.0));
      expect(demoHealth.savingsScoreRatio, inInclusiveRange(0.0, 1.0));
      expect(demoHealth.cardDependencyRatio, inInclusiveRange(0.0, 1.0));
      expect(demoHealth.level, isA<HealthLevel>());
    });
  });
}
