import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../config/constants.dart';

class AiModelInfo {
  final String id;
  final String displayName;
  final String userGroup;
  AiModelInfo({required this.id, required this.displayName, required this.userGroup});
  factory AiModelInfo.fromJson(Map<String, dynamic> j) => AiModelInfo(id: j['id'] ?? '', displayName: j['display_name'] ?? '', userGroup: j['user_group'] ?? 'free');
}

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();

  List<ChatModel> _generalChats = [];
  ChatModel? _currentChat;
  List<MessageModel> _messages = [];
  List<FileModel> _chatFiles = [];
  List<AiModelInfo> _availableModels = [];
  String? _selectedModelId;
  bool _isLoading = false;
  bool _isSending = false;
  bool _aiTyping = false;
  String? _currentCode;
  String? _currentFileName;
  String _searchQuery = '';
  List<Map<String, dynamic>> _lastFileOps = [];

  List<ChatModel> get generalChats => _generalChats;
  String get searchQuery => _searchQuery;
  List<ChatModel> get filteredChats => _searchQuery.isEmpty ? _generalChats
    : _generalChats.where((c) => c.title.toLowerCase().contains(_searchQuery.toLowerCase()) || (c.lastMessage?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
  ChatModel? get currentChat => _currentChat;
  List<MessageModel> get messages => _messages;
  List<FileModel> get chatFiles => _chatFiles;
  List<AiModelInfo> get availableModels => _availableModels;
  String? get selectedModelId => _selectedModelId;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get aiTyping => _aiTyping;
  String? get currentCode => _currentCode;
  String? get currentFileName => _currentFileName;
  List<Map<String, dynamic>> get lastFileOps => _lastFileOps;

  // === Models ===
  Future<void> fetchModels() async {
    final r = await _api.get(ApiEndpoints.aiModels);
    if (r.success && r.data != null) {
      final list = r.data['models'] ?? r.data;
      if (list is List) _availableModels = list.map((m) => AiModelInfo.fromJson(m)).toList();
      if (_availableModels.isNotEmpty && _selectedModelId == null) _selectedModelId = _availableModels.first.id;
      notifyListeners();
    }
  }

  void selectModel(String modelId) { _selectedModelId = modelId; notifyListeners(); }

  void setSearchQuery(String q) { _searchQuery = q; notifyListeners(); }

  String getExportUrl(String chatId) => '${AppConstants.baseUrl}${ApiEndpoints.chatExport(chatId)}';

  Future<String?> getExportToken() async => await _api.token;

  // === Chats ===
  Future<void> fetchGeneralChats() async {
    _isLoading = true; notifyListeners();
    final r = await _api.get(ApiEndpoints.chats);
    _isLoading = false;
    if (r.success && r.data != null) {
      final list = r.data['chats'] ?? r.data;
      if (list is List) _generalChats = list.map((c) => ChatModel.fromJson(c)).toList();
    }
    notifyListeners();
  }

  Future<ChatModel?> createChat({String? projectId, String title = 'New Chat'}) async {
    final r = await _api.post(ApiEndpoints.chats, body: {'title': title, if (projectId != null) 'projectId': projectId});
    if (r.success && r.data != null) {
      final c = ChatModel.fromJson(r.data['chat'] ?? r.data);
      if (projectId == null) _generalChats.insert(0, c);
      notifyListeners();
      return c;
    }
    return null;
  }

  Future<void> openChat(String chatId) async {
    _isLoading = true; _messages = []; _chatFiles = []; _lastFileOps = []; notifyListeners();
    final r = await _api.get(ApiEndpoints.chatMessages(chatId));
    if (r.success && r.data != null) {
      if (r.data['messages'] is List) _messages = (r.data['messages'] as List).map((m) => MessageModel.fromJson(m)).toList();
      if (r.data['chat'] != null) _currentChat = ChatModel.fromJson(r.data['chat']);
      else _currentChat = ChatModel(id: chatId, userId: '', title: 'Chat', createdAt: DateTime.now(), updatedAt: DateTime.now());

      // Fetch files for both project and general chats
      if (_currentChat?.projectId != null) {
        await _fetchProjectFiles(_currentChat!.projectId!);
      } else {
        await _fetchChatFiles(chatId);
      }
    }
    _isLoading = false; notifyListeners();
    _socket.joinChat(chatId);
    _setupChatListeners();
  }

  Future<void> _fetchProjectFiles(String projectId) async {
    final r = await _api.get(ApiEndpoints.projectFiles(projectId));
    if (r.success && r.data != null) {
      final list = r.data['files'] ?? r.data;
      if (list is List) _chatFiles = list.map((f) => FileModel.fromJson(f)).toList();
    }
  }

  Future<void> _fetchChatFiles(String chatId) async {
    final r = await _api.get('${ApiEndpoints.chatDetail(chatId)}/files');
    if (r.success && r.data != null) {
      final list = r.data['files'] ?? r.data;
      if (list is List) _chatFiles = list.map((f) => FileModel.fromJson(f)).toList();
    }
  }

  Future<void> refreshFiles() async {
    if (_currentChat == null) return;
    if (_currentChat!.projectId != null) {
      await _fetchProjectFiles(_currentChat!.projectId!);
    } else {
      await _fetchChatFiles(_currentChat!.id);
    }
    notifyListeners();
  }

  // === Messages ===
  Future<void> sendMessage(String content) async {
    if (_currentChat == null || content.trim().isEmpty) return;
    final userMsg = MessageModel(id: DateTime.now().millisecondsSinceEpoch.toString(), chatId: _currentChat!.id, role: 'user', content: content, createdAt: DateTime.now());
    _messages.add(userMsg);
    _isSending = true; _aiTyping = true; _lastFileOps = []; notifyListeners();

    final r = await _api.post(ApiEndpoints.chatMessages(_currentChat!.id), body: {'content': content});
    _isSending = false; _aiTyping = false;
    if (r.success && r.data != null) {
      final msgData = r.data['message'] ?? r.data;
      var msg = MessageModel.fromJson(msgData);
      msg = _cleanAiResponse(msg);
      _messages.add(msg);

      // Track file operations from AI response
      final files = r.data['files'];
      if (files is List && files.isNotEmpty) {
        _lastFileOps = files.map((f) => Map<String, dynamic>.from(f)).toList();
        // Refresh file tree for both project and general chats
        await refreshFiles();
      }
    } else {
      _messages.add(MessageModel(id: '${DateTime.now().millisecondsSinceEpoch}_err', chatId: _currentChat!.id, role: 'ai', content: r.message ?? 'Sorry, something went wrong.', createdAt: DateTime.now()));
    }
    _currentCode = null; _currentFileName = null; notifyListeners();
  }

  MessageModel _cleanAiResponse(MessageModel msg) {
    if (!msg.isAi) return msg;
    var text = msg.content.trim();

    // Case 1: Pure JSON {"message":"...", "files":[...]}
    if (text.startsWith('{') && text.contains('"files"')) {
      try {
        final parsed = jsonDecode(text);
        if (parsed is Map) {
          final m = parsed['message']?.toString() ?? '';
          final f = parsed['files'] as List?;
          if (m.isNotEmpty) text = m;
          else if (f != null && f.isNotEmpty) text = 'Created ${f.length} file(s): ${f.map((x) => x['path'] ?? '').join(', ')}';
        }
      } catch (_) {
        final m = RegExp(r'"message"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(text);
        if (m != null) text = m.group(1)!.replaceAll(r'\"', '"').replaceAll(r'\n', '\n');
      }
    }

    // Case 2: Text with ```json block mixed in
    if (text.contains('```json') || text.contains('```')) {
      // Extract text parts (before and after code blocks)
      final parts = <String>[];
      final remaining = text.replaceAllMapped(RegExp(r'```(?:json)?\s*\{[\s\S]*?\}\s*```', multiLine: true), (match) {
        // Try parse the JSON block to get file info
        final jsonStr = match.group(0)!.replaceAll(RegExp(r'```(?:json)?\s*'), '').replaceAll(RegExp(r'\s*```'), '');
        try {
          final parsed = jsonDecode(jsonStr);
          if (parsed is Map && parsed['files'] is List) {
            final files = parsed['files'] as List;
            parts.add('[${files.length} file(s): ${files.map((f) => f['path'] ?? '').join(', ')}]');
          }
        } catch (_) {}
        return '';
      }).trim();
      text = remaining.isNotEmpty ? remaining : parts.join('\n');
      if (text.isEmpty) text = msg.content; // fallback
    }

    // Case 3: Just strip remaining code blocks for display
    text = text.replaceAll(RegExp(r'```\w*\n?'), '').trim();

    // Remove any remaining raw JSON objects
    if (text.contains('"content":') && text.contains('"path":')) {
      final clean = text.replaceAll(RegExp(r'\{[^}]*"path"\s*:.*?\}', dotAll: true), '').trim();
      if (clean.isNotEmpty) text = clean;
    }

    text = text.trim();
    if (text.isEmpty) text = 'Files created successfully.';
    if (text == msg.content) return msg;
    return MessageModel(id: msg.id, chatId: msg.chatId, userId: msg.userId, role: msg.role, content: text, files: msg.files, tokenInput: msg.tokenInput, tokenOutput: msg.tokenOutput, createdAt: msg.createdAt);
  }

  // === File Operations ===
  Future<FileModel?> getFileContent(String fileId) async {
    final r = await _api.get(ApiEndpoints.fileContent(fileId));
    if (r.success && r.data != null) return FileModel.fromJson(r.data['file'] ?? r.data);
    return null;
  }

  Future<bool> updateFileContent(String fileId, String content) async {
    final r = await _api.put(ApiEndpoints.fileContent(fileId), body: {'content': content});
    if (r.success) await refreshFiles();
    return r.success;
  }

  Future<bool> deleteFile(String fileId) async {
    final r = await _api.delete(ApiEndpoints.fileDelete(fileId));
    if (r.success) {
      _chatFiles.removeWhere((f) => f.id == fileId);
      notifyListeners();
    }
    return r.success;
  }

  Future<bool> renameChat(String chatId, String title) async {
    final r = await _api.put(ApiEndpoints.chatDetail(chatId), body: {'title': title});
    if (r.success) {
      final idx = _generalChats.indexWhere((c) => c.id == chatId);
      if (idx >= 0) _generalChats[idx] = ChatModel(id: chatId, userId: _generalChats[idx].userId, projectId: _generalChats[idx].projectId, title: title, createdAt: _generalChats[idx].createdAt, updatedAt: DateTime.now());
      if (_currentChat?.id == chatId) _currentChat = ChatModel(id: chatId, userId: _currentChat!.userId, projectId: _currentChat!.projectId, title: title, createdAt: _currentChat!.createdAt, updatedAt: DateTime.now());
      notifyListeners();
    }
    return r.success;
  }

  // === File Upload ===
  bool _isUploadingZip = false;
  String _zipUploadStatus = '';
  bool get isUploadingZip => _isUploadingZip;
  String get zipUploadStatus => _zipUploadStatus;

  Future<void> uploadFile(String filePath, String fileName) async {
    if (_currentChat == null) return;
    _isSending = true; notifyListeners();

    try {
      final token = await _api.token;
      final uri = Uri.parse('${AppConstants.baseUrl}${ApiEndpoints.chatUpload(_currentChat!.id)}');
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

      final streamResp = await request.send();
      final respStr = await streamResp.stream.bytesToString();
      final resp = jsonDecode(respStr);

      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        // Add user message
        if (data['userMessage'] != null) _messages.add(MessageModel.fromJson(data['userMessage']));
        // Add AI response
        if (data['aiMessage'] != null) {
          var msg = MessageModel.fromJson(data['aiMessage']);
          msg = _cleanAiResponse(msg);
          _messages.add(msg);
        }
        if (_currentChat?.projectId != null) await _fetchProjectFiles(_currentChat!.projectId!);
        else await _fetchChatFiles(_currentChat!.id);
        // Also track file ops from upload response
        final files = data['files'];
        if (files is List && files.isNotEmpty) {
          _lastFileOps = files.map((f) => Map<String, dynamic>.from(f)).toList();
        }
      } else {
        _messages.add(MessageModel(id: '${DateTime.now().millisecondsSinceEpoch}_err', chatId: _currentChat!.id, role: 'ai', content: resp['message'] ?? 'Upload failed', createdAt: DateTime.now()));
      }
    } catch (e) {
      _messages.add(MessageModel(id: '${DateTime.now().millisecondsSinceEpoch}_err', chatId: _currentChat!.id, role: 'ai', content: 'Upload error: ${e.toString().split('\n').first}', createdAt: DateTime.now()));
    }

    _isSending = false; notifyListeners();
  }

  /// Upload a ZIP file → backend extracts, fixes structure, adds to file tree
  Future<void> uploadZip(String filePath, String fileName) async {
    if (_currentChat == null) return;
    _isUploadingZip = true;
    _zipUploadStatus = 'Uploading ZIP...';
    notifyListeners();

    try {
      final token = await _api.token;
      final uri = Uri.parse('${AppConstants.baseUrl}${ApiEndpoints.chatUploadZip(_currentChat!.id)}');
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

      _zipUploadStatus = 'Extracting & analyzing...';
      notifyListeners();

      final streamResp = await request.send();
      final respStr = await streamResp.stream.bytesToString();
      final resp = jsonDecode(respStr);

      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        final extractedCount = data['extractedCount'] ?? 0;
        final fixedCount = data['fixedCount'] ?? 0;
        final skippedFiles = data['skippedFiles'] as List? ?? [];

        // Add system message showing what happened
        final sb = StringBuffer();
        sb.writeln('📦 **ZIP Extracted:** $extractedCount files added to project');
        if (fixedCount > 0) sb.writeln('🔧 **Structure fixed:** $fixedCount files reorganized');
        if (skippedFiles.isNotEmpty) sb.writeln('⚠️ **Skipped:** ${skippedFiles.join(', ')}');

        // If AI analyzed and gave a message
        if (data['aiMessage'] != null) {
          var msg = MessageModel.fromJson(data['aiMessage']);
          msg = _cleanAiResponse(msg);
          _messages.add(msg);
        } else {
          _messages.add(MessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            chatId: _currentChat!.id,
            role: 'ai',
            content: sb.toString(),
            createdAt: DateTime.now(),
          ));
        }

        // Track file ops
        final files = data['files'];
        if (files is List && files.isNotEmpty) {
          _lastFileOps = files.map((f) => Map<String, dynamic>.from(f)).toList();
        }

        // Refresh files
        await refreshFiles();
      } else {
        _messages.add(MessageModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          chatId: _currentChat!.id, role: 'ai',
          content: resp['message'] ?? 'ZIP upload failed',
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      _messages.add(MessageModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_err',
        chatId: _currentChat!.id, role: 'ai',
        content: 'ZIP upload error: ${e.toString().split('\n').first}',
        createdAt: DateTime.now(),
      ));
    }

    _isUploadingZip = false;
    _zipUploadStatus = '';
    notifyListeners();
  }

  Future<bool> deleteChat(String chatId) async {
    final r = await _api.delete(ApiEndpoints.chatDetail(chatId));
    if (r.success) { _generalChats.removeWhere((c) => c.id == chatId); notifyListeners(); }
    return r.success;
  }

  void closeChat() {
    if (_currentChat != null) _socket.leaveChat(_currentChat!.id);
    _currentChat = null; _messages = []; _chatFiles = []; _lastFileOps = [];
    _aiTyping = false; _currentCode = null; _currentFileName = null;
    _socket.off('chat:message'); _socket.off('chat:ai-typing'); _socket.off('chat:ai-code-writing'); _socket.off('chat:ai-complete');
    notifyListeners();
  }

  void _setupChatListeners() {
    _socket.onNewMessage((data) {
      if (data is Map) { _messages.add(MessageModel.fromJson(Map<String, dynamic>.from(data))); notifyListeners(); }
    });
    _socket.onAiTyping((data) { _aiTyping = data is Map ? (data['isTyping'] ?? false) : false; notifyListeners(); });
    _socket.onAiCodeWriting((data) {
      if (data is Map) { _currentCode = data['code']; _currentFileName = data['fileName']; _aiTyping = true; notifyListeners(); }
    });
    _socket.onAiComplete((data) { _aiTyping = false; _currentCode = null; _currentFileName = null; refreshFiles(); notifyListeners(); });
    _socket.onFileUpdate((data) { refreshFiles(); });
  }
}
