import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';

class StorageService {
  static const String _transactionsKey = 'app_transactions_list';
  static const String _monthlyLimitKey = 'app_monthly_budget_limit';
  static const String _settingsKey = 'app_user_settings';
  static const String _savingsGoalsKey = 'app_savings_goals';
  static const String _creditCardsKey = 'app_credit_cards';

  Future<List<TransactionItem>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_transactionsKey);
    if (jsonList == null) return [];

    try {
      return jsonList
          .map((item) => TransactionItem.fromJson(item))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => item.toJson()).toList();
    await prefs.setStringList(_transactionsKey, jsonList);
  }

  Future<double> loadMonthlyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_monthlyLimitKey) ?? 30000.0;
  }

  Future<void> saveMonthlyLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monthlyLimitKey, limit);
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);
    if (jsonString != null) {
      try {
        return AppSettings.fromJson(jsonString);
      } catch (_) {}
    }
    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toJson());
  }

  Future<List<SavingsGoal>> loadSavingsGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_savingsGoalsKey);
    if (jsonList == null) return [];
    try {
      return jsonList.map((item) => SavingsGoal.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSavingsGoals(List<SavingsGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = goals.map((item) => item.toJson()).toList();
    await prefs.setStringList(_savingsGoalsKey, jsonList);
  }

  Future<List<CreditCardInfo>> loadCreditCards() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_creditCardsKey);
    if (jsonList == null) return [];
    try {
      return jsonList.map((item) => CreditCardInfo.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCreditCards(List<CreditCardInfo> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cards.map((item) => item.toJson()).toList();
    await prefs.setStringList(_creditCardsKey, jsonList);
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
    await prefs.remove(_savingsGoalsKey);
    await prefs.remove(_creditCardsKey);
  }
}
