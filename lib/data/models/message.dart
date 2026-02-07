import 'user.dart';

class AnonymousMessage {
  final int id;
  final int senderId;
  final int recipientId;
  final String content;
  final int? replyToMessageId;
  final bool isRead;
  final bool isIdentityRevealed;
  final int? revealedViaSubscriptionId;
  final User? sender;
  final User? recipient;
  final AnonymousMessage? replyToMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AnonymousMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.replyToMessageId,
    this.isRead = false,
    this.isIdentityRevealed = false,
    this.revealedViaSubscriptionId,
    this.sender,
    this.recipient,
    this.replyToMessage,
    required this.createdAt,
    this.updatedAt,
  });

  String get senderInitials {
    if (sender != null) {
      return sender!.initials;
    }
    return '??';
  }

  factory AnonymousMessage.fromJson(Map<String, dynamic> json) {
    return AnonymousMessage(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? json['senderId'] ?? 0,
      recipientId: json['recipient_id'] ?? json['recipientId'] ?? 0,
      content: json['content'] ?? '',
      replyToMessageId: json['reply_to_message_id'] ?? json['replyToMessageId'],
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      isIdentityRevealed:
          json['is_identity_revealed'] ?? json['isIdentityRevealed'] ?? false,
      revealedViaSubscriptionId: json['revealed_via_subscription_id'],
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      recipient: json['recipient'] != null
          ? User.fromJson(json['recipient'])
          : null,
      replyToMessage: json['reply_to_message'] != null
          ? AnonymousMessage.fromJson(json['reply_to_message'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'reply_to_message_id': replyToMessageId,
      'is_read': isRead,
      'is_identity_revealed': isIdentityRevealed,
      'revealed_via_subscription_id': revealedViaSubscriptionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class MessageStats {
  final int totalReceived;
  final int totalSent;
  final int unreadCount;
  final int revealedCount;

  MessageStats({
    this.totalReceived = 0,
    this.totalSent = 0,
    this.unreadCount = 0,
    this.revealedCount = 0,
  });

  factory MessageStats.fromJson(Map<String, dynamic> json) {
    return MessageStats(
      totalReceived: json['total_received'] ?? json['totalReceived'] ?? 0,
      totalSent: json['total_sent'] ?? json['totalSent'] ?? 0,
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
      revealedCount: json['revealed_count'] ?? json['revealedCount'] ?? 0,
    );
  }
}
