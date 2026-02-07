import 'dart:async';
import 'package:get/get.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/auth_service.dart';
import '../../../data/providers/storage_service.dart';
import '../../../data/providers/user_service.dart';
import '../../../data/providers/websocket_service.dart';
import '../../../core/errors/exceptions.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  final WebSocketService _webSocket = WebSocketService();
  final UserService _userService = UserService();

  final _status = AuthStatus.initial.obs;
  final Rx<User?> _user = Rx<User?>(null);
  final RxString _error = ''.obs;
  Timer? _errorTimer;

  AuthStatus get status => _status.value;
  User? get user => _user.value;
  User? get currentUser => _user.value;
  String? get error => _error.value.isEmpty ? null : _error.value;
  bool get isAuthenticated => _status.value == AuthStatus.authenticated;
  bool get isLoading => _status.value == AuthStatus.loading;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  @override
  void onClose() {
    _errorTimer?.cancel();
    super.onClose();
  }

  Future<void> checkAuthStatus() async {
    _status.value = AuthStatus.loading;

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _user.value = await _authService.getSavedUser();
        if (_user.value != null) {
          _status.value = AuthStatus.authenticated;
          _connectWebSocket();
        } else {
          try {
            _user.value = await _authService.getCurrentUser();
            _status.value = AuthStatus.authenticated;
            _connectWebSocket();
          } catch (e) {
            await _authService.logout();
            _status.value = AuthStatus.unauthenticated;
          }
        }
      } else {
        _status.value = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status.value = AuthStatus.unauthenticated;
      _error.value = e.toString();
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _status.value = AuthStatus.loading;
    _error.value = '';

    try {
      final response = await _authService.login(
        identifier: identifier,
        password: password,
      );

      if (response.user != null) {
        _user.value = response.user;
        _status.value = AuthStatus.authenticated;
        _connectWebSocket();
        return true;
      } else {
        _status.value = AuthStatus.error;
        _error.value = response.message ?? 'Erreur de connexion';
        _scheduleErrorAutoClear();
        return false;
      }
    } on ValidationException catch (e) {
      _status.value = AuthStatus.error;
      _error.value = e.message;
      _scheduleErrorAutoClear();
      return false;
    } on AuthException catch (e) {
      _status.value = AuthStatus.error;
      _error.value = e.message;
      _scheduleErrorAutoClear();
      return false;
    } catch (e) {
      _status.value = AuthStatus.error;
      _error.value = e.toString();
      _scheduleErrorAutoClear();
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    String? lastName,
    required String username,
    String? email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    _status.value = AuthStatus.loading;
    _error.value = '';

    try {
      final response = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.user != null) {
        _user.value = response.user;
        _status.value = AuthStatus.authenticated;
        _connectWebSocket();
        return true;
      } else {
        _status.value = AuthStatus.error;
        _error.value = response.message ?? 'Erreur d\'inscription';
        _scheduleErrorAutoClear();
        return false;
      }
    } on ValidationException catch (e) {
      _status.value = AuthStatus.error;
      _error.value = e.message;
      if (e.errors != null) {
        final firstError = e.errors!.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          _error.value = firstError.first.toString();
        }
      }
      _scheduleErrorAutoClear();
      return false;
    } catch (e) {
      _status.value = AuthStatus.error;
      _error.value = e.toString();
      _scheduleErrorAutoClear();
      return false;
    }
  }

  Future<void> logout() async {
    _status.value = AuthStatus.loading;

    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors
    } finally {
      _user.value = null;
      _status.value = AuthStatus.unauthenticated;
      _webSocket.disconnect();
    }
  }

  Future<void> refreshUser() async {
    try {
      _user.value = await _authService.getCurrentUser();
    } catch (e) {
      // Handle error silently
    }
  }

  void updateUser(User user) {
    _user.value = user;
    _storage.saveUser(user);
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    if (_user.value == null) return;

    final currentSettings = _user.value!.settings ?? UserSettings();
    final newSettings = UserSettings(
      notificationsEnabled:
          settings['notifications_enabled'] ??
          currentSettings.notificationsEnabled,
      emailNotifications:
          settings['email_notifications'] ?? currentSettings.emailNotifications,
      pushNotifications:
          settings['push_notifications'] ?? currentSettings.pushNotifications,
      showOnlineStatus:
          settings['show_online_status'] ?? currentSettings.showOnlineStatus,
      allowAnonymousMessages: false,
      showNameOnPosts:
          settings['show_name_on_posts'] ?? currentSettings.showNameOnPosts,
      showPhotoOnPosts:
          settings['show_photo_on_posts'] ?? currentSettings.showPhotoOnPosts,
      language: settings['language'] ?? currentSettings.language,
      theme: settings['theme'] ?? currentSettings.theme,
    );

    _user.value = await _userService.updateSettings(newSettings);
  }

  void _connectWebSocket() {
    if (_user.value != null) {
      _webSocket.connect();
      _webSocket.subscribeToUserChannel(_user.value!.id);
    }
  }

  void clearError() {
    _errorTimer?.cancel();
    _error.value = '';
  }

  void _scheduleErrorAutoClear() {
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 6), () {
      if (_error.value.isNotEmpty) {
        _error.value = '';
      }
    });
  }
}
