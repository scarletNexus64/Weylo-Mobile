import '../core/constants/api_constants.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {'login': identifier, 'password': password},
    );

    final authResponse = AuthResponse.fromJson(response.data);

    if (authResponse.token != null) {
      await _storage.saveToken(authResponse.token!);
      _apiClient.setToken(authResponse.token!);
    }

    if (authResponse.user != null) {
      await _storage.saveUser(authResponse.user!);
    }

    return authResponse;
  }

  Future<AuthResponse> register({
    required String firstName,
    String? lastName,
    required String username,
    String? email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);

    if (authResponse.token != null) {
      await _storage.saveToken(authResponse.token!);
      _apiClient.setToken(authResponse.token!);
    }

    if (authResponse.user != null) {
      await _storage.saveUser(authResponse.user!);
    }

    return authResponse;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } finally {
      await _storage.deleteToken();
      await _storage.deleteUser();
      _apiClient.clearToken();
    }
  }

  Future<void> logoutAll() async {
    try {
      await _apiClient.post(ApiConstants.logoutAll);
    } finally {
      await _storage.deleteToken();
      await _storage.deleteUser();
      _apiClient.clearToken();
    }
  }

  Future<User> getCurrentUser() async {
    final response = await _apiClient.get(ApiConstants.me);
    final user = User.fromJson(response.data['user'] ?? response.data);
    await _storage.saveUser(user);
    return user;
  }

  Future<bool> verifyIdentity({
    required String phone,
    required String firstName,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.verifyIdentity,
      data: {'phone': phone, 'first_name': firstName},
    );
    return response.data['success'] ?? false;
  }

  Future<bool> resetPasswordByPhone({
    required String phone,
    required String firstName,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.resetPasswordByPhone,
      data: {
        'phone': phone,
        'first_name': firstName,
        'password': newPassword,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data['success'] ?? false;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null;
  }

  Future<User?> getSavedUser() async {
    return await _storage.getUser();
  }

  Future<void> updateFcmToken(String fcmToken) async {
    await _apiClient.post(
      ApiConstants.userFcmToken,
      data: {'fcm_token': fcmToken},
    );
    await _storage.saveFcmToken(fcmToken);
  }
}

class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final User? user;

  AuthResponse({this.success = false, this.message, this.token, this.user});

  factory AuthResponse.fromJson(dynamic json) {
    final payload = _normalizePayload(json);
    final userJson = _mapFromJson(payload['user']);
    return AuthResponse(
      success: payload['success'] ?? true,
      message: payload['message'],
      token: payload['token'] ?? payload['access_token'],
      user: userJson != null ? User.fromJson(userJson) : null,
    );
  }

  static Map<String, dynamic>? _mapFromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return json;
    }
    if (json is List) {
      for (final entry in json) {
        if (entry is Map<String, dynamic>) {
          return entry;
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> _normalizePayload(dynamic json) {
    final map = _mapFromJson(json);
    if (map != null) {
      return map;
    }

    if (json is List && json.isNotEmpty) {
      return {'message': json.first.toString()};
    }

    if (json != null) {
      return {'message': json.toString()};
    }

    return {};
  }
}
