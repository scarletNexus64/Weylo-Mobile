import 'user.dart';

enum FlameLevel { none, yellow, orange, purple }

class Conversation {
  final int id;
  final int participantOneId;
  final int participantTwoId;
  final int streakCount;
  final FlameLevel flameLevel;
  final int messageCount;
  final DateTime? lastMessageAt;
  final User? participantOne;
  final User? participantTwo;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isIdentityRevealed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.participantOneId,
    required this.participantTwoId,
    this.streakCount = 0,
    this.flameLevel = FlameLevel.none,
    this.messageCount = 0,
    this.lastMessageAt,
    this.participantOne,
    this.participantTwo,
    this.lastMessage,
    this.unreadCount = 0,
    this.isIdentityRevealed = false,
    required this.createdAt,
    this.updatedAt,
  });

  User? getOtherParticipant(int currentUserId) {
    if (participantOneId == currentUserId) {
      return participantTwo;
    }
    return participantOne;
  }

  String getFlameEmoji() {
    switch (flameLevel) {
      case FlameLevel.yellow:
        return '🔥';
      case FlameLevel.orange:
        return '🔥🔥';
      case FlameLevel.purple:
        return '💜🔥';
      default:
        return '';
    }
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? 0,
      participantOneId: json['participant_one_id'] ?? json['participantOneId'] ?? 0,
      participantTwoId: json['participant_two_id'] ?? json['participantTwoId'] ?? 0,
      streakCount: json['streak_count'] ?? json['streakCount'] ?? 0,
      flameLevel: _parseFlameLevel(json['flame_level'] ?? json['flameLevel']),
      messageCount: json['message_count'] ?? json['messageCount'] ?? 0,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      participantOne: json['participant_one'] != null
          ? User.fromJson(json['participant_one'])
          : null,
      participantTwo: json['participant_two'] != null
          ? User.fromJson(json['participant_two'])
          : null,
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
      isIdentityRevealed: json['is_identity_revealed'] ?? json['isIdentityRevealed'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  static FlameLevel _parseFlameLevel(String? level) {
    switch (level) {
      case 'yellow':
        return FlameLevel.yellow;
      case 'orange':
        return FlameLevel.orange;
      case 'purple':
        return FlameLevel.purple;
      default:
        return FlameLevel.none;
    }
  }

  Conversation copyWith({
    ChatMessage? lastMessage,
    int? unreadCount,
    int? messageCount,
    DateTime? lastMessageAt,
    bool? isIdentityRevealed,
  }) {
    return Conversation(
      id: id,
      participantOneId: participantOneId,
      participantTwoId: participantTwoId,
      streakCount: streakCount,
      flameLevel: flameLevel,
      messageCount: messageCount ?? this.messageCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      participantOne: participantOne,
      participantTwo: participantTwo,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isIdentityRevealed: isIdentityRevealed ?? this.isIdentityRevealed,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final String? type;
  final int? replyToId;
  final bool isRead;
  final User? sender;
  final ChatMessage? replyTo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.replyToId,
    this.isRead = false,
    this.sender,
    this.replyTo,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isGift => type == 'gift';
  bool get isSystem => type == 'system';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      conversationId: json['conversation_id'] ?? json['conversationId'] ?? 0,
      senderId: json['sender_id'] ?? json['senderId'] ?? 0,
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      replyToId: json['reply_to_id'] ?? json['replyToId'],
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      replyTo: json['reply_to'] != null
          ? ChatMessage.fromJson(json['reply_to'])
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
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'type': type,
      'reply_to_id': replyToId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
