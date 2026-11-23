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
    test('BudgetSummary günlük güvenli harcama ve ay sonu tahminini hesaplar', () {
      const summary = BudgetSummary(
        creditCardTotal: 6000.0,
        cashTotal: 4000.0,
        monthlyLimit: 20000.0,
        daysInMonth: 30,
        currentDay: 15,
      );

      expect(summary.grandTotal, 10000.0);
      expect(summary.remainingBudget, 10000.0);
      expect(summary.dailySafeBudget, closeTo(625.0, 1.0));
      expect(summary.projectedMonthEndTotal, closeTo(20000.0, 10.0));
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

    test('CSV ve JSON export motoru veri üretir', () async {
      final controller = TransactionController();
      await controller.initialize();

      await controller.addTransaction(
        title: 'Test Verisi',
        amount: 250.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.akaryakit,
        date: DateTime.now(),
        cardName: 'Bonus',
        installmentCount: 3,
      );

      final csv = controller.exportDataAsCsv();
      expect(csv.contains('Test Verisi'), isTrue);
      expect(csv.contains('Bonus'), isTrue);

      final json = controller.exportDataAsJson();
      expect(json.contains('Test Verisi'), isTrue);
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
      expect(find.text('Kredi Kartı Hesap Kesim Günü'), findsOneWidget);
      expect(find.text('Excel / CSV Formatında İndir'), findsOneWidget);
    });

    testWidgets('Dar ekran boyutunda (360x640) Harcama Ekleme Modal penceresi açılır ve taşma oluşmaz', (
      WidgetTester tester,
    ) async {
      // Dar ekran testi (küçük telefon ölçüsü)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const KrediKartiHesapTakipApp());
      await tester.pumpAndSettle();

      // Harcama Ekle butonuna tıkla
      final addBtn = find.text('Harcama Ekle');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Modal pencerenin açıldığını ve öğelerinin yer aldığını doğrula
      expect(find.text('Yeni Harcama Ekle'), findsOneWidget);
      expect(find.text('Kredi Kartı'), findsWidgets);
      expect(find.text('Nakit'), findsWidgets);
      expect(find.text('Banka / Kart'), findsOneWidget);
      expect(find.text('Taksit'), findsOneWidget);
    });
  });
}
