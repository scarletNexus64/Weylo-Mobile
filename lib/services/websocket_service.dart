import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();

  WebSocketChannel? _channel;
  final StorageService _storage = StorageService();

  final _messageController = StreamController<WebSocketMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<WebSocketMessage> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await _storage.getToken();
      if (token == null) {
        if (kDebugMode) print('WebSocket: No token available');
        return;
      }

      final wsUrl = Uri.parse('${ApiConstants.wsUrl}/app/weylo?token=$token');

      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: _onError,
        cancelOnError: false,
      );

      _isConnected = true;
      _connectionController.add(true);
      _startHeartbeat();

      if (kDebugMode) print('WebSocket: Connected');
    } catch (e) {
      if (kDebugMode) print('WebSocket: Connection error - $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final message = WebSocketMessage.fromJson(json);

      if (kDebugMode) print('WebSocket: Received ${message.event}');

      _messageController.add(message);
    } catch (e) {
      if (kDebugMode) print('WebSocket: Error parsing message - $e');
    }
  }

  void _onDisconnected() {
    if (kDebugMode) print('WebSocket: Disconnected');
    _isConnected = false;
    _connectionController.add(false);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _onError(dynamic error) {
    if (kDebugMode) print('WebSocket: Error - $error');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        send('ping', {});
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void send(String event, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      if (kDebugMode) print('WebSocket: Cannot send - not connected');
      return;
    }

    try {
      final message = jsonEncode({
        'event': event,
        'data': data,
      });
      _channel!.sink.add(message);
    } catch (e) {
      if (kDebugMode) print('WebSocket: Error sending message - $e');
    }
  }

  void subscribeToChannel(String channel) {
    send('subscribe', {'channel': channel});
  }

  void unsubscribeFromChannel(String channel) {
    send('unsubscribe', {'channel': channel});
  }

  void subscribeToUserChannel(int userId) {
    subscribeToChannel('private-user.$userId');
  }

  void subscribeToConversation(int conversationId) {
    subscribeToChannel('presence-chat.$conversationId');
  }

  void unsubscribeFromConversation(int conversationId) {
    unsubscribeFromChannel('presence-chat.$conversationId');
  }

  void subscribeToGroup(int groupId) {
    subscribeToChannel('group.$groupId');
  }

  void unsubscribeFromGroup(int groupId) {
    unsubscribeFromChannel('group.$groupId');
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _channel?.sink.close();
    _isConnected = false;
    _connectionController.add(false);
    if (kDebugMode) print('WebSocket: Manually disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}

class WebSocketMessage {
  final String event;
  final String? channel;
  final Map<String, dynamic> data;

  WebSocketMessage({
    required this.event,
    this.channel,
    required this.data,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      event: json['event'] ?? '',
      channel: json['channel'],
      data: json['data'] ?? {},
    );
  }

  bool get isChatMessage => event == 'ChatMessageSent';
  bool get isGroupMessage => event == 'GroupMessageSent';
  bool get isGiftSent => event == 'GiftSent';
  bool get isNewMessage => event == 'MessageSent';
  bool get isPresenceUpdate => event == 'UserPresenceUpdated';
}
