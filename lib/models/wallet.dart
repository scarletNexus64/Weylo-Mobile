enum TransactionType { deposit, withdrawal, gift_sent, gift_received, premium, subscription }
enum TransactionStatus { pending, completed, failed, cancelled }
enum WithdrawalStatus { pending, processing, completed, rejected }

class WalletTransaction {
  final int id;
  final int userId;
  final TransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? description;
  final String? reference;
  final TransactionStatus status;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.description,
    this.reference,
    this.status = TransactionStatus.completed,
    required this.createdAt,
  });

  bool get isCredit => type == TransactionType.deposit || type == TransactionType.gift_received;
  bool get isDebit => !isCredit;

  String get typeLabel {
    switch (type) {
      case TransactionType.deposit:
        return 'Dépôt';
      case TransactionType.withdrawal:
        return 'Retrait';
      case TransactionType.gift_sent:
        return 'Cadeau envoyé';
      case TransactionType.gift_received:
        return 'Cadeau reçu';
      case TransactionType.premium:
        return 'Abonnement Premium';
      case TransactionType.subscription:
        return 'Souscription';
    }
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      type: _parseType(json['type']),
      amount: (json['amount'] ?? 0).toDouble(),
      balanceBefore: (json['balance_before'] ?? json['balanceBefore'] ?? 0).toDouble(),
      balanceAfter: (json['balance_after'] ?? json['balanceAfter'] ?? 0).toDouble(),
      description: json['description'],
      reference: json['reference'],
      status: _parseStatus(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  static TransactionType _parseType(String? type) {
    switch (type) {
      case 'deposit':
        return TransactionType.deposit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'gift_sent':
        return TransactionType.gift_sent;
      case 'gift_received':
        return TransactionType.gift_received;
      case 'premium':
        return TransactionType.premium;
      case 'subscription':
        return TransactionType.subscription;
      default:
        return TransactionType.deposit;
    }
  }

  static TransactionStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.completed;
    }
  }
}

class Withdrawal {
  final int id;
  final int userId;
  final double amount;
  final String provider;
  final String phoneNumber;
  final WithdrawalStatus status;
  final String? rejectionReason;
  final String? reference;
  final DateTime createdAt;
  final DateTime? processedAt;

  Withdrawal({
    required this.id,
    required this.userId,
    required this.amount,
    required this.provider,
    required this.phoneNumber,
    this.status = WithdrawalStatus.pending,
    this.rejectionReason,
    this.reference,
    required this.createdAt,
    this.processedAt,
  });

  String get statusLabel {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'En attente';
      case WithdrawalStatus.processing:
        return 'En cours';
      case WithdrawalStatus.completed:
        return 'Complété';
      case WithdrawalStatus.rejected:
        return 'Rejeté';
    }
  }

  String get providerLabel {
    switch (provider.toLowerCase()) {
      case 'mtn':
        return 'MTN Mobile Money';
      case 'orange':
        return 'Orange Money';
      default:
        return provider;
    }
  }

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      provider: json['provider'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      status: _parseStatus(json['status']),
      rejectionReason: json['rejection_reason'] ?? json['rejectionReason'],
      reference: json['reference'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
    );
  }

  static WithdrawalStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return WithdrawalStatus.pending;
      case 'processing':
        return WithdrawalStatus.processing;
      case 'completed':
        return WithdrawalStatus.completed;
      case 'rejected':
        return WithdrawalStatus.rejected;
      default:
        return WithdrawalStatus.pending;
    }
  }
}

class WithdrawalMethod {
  final String id;
  final String name;
  final String provider;
  final String? icon;
  final bool isAvailable;

  WithdrawalMethod({
    required this.id,
    required this.name,
    required this.provider,
    this.icon,
    this.isAvailable = true,
  });

  factory WithdrawalMethod.fromJson(Map<String, dynamic> json) {
    return WithdrawalMethod(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      provider: json['provider'] ?? '',
      icon: json['icon'],
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
    );
  }
}

class WalletStats {
  final double totalDeposits;
  final double totalWithdrawals;
  final double totalGiftsSent;
  final double totalGiftsReceived;
  final int transactionsCount;

  WalletStats({
    this.totalDeposits = 0,
    this.totalWithdrawals = 0,
    this.totalGiftsSent = 0,
    this.totalGiftsReceived = 0,
    this.transactionsCount = 0,
  });

  factory WalletStats.fromJson(Map<String, dynamic> json) {
    return WalletStats(
      totalDeposits: (json['total_deposits'] ?? json['totalDeposits'] ?? 0).toDouble(),
      totalWithdrawals: (json['total_withdrawals'] ?? json['totalWithdrawals'] ?? 0).toDouble(),
      totalGiftsSent: (json['total_gifts_sent'] ?? json['totalGiftsSent'] ?? 0).toDouble(),
      totalGiftsReceived: (json['total_gifts_received'] ?? json['totalGiftsReceived'] ?? 0).toDouble(),
      transactionsCount: json['transactions_count'] ?? json['transactionsCount'] ?? 0,
    );
  }
}
