import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesaptakip/controllers/transaction_controller.dart';
import 'package:hesaptakip/main.dart';
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

  group('Hesap Takip Gelişmiş Özellikler Testi', () {
    test('BudgetSummary günlük güvenli harcama ve MoM değişimini hesaplar', () {
      const summary = BudgetSummary(
        creditCardTotal: 6000.0,
        cashTotal: 4000.0,
        monthlyLimit: 20000.0,
        daysInMonth: 30,
        currentDay: 15,
        previousMonthTotal: 8000.0,
      );

      expect(summary.grandTotal, 10000.0);
      expect(summary.remainingBudget, 10000.0);
      expect(summary.dailySafeBudget, closeTo(625.0, 1.0));
      expect(summary.projectedMonthEndTotal, closeTo(20000.0, 10.0));
      expect(summary.monthOverMonthChangePercent, closeTo(25.0, 0.1));
    });

    test('Ay değiştirme ve aya göre filtreleme doğru çalışır', () async {
      final controller = TransactionController();
      await controller.initialize();

      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);

      await controller.addTransaction(
        title: 'Bu Ayki Harcama',
        amount: 500.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.market,
        date: now,
      );

      await controller.addTransaction(
        title: 'Geçen Ayki Harcama',
        amount: 800.0,
        paymentType: PaymentType.cash,
        category: ExpenseCategory.fatura,
        date: lastMonth,
      );

      expect(controller.currentMonthTransactions.length, 1);
      expect(controller.currentMonthTransactions.first.title, 'Bu Ayki Harcama');

      controller.previousMonth();
      expect(controller.currentMonthTransactions.length, 1);
      expect(controller.currentMonthTransactions.first.title, 'Geçen Ayki Harcama');
    });

    test('Kredi Kartı Cüzdanı ve Tasarruf Hedefleri yönetimi çalışır', () async {
      final controller = TransactionController();
      await controller.initialize();

      await controller.addSavingsGoal(
        title: 'Tatil Fonu',
        targetAmount: 10000.0,
        initialAmount: 2000.0,
        targetDate: DateTime.now().add(const Duration(days: 90)),
      );

      expect(controller.savingsGoals.length, 1);
      expect(controller.savingsGoals.first.title, 'Tatil Fonu');
      expect(controller.savingsGoals.first.progressRatio, 0.2);

      await controller.depositToSavingsGoal(controller.savingsGoals.first.id, 3000.0);
      expect(controller.savingsGoals.first.currentAmount, 5000.0);
      expect(controller.savingsGoals.first.progressRatio, 0.5);

      await controller.addCreditCard(
        cardName: 'Ziraat Platinum',
        bankName: 'Ziraat',
        cardLimit: 40000.0,
        cutOffDay: 10,
        paymentDueDay: 20,
      );

      expect(controller.creditCards.any((c) => c.cardName == 'Ziraat Platinum'), isTrue);
    });

    test('Demo verileri başarıyla yüklenir ve CSV / JSON üretilir', () async {
      final controller = TransactionController();
      await controller.initialize();
      await controller.loadDemoData();

      expect(controller.allTransactions.length, greaterThan(3));
      expect(controller.savingsGoals.length, 2);

      final csv = controller.exportDataAsCsv();
      expect(csv.contains('Migros Süpermarket'), isTrue);

      final json = controller.exportDataAsJson();
      expect(json.contains('Migros Süpermarket'), isTrue);
    });
  });

  group('Widget UI Alt Bar ve Gezinme Testleri', () {
    testWidgets('Alt navigasyon barı ile Harcamalar, Analiz ve Ayarlar sayfaları açılır', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const KrediKartiHesapTakipApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Harcamalar'), findsWidgets);
      expect(find.text('Oran & Analiz'), findsOneWidget);
      expect(find.text('Ayarlar'), findsOneWidget);

      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();

      expect(find.text('Uygulama & Bütçe Ayarları'), findsOneWidget);
      expect(find.text('Hesap Kesim Günü'), findsOneWidget);
      expect(find.text('CSV / Excel Olarak Dışa Aktar'), findsOneWidget);
    });

    testWidgets('Dar ekran boyutunda (360x640) Harcama Ekleme Modal penceresi açılır ve taşma oluşmaz', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const KrediKartiHesapTakipApp());
      await tester.pumpAndSettle();

      final addBtn = find.text('Harcama Ekle');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Yeni Harcama Ekle'), findsOneWidget);
      expect(find.text('Kredi Kartı'), findsWidgets);
      expect(find.text('Nakit'), findsWidgets);
      expect(find.text('Taksit'), findsOneWidget);
    });
  });
}
