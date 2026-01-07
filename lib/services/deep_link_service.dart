import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initialize(BuildContext context) async {
    // Handle initial link if app was started from a link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(context, initialUri);
    }

    // Handle links when app is in foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(context, uri);
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  void _handleDeepLink(BuildContext context, Uri uri) {
    debugPrint('Deep link received: $uri');

    final path = uri.path;
    final pathSegments = uri.pathSegments;

    // Handle different deep link patterns
    if (path.startsWith('/u/') && pathSegments.length >= 2) {
      // User profile: weylo://u/username or https://weylo.app/u/username
      final username = pathSegments[1];
      context.push('/u/$username');
    } else if (path.startsWith('/post/') && pathSegments.length >= 2) {
      // Post detail: weylo://post/123 or https://weylo.app/post/123
      final postId = pathSegments[1];
      context.push('/post/$postId');
    } else if (path.startsWith('/chat/') && pathSegments.length >= 2) {
      // Chat conversation: weylo://chat/123
      final chatId = pathSegments[1];
      context.push('/chat/$chatId');
    } else if (path.startsWith('/stories/') && pathSegments.length >= 2) {
      // Stories: weylo://stories/userId
      final userId = pathSegments[1];
      context.push('/stories/$userId');
    } else if (path == '/wallet') {
      // Wallet: weylo://wallet
      context.push('/wallet');
    } else if (path == '/premium') {
      // Premium: weylo://premium
      context.push('/premium');
    } else {
      // Default to home
      context.go('/');
    }
  }

  /// Generate a shareable link for a post
  static String getPostShareLink(int postId) {
    return 'https://weylo.app/post/$postId';
  }

  /// Generate a shareable link for a user profile
  static String getProfileShareLink(String username) {
    return 'https://weylo.app/u/$username';
  }

  /// Generate an app deep link for a post
  static String getPostDeepLink(int postId) {
    return 'weylo://post/$postId';
  }

  /// Generate an app deep link for a user profile
  static String getProfileDeepLink(String username) {
    return 'weylo://u/$username';
  }
}
