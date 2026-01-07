import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/story.dart';
import 'api_client.dart';

class StoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<UserStories>> getFeed() async {
    final response = await _apiClient.get(ApiConstants.stories);
    final data = response.data['stories'] ?? response.data['data'] ?? response.data;

    // Handle case where data is a Map instead of List
    if (data is Map) {
      return [];
    }
    if (data is! List) {
      return [];
    }
    return data.map((s) => UserStories.fromJson(s)).toList();
  }

  Future<List<Story>> getMyStories() async {
    final response = await _apiClient.get(ApiConstants.storiesMyStories);
    final data = response.data['stories'] ?? response.data['data'] ?? response.data;

    // Handle case where data is a Map instead of List
    if (data is Map) {
      return [];
    }
    if (data is! List) {
      return [];
    }
    return data.map((s) => Story.fromJson(s)).toList();
  }

  Future<List<Story>> getUserStories(String username) async {
    final response = await _apiClient.get('${ApiConstants.stories}/user/$username');
    final data = response.data['stories'] ?? response.data['data'] ?? response.data;

    // Handle case where data is a Map instead of List
    if (data is Map) {
      return [];
    }
    if (data is! List) {
      return [];
    }
    return data.map((s) => Story.fromJson(s)).toList();
  }

  Future<Story> getStory(int id) async {
    final response = await _apiClient.get('${ApiConstants.stories}/$id');
    return Story.fromJson(response.data['story'] ?? response.data);
  }

  Future<Story> createTextStory({
    required String content,
    String? backgroundColor,
    int duration = 5,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.stories,
      data: {
        'type': 'text',
        'content': content,
        'background_color': backgroundColor,
        'duration': duration,
      },
    );
    return Story.fromJson(response.data['story'] ?? response.data);
  }

  Future<Story> createMediaStory({
    required String filePath,
    required String type,
    String? content,
    int duration = 5,
  }) async {
    final formData = FormData.fromMap({
      'type': type,
      'media': await MultipartFile.fromFile(filePath),
      'content': content,
      'duration': duration,
    });

    final response = await _apiClient.uploadFile(
      ApiConstants.stories,
      data: formData,
    );
    return Story.fromJson(response.data['story'] ?? response.data);
  }

  // Unified method for creating stories
  Future<Story> createStory({
    File? media,
    String? text,
    String? backgroundColor,
    String type = 'text',
    int duration = 5,
  }) async {
    if (media != null) {
      return createMediaStory(
        filePath: media.path,
        type: type,
        content: text,
        duration: duration,
      );
    } else {
      return createTextStory(
        content: text ?? '',
        backgroundColor: backgroundColor,
        duration: duration,
      );
    }
  }

  Future<bool> viewStory(int storyId) async {
    final response = await _apiClient.post('${ApiConstants.stories}/$storyId/view');
    return response.data['success'] ?? true;
  }

  // Alias for story viewer
  Future<bool> markAsViewed(int storyId) async {
    return viewStory(storyId);
  }

  Future<List<StoryView>> getViewers(int storyId) async {
    final response = await _apiClient.get('${ApiConstants.stories}/$storyId/viewers');
    final data = response.data['viewers'] ?? response.data['data'] ?? [];
    return (data as List).map((v) => StoryView.fromJson(v)).toList();
  }

  Future<bool> deleteStory(int storyId) async {
    final response = await _apiClient.delete('${ApiConstants.stories}/$storyId');
    return response.data['success'] ?? true;
  }

  Future<StoryStats> getStats() async {
    final response = await _apiClient.get(ApiConstants.storiesStats);
    return StoryStats.fromJson(response.data);
  }
}
