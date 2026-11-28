import 'package:flutter_test/flutter_test.dart';
import 'package:hesaptakip/core/error/failures.dart';
import 'package:hesaptakip/models/transaction_item.dart';
import 'package:hesaptakip/repositories/transaction_repository.dart';
import 'package:hesaptakip/controllers/transaction_controller.dart';
import 'package:hesaptakip/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Test icin sahte hata firlatan depolama servisi
class FailingStorageService extends StorageService {
  @override
  Future<List<TransactionItem>> loadTransactions() async {
    throw Exception('Veritabani okuma hatasi simule edildi');
  }

  @override
  Future<void> saveTransactions(List<TransactionItem> items) async {
    throw Exception('Diske yazma hatasi');
  }

  @override
  Future<double> loadMonthlyLimit() async {
    throw Exception('Limit yukleme hatasi');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clean Architecture - Result ve Failure Modelleri Testi', () {
    test('Result.success dogru veri tasiyor ve isSuccess true donuyor', () {
      final Result<String, Failure> result = Result.success('Basarili');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals('Basarili'));
      expect(result.failureOrNull, isNull);

      final folded = result.fold(
        onSuccess: (data) => 'Veri: $data',
        onFailure: (failure) => 'Hata: ${failure.message}',
      );
      expect(folded, equals('Veri: Basarili'));
    });

    test('Result.failure hata nesnesi tasiyor ve isFailure true donuyor', () {
      const failure = StorageFailure('Yerel kayit hatasi olustu');
      final Result<String, StorageFailure> result = Result.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, equals(failure));
      expect(result.failureOrNull?.message, equals('Yerel kayit hatasi olustu'));

      final folded = result.fold(
        onSuccess: (data) => 'Veri: $data',
        onFailure: (failure) => 'Hata: ${failure.message}',
      );
      expect(folded, equals('Hata: Yerel kayit hatasi olustu'));
    });

    test('Tum Failure turevleri dogru mesaj ve toString uretir', () {
      const storage = StorageFailure('Disk dolu');
      const validation = ValidationFailure('Tutar negatif olamaz');
      const format = FormatFailure('Gecersiz JSON');
      const notFound = NotFoundFailure('Kart bulunamadi');

      expect(storage.toString(), contains('StorageFailure: Disk dolu'));
      expect(validation.toString(), contains('ValidationFailure: Tutar negatif olamaz'));
      expect(format.toString(), contains('FormatFailure: Gecersiz JSON'));
      expect(notFound.toString(), contains('NotFoundFailure: Kart bulunamadi'));
    });
  });

  group('Clean Architecture - TransactionRepository Somut Testleri', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TransactionRepository basarili islemlerde Result.success dondurur', () async {
      final repository = TransactionRepository();

      // 1. Ilk yuklemede bos liste dondurur
      final loadRes = await repository.getTransactions();
      expect(loadRes.isSuccess, isTrue);
      expect(loadRes.dataOrNull, isEmpty);

      // 2. Harcama kaydet ve tekrar oku
      final item = TransactionItem(
        id: 'tx-1',
        title: 'Market Alisverisi',
        amount: 250.0,
        paymentType: PaymentType.creditCard,
        category: ExpenseCategory.market,
        date: DateTime(2026, 11, 28),
      );

      final saveRes = await repository.saveTransactions([item]);
      expect(saveRes.isSuccess, isTrue);

      final reloadRes = await repository.getTransactions();
      expect(reloadRes.isSuccess, isTrue);
      expect(reloadRes.dataOrNull?.length, equals(1));
      expect(reloadRes.dataOrNull?.first.title, equals('Market Alisverisi'));

      // 3. Limit kaydet ve oku
      final saveLimitRes = await repository.saveMonthlyLimit(45000.0);
      expect(saveLimitRes.isSuccess, isTrue);

      final limitRes = await repository.getMonthlyLimit();
      expect(limitRes.isSuccess, isTrue);
      expect(limitRes.dataOrNull, equals(45000.0));

      // 4. Ayarlari kaydet ve oku
      final settingsRes = await repository.getSettings();
      expect(settingsRes.isSuccess, isTrue);
      expect(settingsRes.dataOrNull?.cutOffDay, equals(1));

      final newSettings = const AppSettings(cutOffDay: 20, compactListView: true);
      final saveSettingsRes = await repository.saveSettings(newSettings);
      expect(saveSettingsRes.isSuccess, isTrue);

      final reSettingsRes = await repository.getSettings();
      expect(reSettingsRes.dataOrNull?.cutOffDay, equals(20));
      expect(reSettingsRes.dataOrNull?.compactListView, isTrue);
    });

    test('TransactionRepository hata durumunda Result.failure yakalar ve guvenli doner', () async {
      final failingRepo = TransactionRepository(storageService: FailingStorageService());

      final txRes = await failingRepo.getTransactions();
      expect(txRes.isFailure, isTrue);
      expect(txRes.failureOrNull, isA<StorageFailure>());

      final saveRes = await failingRepo.saveTransactions([]);
      expect(saveRes.isFailure, isTrue);
      expect(saveRes.failureOrNull, isA<StorageFailure>());

      final limitRes = await failingRepo.getMonthlyLimit();
      expect(limitRes.isFailure, isTrue);
    });

    test('TransactionController ITransactionRepository ile basariyla initialize olur', () async {
      final repository = TransactionRepository();
      final controller = TransactionController(repository: repository);

      expect(controller.isLoading, isTrue);
      await controller.initialize();
      expect(controller.isLoading, isFalse);
      expect(controller.monthlyLimit, equals(30000.0));
      expect(controller.repository, equals(repository));
    });
  });
}
