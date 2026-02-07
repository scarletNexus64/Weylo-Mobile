import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import '../../core/constants/api_constants.dart';
import 'api_client.dart';

class StoryReplyService {
  final ApiClient _api = ApiClient();

  /// Get replies for a story (only for story owner)
  Future<Map<String, dynamic>> getReplies(int storyId, {int page = 1}) async {
    final response = await _api.get(
      ApiConstants.storyReplies(storyId),
      queryParameters: {'page': page},
    );
    return response.data;
  }

  /// Send a text reply to a story
  Future<Map<String, dynamic>> sendTextReply({
    required int storyId,
    required String content,
    bool isAnonymous = true,
  }) async {
    final response = await _api.post(
      ApiConstants.storyReplies(storyId),
      data: {'content': content, 'type': 'text', 'is_anonymous': isAnonymous},
    );
    return response.data;
  }

  /// Send an emoji reply to a story
  Future<Map<String, dynamic>> sendEmojiReply({
    required int storyId,
    required String emoji,
    bool isAnonymous = true,
  }) async {
    final response = await _api.post(
      ApiConstants.storyReplies(storyId),
      data: {'content': emoji, 'type': 'emoji', 'is_anonymous': isAnonymous},
    );
    return response.data;
  }

  /// Send a voice reply to a story
  Future<Map<String, dynamic>> sendVoiceReply({
    required int storyId,
    required File audioFile,
    String? voiceEffect,
    bool isAnonymous = true,
  }) async {
    final filename = audioFile.path.split('/').last;
    final extension = filename.split('.').last.toLowerCase();
    String contentType = 'audio/m4a';

    switch (extension) {
      case 'mp3':
        contentType = 'audio/mpeg';
        break;
      case 'm4a':
        contentType = 'audio/m4a';
        break;
      case 'aac':
        contentType = 'audio/aac';
        break;
      case 'wav':
        contentType = 'audio/wav';
        break;
      case 'ogg':
        contentType = 'audio/ogg';
        break;
      case 'webm':
        contentType = 'audio/webm';
        break;
    }

    debugPrint(
      'Sending story voice: $filename (ext=$extension, type=$contentType, path=${audioFile.path})',
    );

    final formData = FormData.fromMap({
      'type': 'voice',
      'is_anonymous': isAnonymous,
      if (voiceEffect != null) 'voice_effect': voiceEffect,
      'media': await MultipartFile.fromFile(
        audioFile.path,
        filename: filename,
        contentType: http_parser.MediaType.parse(contentType),
      ),
    });

    final response = await _api.post(
      ApiConstants.storyReplies(storyId),
      data: formData,
    );
    return response.data;
  }

  /// Send an image reply to a story
  Future<Map<String, dynamic>> sendImageReply({
    required int storyId,
    required File imageFile,
    String? caption,
    bool isAnonymous = true,
  }) async {
    final formData = FormData.fromMap({
      'type': 'image',
      'is_anonymous': isAnonymous,
      if (caption != null) 'content': caption,
      'media': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'image_reply.jpg',
      ),
    });

    final response = await _api.post(
      ApiConstants.storyReplies(storyId),
      data: formData,
    );
    return response.data;
  }

  /// Delete a reply
  Future<Map<String, dynamic>> deleteReply(int replyId) async {
    final response = await _api.delete('/stories/replies/$replyId');
    return response.data;
  }
}
