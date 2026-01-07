import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/confession.dart';
import 'api_client.dart';

class ConfessionService {
  final ApiClient _apiClient = ApiClient();

  // Alias for feed provider
  Future<PaginatedConfessions> getConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    return getPublicConfessions(page: page, perPage: perPage);
  }

  Future<PaginatedConfessions> getPublicConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.confessions,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedConfessions.fromJson(response.data);
  }

  Future<PaginatedConfessions> getUserConfessions(
    int userId, {
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.users}/$userId/confessions',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedConfessions.fromJson(response.data);
  }

  Future<PaginatedConfessions> getReceivedConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.confessionsReceived,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedConfessions.fromJson(response.data);
  }

  Future<PaginatedConfessions> getSentConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.confessionsSent,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedConfessions.fromJson(response.data);
  }

  Future<PaginatedConfessions> getLikedConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final response = await _apiClient.get(
      '/confessions/liked',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedConfessions.fromJson(response.data);
  }

  Future<Confession> getConfession(int id) async {
    final response = await _apiClient.get('${ApiConstants.confessions}/$id');
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<Confession> createConfession({
    required String content,
    String type = 'public',
    String? recipientUsername,
    File? image,
  }) async {
    // If there's an image, use multipart form data
    if (image != null) {
      final formData = FormData.fromMap({
        'content': content,
        'type': type,
        if (recipientUsername != null) 'recipient_username': recipientUsername,
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      });

      final response = await _apiClient.uploadFile(
        ApiConstants.confessions,
        data: formData,
      );
      return Confession.fromJson(response.data['confession'] ?? response.data);
    }

    // No image, use regular JSON
    final data = <String, dynamic>{
      'content': content,
      'type': type,
    };
    if (recipientUsername != null) {
      data['recipient_username'] = recipientUsername;
    }

    final response = await _apiClient.post(
      ApiConstants.confessions,
      data: data,
    );
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<Confession> likeConfession(int confessionId) async {
    final response = await _apiClient.post('${ApiConstants.confessions}/$confessionId/like');
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<Confession> unlikeConfession(int confessionId) async {
    final response = await _apiClient.delete('${ApiConstants.confessions}/$confessionId/like');
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<Confession> revealIdentity(int confessionId) async {
    final response = await _apiClient.post('${ApiConstants.confessions}/$confessionId/reveal');
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<bool> reportConfession(int confessionId, {String? reason}) async {
    final response = await _apiClient.post(
      '${ApiConstants.confessions}/$confessionId/report',
      data: reason != null ? {'reason': reason} : null,
    );
    return response.data['success'] ?? true;
  }

  Future<List<ConfessionComment>> getComments(int confessionId) async {
    final response = await _apiClient.get('${ApiConstants.confessions}/$confessionId/comments');
    final data = response.data['comments'] ?? response.data['data'] ?? [];
    return (data as List).map((c) => ConfessionComment.fromJson(c)).toList();
  }

  Future<ConfessionComment> addComment(int confessionId, String content) async {
    final response = await _apiClient.post(
      '${ApiConstants.confessions}/$confessionId/comments',
      data: {'content': content},
    );
    return ConfessionComment.fromJson(response.data['comment'] ?? response.data);
  }

  Future<bool> deleteComment(int confessionId, int commentId) async {
    final response = await _apiClient.delete(
      '${ApiConstants.confessions}/$confessionId/comments/$commentId',
    );
    return response.data['success'] ?? true;
  }

  Future<bool> deleteConfession(int confessionId) async {
    final response = await _apiClient.delete('${ApiConstants.confessions}/$confessionId');
    return response.data['success'] ?? true;
  }

  Future<ConfessionStats> getStats() async {
    final response = await _apiClient.get(ApiConstants.confessionsStats);
    return ConfessionStats.fromJson(response.data);
  }
}

class PaginatedConfessions {
  final List<Confession> confessions;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  PaginatedConfessions({
    required this.confessions,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.hasMore = false,
  });

  factory PaginatedConfessions.fromJson(Map<String, dynamic> json) {
    final data = json['confessions'] ?? json['data'] ?? [];
    final meta = json['meta'] ?? json;

    return PaginatedConfessions(
      confessions: (data as List).map((c) => Confession.fromJson(c)).toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      total: meta['total'] ?? 0,
      hasMore: (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1),
    );
  }
}
