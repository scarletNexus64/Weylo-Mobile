import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/message.dart';
import 'api_client.dart';

class MessageService {
  final ApiClient _apiClient = ApiClient();

  Future<PaginatedMessages> getInbox({int page = 1, int perPage = AppConstants.defaultPageSize}) async {
    final response = await _apiClient.get(
      ApiConstants.messages,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedMessages.fromJson(response.data);
  }

  Future<PaginatedMessages> getSentMessages({int page = 1, int perPage = AppConstants.defaultPageSize}) async {
    final response = await _apiClient.get(
      ApiConstants.messagesSent,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedMessages.fromJson(response.data);
  }

  Future<AnonymousMessage> getMessage(int id) async {
    final response = await _apiClient.get('${ApiConstants.messages}/$id');
    return AnonymousMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<AnonymousMessage> sendMessage({
    required String username,
    required String content,
    int? replyToMessageId,
  }) async {
    final data = <String, dynamic>{
      'content': content,
    };
    if (replyToMessageId != null) {
      data['reply_to_message_id'] = replyToMessageId;
    }

    final response = await _apiClient.post(
      '${ApiConstants.messages}/send/$username',
      data: data,
    );
    return AnonymousMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<AnonymousMessage> sendAnonymousMessage({
    required String recipientUsername,
    required String content,
    bool isAnonymous = true,
    File? image,
    File? voice,
    String? voiceEffect,
  }) async {
    final formData = FormData.fromMap({
      'content': content,
      'is_anonymous': isAnonymous ? '1' : '0',
      if (voiceEffect != null) 'voice_effect': voiceEffect,
    });

    if (image != null) {
      formData.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(image.path, filename: 'image.jpg'),
      ));
    }

    if (voice != null) {
      formData.files.add(MapEntry(
        'voice',
        await MultipartFile.fromFile(voice.path, filename: 'voice.m4a'),
      ));
    }

    final response = await _apiClient.post(
      '${ApiConstants.messages}/send/$recipientUsername',
      data: formData,
    );
    return AnonymousMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<AnonymousMessage> revealIdentity(int messageId) async {
    final response = await _apiClient.post('${ApiConstants.messages}/$messageId/reveal');
    return AnonymousMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<Map<String, dynamic>> startConversation(int messageId) async {
    final response = await _apiClient.post('${ApiConstants.messages}/$messageId/start-conversation');
    return response.data;
  }

  Future<bool> reportMessage(int messageId, {String? reason}) async {
    final response = await _apiClient.post(
      '${ApiConstants.messages}/$messageId/report',
      data: reason != null ? {'reason': reason} : null,
    );
    return response.data['success'] ?? true;
  }

  Future<bool> deleteMessage(int messageId) async {
    final response = await _apiClient.delete('${ApiConstants.messages}/$messageId');
    return response.data['success'] ?? true;
  }

  Future<bool> markAllAsRead() async {
    final response = await _apiClient.post(ApiConstants.messagesReadAll);
    return response.data['success'] ?? true;
  }

  Future<MessageStats> getStats() async {
    final response = await _apiClient.get(ApiConstants.messagesStats);
    return MessageStats.fromJson(response.data);
  }
}

class PaginatedMessages {
  final List<AnonymousMessage> messages;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  PaginatedMessages({
    required this.messages,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.hasMore = false,
  });

  factory PaginatedMessages.fromJson(Map<String, dynamic> json) {
    final data = json['messages'] ?? json['data'] ?? [];
    final meta = json['meta'] ?? json;

    return PaginatedMessages(
      messages: (data as List).map((m) => AnonymousMessage.fromJson(m)).toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      total: meta['total'] ?? 0,
      hasMore: (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1),
    );
  }
}
