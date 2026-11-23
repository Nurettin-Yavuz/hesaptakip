import 'package:flutter_test/flutter_test.dart';
import 'package:hesaptakip/controllers/theme_controller.dart';
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

  group('Hesap Takip & Oranlama Model / Controller Testleri', () {
    test('BudgetSummary kredi kartı ve nakit oranlarını doğru hesaplar', () {
      const summary = BudgetSummary(
        creditCardTotal: 6000.0,
        cashTotal: 4000.0,
        monthlyLimit: 20000.0,
      );

      expect(summary.grandTotal, 10000.0);
      expect(summary.creditCardRatio, 60.0);
      expect(summary.cashRatio, 40.0);
      expect(summary.remainingBudget, 10000.0);
      expect(summary.budgetUsageRatio, 0.5);
    });

    test('TransactionController başlangıçta temizdir ve ekleme/silme çalışır', () async {
      final controller = TransactionController();
      await controller.initialize();

      // Sıfır veri doğrulaması
      expect(controller.allTransactions.length, 0);

      // Yeni Kredi Kartı harcaması ekle
      await controller.addTransaction(
        title: 'Özel Test Alışverişi',
        amount: 1500.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.market,
        date: DateTime.now(),
      );

      expect(controller.allTransactions.length, 1);

      // Silme işlemi testi
      final id = controller.allTransactions.first.id;
      await controller.deleteTransaction(id);
      expect(controller.allTransactions.length, 0);
    });

    test('ThemeController koyu ve açık tema geçişini yönetir', () async {
      final themeController = ThemeController();
      await themeController.initialize();

      await themeController.toggleTheme();
      expect(themeController.isDarkMode, isTrue);

      await themeController.toggleTheme();
      expect(themeController.isDarkMode, isFalse);
    });
  });

  group('Widget UI Testleri', () {
    testWidgets('Ana ekran temiz sıfır durumla yüklenir ve bileşenler ekranda yer alır', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const KrediKartiHesapTakipApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Harcama & Oran Takibi'), findsOneWidget);
      expect(find.text('Toplam Harcama'), findsOneWidget);
      expect(find.text('Harcamalar'), findsOneWidget);
      expect(find.text('Oran & Analiz'), findsOneWidget);
      expect(find.text('Harcama Ekle'), findsOneWidget);
      expect(find.text('Kayıtlı Harcama Yok'), findsOneWidget);
    });
  });
}
