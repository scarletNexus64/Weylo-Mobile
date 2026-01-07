import '../core/constants/api_constants.dart';
import 'api_client.dart';

class PromotionService {
  final ApiClient _api = ApiClient();

  /// Get promotion pricing options
  Future<List<Map<String, dynamic>>> getPricing() async {
    final response = await _api.get(ApiConstants.promotionsPricing);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  /// Promote a confession/post
  Future<Map<String, dynamic>> promotePost(int confessionId, int durationHours) async {
    final response = await _api.post(
      ApiConstants.promoteConfession(confessionId),
      data: {'duration_hours': durationHours},
    );
    return response.data;
  }

  /// Get user's promotions
  Future<Map<String, dynamic>> getMyPromotions({int page = 1}) async {
    final response = await _api.get(
      ApiConstants.myPromotions,
      queryParameters: {'page': page},
    );
    return response.data;
  }

  /// Cancel a promotion
  Future<Map<String, dynamic>> cancelPromotion(int promotionId) async {
    final response = await _api.delete(ApiConstants.cancelPromotion(promotionId));
    return response.data;
  }

  /// Get promotion stats
  Future<Map<String, dynamic>> getPromotionStats(int promotionId) async {
    final response = await _api.get(ApiConstants.promotionStats(promotionId));
    return response.data;
  }
}
