import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _userId;
  bool get isConnected => _isConnected;

  void connect(String token, String userId) {
    _userId = userId;
    _socket = io.io(AppConstants.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token},
    });
    _socket!.onConnect((_) { _isConnected = true; });
    _socket!.onDisconnect((_) { _isConnected = false; });
    _socket!.onConnectError((_) { _isConnected = false; });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // Backend event names: join:project, leave:project, join:chat, leave:chat
  void joinProject(String id) => _socket?.emit('join:project', {'projectId': id, 'displayName': ''});
  void leaveProject(String id) => _socket?.emit('leave:project', {'projectId': id});
  void joinChat(String id) => _socket?.emit('join:chat', {'chatId': id});
  void leaveChat(String id) => _socket?.emit('leave:chat', {'chatId': id});
  void on(String event, Function(dynamic) cb) => _socket?.on(event, cb);
  void off(String event) => _socket?.off(event);
  void emit(String event, dynamic data) => _socket?.emit(event, data);

  void onNewMessage(Function(dynamic) cb) => on('chat:message', cb);
  void onAiTyping(Function(dynamic) cb) => on('chat:ai-typing', cb);
  void onAiCodeWriting(Function(dynamic) cb) => on('chat:ai-code-writing', cb);
  void onAiComplete(Function(dynamic) cb) => on('chat:ai-complete', cb);
  void onBuildStatus(Function(dynamic) cb) => on('project:build-status', cb);
  void onFileUpdate(Function(dynamic) cb) => on('project:file-update', cb);
  void onUserOnline(Function(dynamic) cb) => on('user:online', cb);
  void onUserOffline(Function(dynamic) cb) => on('user:offline', cb);
  void onQueueRequest(Function(dynamic) cb) => on('queue:request', cb);
  void onQueueComplete(Function(dynamic) cb) => on('queue:complete', cb);
}
