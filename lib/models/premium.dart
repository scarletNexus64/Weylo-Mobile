enum SubscriptionType { conversation, message, story }

enum SubscriptionStatus { active, pending, expired, cancelled }

enum PremiumPassStatus { active, pending, expired, cancelled }

class PremiumSubscription {
  final int id;
  final int subscriberId;
  final int targetUserId;
  final SubscriptionType type;
  final double amount;
  final DateTime? expiresAt;
  final bool autoRenew;
  final SubscriptionStatus status;
  final DateTime createdAt;

  PremiumSubscription({
    required this.id,
    required this.subscriberId,
    required this.targetUserId,
    required this.type,
    required this.amount,
    this.expiresAt,
    this.autoRenew = false,
    this.status = SubscriptionStatus.active,
    required this.createdAt,
  });

  bool get isActive =>
      status == SubscriptionStatus.active &&
      (expiresAt == null || DateTime.now().isBefore(expiresAt!));

  String get typeLabel {
    switch (type) {
      case SubscriptionType.conversation:
        return 'Conversation';
      case SubscriptionType.message:
        return 'Message';
      case SubscriptionType.story:
        return 'Story';
    }
  }

  factory PremiumSubscription.fromJson(Map<String, dynamic> json) {
    return PremiumSubscription(
      id: json['id'] ?? 0,
      subscriberId: json['subscriber_id'] ?? json['subscriberId'] ?? 0,
      targetUserId: json['target_user_id'] ?? json['targetUserId'] ?? 0,
      type: _parseType(json['type']),
      amount: (json['amount'] ?? 0).toDouble(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      autoRenew: json['auto_renew'] ?? json['autoRenew'] ?? false,
      status: _parseStatus(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  static SubscriptionType _parseType(String? type) {
    switch (type) {
      case 'conversation':
        return SubscriptionType.conversation;
      case 'message':
        return SubscriptionType.message;
      case 'story':
        return SubscriptionType.story;
      default:
        return SubscriptionType.message;
    }
  }

  static SubscriptionStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return SubscriptionStatus.active;
      case 'pending':
        return SubscriptionStatus.pending;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      default:
        return SubscriptionStatus.pending;
    }
  }
}

class PremiumPass {
  final int id;
  final int userId;
  final double amount;
  final DateTime startsAt;
  final DateTime expiresAt;
  final bool autoRenew;
  final PremiumPassStatus status;
  final DateTime createdAt;

  PremiumPass({
    required this.id,
    required this.userId,
    required this.amount,
    required this.startsAt,
    required this.expiresAt,
    this.autoRenew = false,
    this.status = PremiumPassStatus.active,
    required this.createdAt,
  });

  bool get isActive =>
      status == PremiumPassStatus.active && DateTime.now().isBefore(expiresAt);

  int get daysRemaining {
    if (!isActive) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  factory PremiumPass.fromJson(Map<String, dynamic> json) {
    return PremiumPass(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(days: 30)),
      autoRenew: json['auto_renew'] ?? json['autoRenew'] ?? false,
      status: _parseStatus(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  static PremiumPassStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return PremiumPassStatus.active;
      case 'pending':
        return PremiumPassStatus.pending;
      case 'expired':
        return PremiumPassStatus.expired;
      case 'cancelled':
        return PremiumPassStatus.cancelled;
      default:
        return PremiumPassStatus.pending;
    }
  }
}

class PremiumPricing {
  final double passPrice;
  final double subscriptionPrice;
  final String currency;

  PremiumPricing({
    required this.passPrice,
    required this.subscriptionPrice,
    this.currency = 'FCFA',
  });

  factory PremiumPricing.fromJson(Map<String, dynamic> json) {
    return PremiumPricing(
      passPrice: (json['pass_price'] ?? json['passPrice'] ?? 5000).toDouble(),
      subscriptionPrice:
          (json['subscription_price'] ?? json['subscriptionPrice'] ?? 450)
              .toDouble(),
      currency: json['currency'] ?? 'FCFA',
    );
  }
}
