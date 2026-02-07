import 'user.dart';

enum GiftTier { bronze, silver, gold, diamond }

class Gift {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String icon;
  final String? animation;
  final double price;
  final GiftTier tier;
  final int categoryId;
  final String? backgroundColor;
  final GiftCategory? category;
  final DateTime? createdAt;

  Gift({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.icon,
    this.animation,
    required this.price,
    this.tier = GiftTier.bronze,
    required this.categoryId,
    this.backgroundColor,
    this.category,
    this.createdAt,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      icon: json['icon'] ?? '',
      animation: json['animation'],
      price: (json['price'] ?? 0).toDouble(),
      tier: _parseTier(json['tier']),
      categoryId: json['gift_category_id'] ?? json['categoryId'] ?? 0,
      backgroundColor: json['background_color'] ?? json['backgroundColor'],
      category: json['category'] != null
          ? GiftCategory.fromJson(json['category'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  static GiftTier _parseTier(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'silver':
        return GiftTier.silver;
      case 'gold':
        return GiftTier.gold;
      case 'diamond':
        return GiftTier.diamond;
      default:
        return GiftTier.bronze;
    }
  }

  String get tierName {
    switch (tier) {
      case GiftTier.silver:
        return 'Argent';
      case GiftTier.gold:
        return 'Or';
      case GiftTier.diamond:
        return 'Diamant';
      default:
        return 'Bronze';
    }
  }

  // Alias for icon to support imageUrl in gift_bottom_sheet
  String? get imageUrl => icon.isNotEmpty ? icon : null;
}

class GiftCategory {
  final int id;
  final String name;
  final String? icon;
  final int? giftsCount;

  GiftCategory({
    required this.id,
    required this.name,
    this.icon,
    this.giftsCount,
  });

  factory GiftCategory.fromJson(Map<String, dynamic> json) {
    return GiftCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
      giftsCount: json['gifts_count'] ?? json['giftsCount'],
    );
  }
}

class GiftTransaction {
  final int id;
  final int senderId;
  final int recipientId;
  final int giftId;
  final String? message;
  final double amount;
  final double platformFee;
  final double recipientAmount;
  final User? sender;
  final User? recipient;
  final Gift? gift;
  final DateTime createdAt;

  GiftTransaction({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.giftId,
    this.message,
    required this.amount,
    this.platformFee = 0,
    required this.recipientAmount,
    this.sender,
    this.recipient,
    this.gift,
    required this.createdAt,
  });

  factory GiftTransaction.fromJson(Map<String, dynamic> json) {
    return GiftTransaction(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? json['senderId'] ?? 0,
      recipientId: json['recipient_id'] ?? json['recipientId'] ?? 0,
      giftId: json['gift_id'] ?? json['giftId'] ?? 0,
      message: json['message'],
      amount: (json['amount'] ?? 0).toDouble(),
      platformFee: (json['platform_fee'] ?? json['platformFee'] ?? 0)
          .toDouble(),
      recipientAmount:
          (json['recipient_amount'] ?? json['recipientAmount'] ?? 0).toDouble(),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      recipient: json['recipient'] != null
          ? User.fromJson(json['recipient'])
          : null,
      gift: json['gift'] != null ? Gift.fromJson(json['gift']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class GiftStats {
  final int totalSent;
  final int totalReceived;
  final double totalSpent;
  final double totalEarned;

  GiftStats({
    this.totalSent = 0,
    this.totalReceived = 0,
    this.totalSpent = 0,
    this.totalEarned = 0,
  });

  factory GiftStats.fromJson(Map<String, dynamic> json) {
    return GiftStats(
      totalSent: json['total_sent'] ?? json['totalSent'] ?? 0,
      totalReceived: json['total_received'] ?? json['totalReceived'] ?? 0,
      totalSpent: (json['total_spent'] ?? json['totalSpent'] ?? 0).toDouble(),
      totalEarned: (json['total_earned'] ?? json['totalEarned'] ?? 0)
          .toDouble(),
    );
  }
}
