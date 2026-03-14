// Helper to safely parse bool from int or bool
bool _toBool(dynamic v) => v == true || v == 1;

class UserModel {
  final String id;
  final String name;
  final String email;
  final String authProvider;
  final String plan;
  final double pointsBalance;
  final int dailyTokenUsed;
  final int dailyTokenLimit;
  final String language;
  final String theme;
  final bool githubConnected;
  final bool googleConnected;
  final DateTime createdAt;

  UserModel({
    required this.id, required this.name, required this.email,
    this.authProvider = 'email', this.plan = 'free', this.pointsBalance = 0,
    this.dailyTokenUsed = 0, this.dailyTokenLimit = 5000,
    this.language = 'en', this.theme = 'dark',
    this.githubConnected = false, this.googleConnected = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '', name: json['name'] ?? '', email: json['email'] ?? '',
    authProvider: json['auth_provider'] ?? 'email', plan: json['plan'] ?? 'free',
    pointsBalance: (json['points_balance'] ?? 0).toDouble(),
    dailyTokenUsed: json['daily_token_used'] ?? 0, dailyTokenLimit: json['daily_token_limit'] ?? 5000,
    language: json['language'] ?? 'en', theme: json['theme'] ?? 'dark',
    githubConnected: json['github_connected'] == true || json['github_token_encrypted'] != null,
    googleConnected: json['google_connected'] == true || json['google_id'] != null,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'auth_provider': authProvider,
    'plan': plan, 'points_balance': pointsBalance, 'language': language, 'theme': theme,
  };
}

class ProjectModel {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String framework;
  final bool isTeam;
  final String? githubRepoUrl;
  final String? githubRepoName;
  final String status;
  final bool isPinned;
  final int chatCount;
  final int fileCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id, required this.ownerId, required this.name,
    required this.type, required this.framework,
    this.isTeam = false, this.githubRepoUrl, this.githubRepoName, this.status = 'active',
    this.isPinned = false, this.chatCount = 0, this.fileCount = 0,
    required this.createdAt, required this.updatedAt,
  });

  ProjectModel copyWith({bool? isPinned, String? status}) => ProjectModel(
    id: id, ownerId: ownerId, name: name, type: type, framework: framework,
    isTeam: isTeam, githubRepoUrl: githubRepoUrl, githubRepoName: githubRepoName,
    status: status ?? this.status, isPinned: isPinned ?? this.isPinned,
    chatCount: chatCount, fileCount: fileCount, createdAt: createdAt, updatedAt: updatedAt,
  );

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id'] ?? '', ownerId: json['owner_id'] ?? '', name: json['name'] ?? '',
    type: json['type'] ?? 'website', framework: json['framework'] ?? '',
    isTeam: _toBool(json['is_team']), githubRepoUrl: json['github_repo_url'],
    githubRepoName: json['github_repo_name'],
    status: json['status'] ?? 'active', isPinned: _toBool(json['is_pinned']),
    chatCount: json['chat_count'] ?? 0, fileCount: json['file_count'] ?? 0,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
  );
}

class ChatModel {
  final String id;
  final String userId;
  final String? projectId;
  final String title;
  final String? lastMessage;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({required this.id, required this.userId, this.projectId, required this.title, this.lastMessage, this.messageCount = 0, required this.createdAt, required this.updatedAt});
  bool get isProjectChat => projectId != null;

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
    id: json['id'] ?? '', userId: json['user_id'] ?? '', projectId: json['project_id'],
    title: json['title'] ?? 'New Chat', lastMessage: json['last_message'],
    messageCount: json['message_count'] ?? 0,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
  );
}

class MessageModel {
  final String id;
  final String chatId;
  final String? userId;
  final String role;
  final String content;
  final List<FileModel>? files;
  final bool isLoading;
  final int tokenInput;
  final int tokenOutput;
  final DateTime createdAt;

  MessageModel({required this.id, required this.chatId, this.userId, required this.role, required this.content, this.files, this.isLoading = false, this.tokenInput = 0, this.tokenOutput = 0, required this.createdAt});
  bool get isUser => role == 'user';
  bool get isAi => role == 'ai';
  bool get hasFiles => files != null && files!.isNotEmpty;

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] ?? '', chatId: json['chat_id'] ?? '', userId: json['user_id'],
    role: json['role'] ?? 'user', content: json['content'] ?? '',
    files: json['files'] != null ? (json['files'] as List).map((f) => FileModel.fromJson(f)).toList() : null,
    tokenInput: json['token_input'] ?? 0, tokenOutput: json['token_output'] ?? 0,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

class FileModel {
  final String id;
  final String projectId;
  final String? chatId;
  final String fileName;
  final String filePath;
  final String? fileContent;
  final int fileSize;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  FileModel({required this.id, required this.projectId, this.chatId, required this.fileName, required this.filePath, this.fileContent, this.fileSize = 0, this.createdBy, required this.createdAt, required this.updatedAt});
  String get fileExtension => fileName.contains('.') ? fileName.split('.').last : '';

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
    id: json['id'] ?? '', projectId: json['project_id'] ?? '', chatId: json['chat_id'],
    fileName: json['file_name'] ?? '', filePath: json['file_path'] ?? '',
    fileContent: json['file_content'], fileSize: json['file_size'] ?? 0,
    createdBy: json['created_by'],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
  );
}

class BuildModel {
  final String id;
  final String projectId;
  final String? githubActionRunId;
  final String status;
  final String? errorLog;
  final String? artifactUrl;
  final String? triggeredBy;
  final DateTime createdAt;

  BuildModel({required this.id, required this.projectId, this.githubActionRunId, required this.status, this.errorLog, this.artifactUrl, this.triggeredBy, required this.createdAt});
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isBuilding => status == 'building';

  factory BuildModel.fromJson(Map<String, dynamic> json) => BuildModel(
    id: json['id'] ?? '', projectId: json['project_id'] ?? '',
    githubActionRunId: json['github_action_run_id'],
    status: json['status'] ?? 'building',
    errorLog: json['error_log'], artifactUrl: json['artifact_url'],
    triggeredBy: json['triggered_by'],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

class TeamMemberModel {
  final String id;
  final String projectId;
  final String? userId;
  final String displayName;
  final String role;
  final String status;
  final String? invitedEmail;
  final bool isOnline;
  final DateTime? joinedAt;

  TeamMemberModel({required this.id, required this.projectId, this.userId, required this.displayName, required this.role, this.status = 'pending', this.invitedEmail, this.isOnline = false, this.joinedAt});
  bool get isOwner => role == 'owner';

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) => TeamMemberModel(
    id: json['id'] ?? '', projectId: json['project_id'] ?? '', userId: json['user_id'],
    displayName: json['display_name'] ?? json['user_name'] ?? '', role: json['role'] ?? 'viewer',
    status: json['status'] ?? 'pending', invitedEmail: json['invited_email'],
    isOnline: _toBool(json['is_online']),
    joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at']) : null,
  );
}

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({required this.id, required this.type, required this.title, required this.message, this.isRead = false, required this.createdAt});

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'] ?? '', type: json['type'] ?? 'system', title: json['title'] ?? '',
    message: json['message'] ?? '', isRead: _toBool(json['is_read']),
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

class ActivityModel {
  final String id;
  final String text;
  final String type;
  final String? userName;
  final DateTime time;

  ActivityModel({this.id = '', required this.text, required this.type, this.userName, required this.time});

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id: json['id'] ?? '', text: json['text'] ?? '', type: json['type'] ?? 'info',
    userName: json['user_name'],
    time: DateTime.tryParse(json['created_at'] ?? json['time'] ?? '') ?? DateTime.now(),
  );
}
