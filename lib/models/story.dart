import 'user.dart';

enum StoryType { image, video, text }
enum StoryStatus { active, expired }

class Story {
  final int id;
  final int userId;
  final StoryType type;
  final String? mediaUrl;
  final String? content;
  final int duration;
  final StoryStatus status;
  final int viewsCount;
  final String? backgroundColor;
  final DateTime expiresAt;
  final User? user;
  final List<StoryView>? viewers;
  final bool isViewed;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.userId,
    this.type = StoryType.text,
    this.mediaUrl,
    this.content,
    this.duration = 5,
    this.status = StoryStatus.active,
    this.viewsCount = 0,
    this.backgroundColor,
    required this.expiresAt,
    this.user,
    this.viewers,
    this.isViewed = false,
    required this.createdAt,
  });

  bool get isExpired => status == StoryStatus.expired || DateTime.now().isAfter(expiresAt);
  bool get isText => type == StoryType.text;
  bool get isImage => type == StoryType.image;
  bool get isVideo => type == StoryType.video;

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      type: _parseType(json['type']),
      mediaUrl: json['media_url'] ?? json['mediaUrl'],
      content: json['content'],
      duration: json['duration'] ?? 5,
      status: json['status'] == 'expired' ? StoryStatus.expired : StoryStatus.active,
      viewsCount: json['views_count'] ?? json['viewsCount'] ?? 0,
      backgroundColor: json['background_color'] ?? json['backgroundColor'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(hours: 24)),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      viewers: json['viewers'] != null && json['viewers'] is List
          ? (json['viewers'] as List).map((v) => StoryView.fromJson(v)).toList()
          : null,
      isViewed: json['is_viewed'] ?? json['isViewed'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  static StoryType _parseType(String? type) {
    switch (type) {
      case 'image':
        return StoryType.image;
      case 'video':
        return StoryType.video;
      default:
        return StoryType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'media_url': mediaUrl,
      'content': content,
      'duration': duration,
      'status': status.name,
      'views_count': viewsCount,
      'background_color': backgroundColor,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class StoryView {
  final int id;
  final int storyId;
  final int userId;
  final User? user;
  final DateTime viewedAt;

  StoryView({
    required this.id,
    required this.storyId,
    required this.userId,
    this.user,
    required this.viewedAt,
  });

  factory StoryView.fromJson(Map<String, dynamic> json) {
    return StoryView(
      id: json['id'] ?? 0,
      storyId: json['story_id'] ?? json['storyId'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      viewedAt: json['viewed_at'] != null
          ? DateTime.parse(json['viewed_at'])
          : DateTime.now(),
    );
  }
}

class UserStories {
  final User user;
  final List<Story> stories;
  final bool hasUnviewed;

  UserStories({
    required this.user,
    required this.stories,
    this.hasUnviewed = false,
  });

  factory UserStories.fromJson(Map<String, dynamic> json) {
    final storiesData = json['stories'];
    List<Story> stories = [];
    if (storiesData is List) {
      stories = storiesData.map((s) => Story.fromJson(s)).toList();
    }

    return UserStories(
      user: User.fromJson(json['user']),
      stories: stories,
      hasUnviewed: json['has_unviewed'] ?? json['hasUnviewed'] ?? false,
    );
  }
}

class StoryStats {
  final int totalStories;
  final int totalViews;
  final int activeStories;

  StoryStats({
    this.totalStories = 0,
    this.totalViews = 0,
    this.activeStories = 0,
  });

  factory StoryStats.fromJson(Map<String, dynamic> json) {
    return StoryStats(
      totalStories: json['total_stories'] ?? json['totalStories'] ?? 0,
      totalViews: json['total_views'] ?? json['totalViews'] ?? 0,
      activeStories: json['active_stories'] ?? json['activeStories'] ?? 0,
    );
  }
}
