import '../../core/constants/api_constants.dart';
import 'api_client.dart';

class FollowService {
  final ApiClient _api = ApiClient();

  /// Follow a user
  Future<Map<String, dynamic>> followUser(String username) async {
    final response = await _api.post(ApiConstants.userFollow(username));
    return response.data;
  }

  /// Unfollow a user
  Future<Map<String, dynamic>> unfollowUser(String username) async {
    final response = await _api.delete(ApiConstants.userFollow(username));
    return response.data;
  }

  /// Get followers list
  Future<Map<String, dynamic>> getFollowers(
    String username, {
    int page = 1,
  }) async {
    final response = await _api.get(
      ApiConstants.userFollowers(username),
      queryParameters: {'page': page},
    );
    return response.data;
  }

  /// Get following list
  Future<Map<String, dynamic>> getFollowing(
    String username, {
    int page = 1,
  }) async {
    final response = await _api.get(
      ApiConstants.userFollowing(username),
      queryParameters: {'page': page},
    );
    return response.data;
  }

  /// Check follow status
  Future<Map<String, dynamic>> checkFollowStatus(String username) async {
    final response = await _api.get(ApiConstants.userFollowStatus(username));
    return response.data;
  }
}
