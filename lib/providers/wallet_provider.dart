import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  double _balance = 0.0;
  List<WalletTransaction> _transactions = [];
  WalletStats? _stats;
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;

  double get balance => _balance;
  List<WalletTransaction> get transactions => _transactions;
  WalletStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Load wallet info
  Future<void> loadWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _walletService.getWallet();
      _balance = (response['data']['balance'] ?? 0).toDouble();

      // Reset transactions pagination
      _currentPage = 1;
      _hasMore = true;
      _transactions = [];

      await loadTransactions();
      await loadStats();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error loading wallet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load transactions
  Future<void> loadTransactions({bool loadMore = false}) async {
    if (!_hasMore && loadMore) return;

    try {
      final newTransactions = await _walletService.getTransactions(
        page: loadMore ? _currentPage : 1,
      );

      if (loadMore) {
        _transactions.addAll(newTransactions);
      } else {
        _transactions = newTransactions;
        _currentPage = 1;
      }

      _hasMore = newTransactions.length >= 20;
      _currentPage++;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading transactions: $e');
    }
  }

  /// Load wallet stats
  Future<void> loadStats() async {
    try {
      _stats = await _walletService.getStats();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading stats: $e');
    }
  }

  /// Initiate deposit
  Future<Map<String, dynamic>?> initiateDeposit({
    required double amount,
    required String provider,
  }) async {
    try {
      final response = await _walletService.initiateDeposit(
        amount: amount,
        provider: provider,
      );
      return {
        'payment_url': response.paymentUrl,
        'reference': response.reference,
        'amount': response.amount,
      };
    } catch (e) {
      if (kDebugMode) print('Error initiating deposit: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Request withdrawal
  Future<bool> requestWithdrawal({
    required double amount,
    required String provider,
    required String phoneNumber,
  }) async {
    try {
      await _walletService.withdraw(
        amount: amount,
        provider: provider,
        phoneNumber: phoneNumber,
      );
      await loadWallet(); // Refresh wallet data
      return true;
    } catch (e) {
      if (kDebugMode) print('Error requesting withdrawal: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update balance locally (for real-time updates)
  void updateBalance(double newBalance) {
    _balance = newBalance;
    notifyListeners();
  }

  void clear() {
    _balance = 0.0;
    _transactions = [];
    _stats = null;
    _error = null;
    notifyListeners();
  }
}
