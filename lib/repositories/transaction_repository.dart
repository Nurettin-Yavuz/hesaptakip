import '../core/error/failures.dart';
import '../models/transaction_item.dart';
import '../services/storage_service.dart';

/// Clean Architecture: Domain/Data kontrati
abstract interface class ITransactionRepository {
  Future<Result<List<TransactionItem>, StorageFailure>> getTransactions();
  Future<Result<void, StorageFailure>> saveTransactions(List<TransactionItem> items);
  Future<Result<double, StorageFailure>> getMonthlyLimit();
  Future<Result<void, StorageFailure>> saveMonthlyLimit(double limit);
  Future<Result<AppSettings, StorageFailure>> getSettings();
  Future<Result<void, StorageFailure>> saveSettings(AppSettings settings);
  Future<Result<List<SavingsGoal>, StorageFailure>> getSavingsGoals();
  Future<Result<void, StorageFailure>> saveSavingsGoals(List<SavingsGoal> goals);
  Future<Result<List<CreditCardInfo>, StorageFailure>> getCreditCards();
  Future<Result<void, StorageFailure>> saveCreditCards(List<CreditCardInfo> cards);
  Future<Result<void, StorageFailure>> clearAllData();
}

/// Depolama servisi ile entegre somut Repository sinifi
class TransactionRepository implements ITransactionRepository {
  final StorageService _storageService;

  TransactionRepository({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  @override
  Future<Result<List<TransactionItem>, StorageFailure>> getTransactions() async {
    try {
      final items = await _storageService.loadTransactions();
      return Result.success(items);
    } catch (e) {
      return Result.failure(StorageFailure('Harcamalar yuklenirken hata olustu.', e));
    }
  }

  @override
  Future<Result<void, StorageFailure>> saveTransactions(List<TransactionItem> items) async {
    try {
      await _storageService.saveTransactions(items);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Harcamalar kaydedilirken hata olustu.', e));
    }
  }

  @override
  Future<Result<double, StorageFailure>> getMonthlyLimit() async {
    try {
      final limit = await _storageService.loadMonthlyLimit();
      return Result.success(limit);
    } catch (e) {
      return Result.failure(StorageFailure('Aylik limit yuklenemedi.', e));
    }
  }

  @override
  Future<Result<void, StorageFailure>> saveMonthlyLimit(double limit) async {
    try {
      await _storageService.saveMonthlyLimit(limit);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Aylik limit kaydedilemedi.', e));
    }
  }

  @override
  Future<Result<AppSettings, StorageFailure>> getSettings() async {
    try {
      final settings = await _storageService.loadSettings();
      return Result.success(settings);
    } catch (e) {
      return Result.failure(StorageFailure('Ayarlar yuklenemedi.', e));
    }
  }

  @override
  Future<Result<void, StorageFailure>> saveSettings(AppSettings settings) async {
    try {
      await _storageService.saveSettings(settings);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Ayarlar kaydedilemedi.', e));
    }
  }

  @override
  Future<Result<List<SavingsGoal>, StorageFailure>> getSavingsGoals() async {
    try {
      final goals = await _storageService.loadSavingsGoals();
      return Result.success(goals);
    } catch (e) {
      return Result.failure(StorageFailure('Tasarruf hedefleri yuklenemedi.', e));
    }
  }

  @override
  Future<Result<void, StorageFailure>> saveSavingsGoals(List<SavingsGoal> goals) async {
    try {
      await _storageService.saveSavingsGoals(goals);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Tasarruf hedefleri kaydedilemedi.', e));
    }
  }

  @override
  Future<Result<List<CreditCardInfo>, StorageFailure>> getCreditCards() async {
    try {
      final cards = await _storageService.loadCreditCards();
      return Result.success(cards);
    } catch (e) {
      return Result.failure(StorageFailure('Kredi kartlari yuklenemedi.', e));
    }
  }

  @override
  Future<Result<void, StorageFailure>> saveCreditCards(List<CreditCardInfo> cards) async {
    try {
      await _storageService.saveCreditCards(cards);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Kredi kartlari kaydedilemedi.', e));
    }
  }

  @override
  Future<Result<void, StorageFailure>> clearAllData() async {
    try {
      await _storageService.clearAllData();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Veriler temizlenirken hata olustu.', e));
    }
  }
}
