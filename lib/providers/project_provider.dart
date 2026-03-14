import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../config/constants.dart';

class ProjectProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();

  List<ProjectModel> _projects = [];
  ProjectModel? _currentProject;
  List<ChatModel> _projectChats = [];
  List<FileModel> _projectFiles = [];
  List<BuildModel> _builds = [];
  List<TeamMemberModel> _members = [];
  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<ProjectModel> get projects => _projects;
  ProjectModel? get currentProject => _currentProject;
  List<ChatModel> get projectChats => _projectChats;
  List<FileModel> get projectFiles => _projectFiles;
  List<BuildModel> get builds => _builds;
  List<TeamMemberModel> get members => _members;
  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProjects({String? search, String? type}) async {
    _isLoading = true; notifyListeners();
    String endpoint = ApiEndpoints.projects;
    final params = <String>[];
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (type != null) params.add('type=$type');
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';
    final r = await _api.get(endpoint);
    _isLoading = false;
    if (r.success && r.data != null) {
      final list = r.data['projects'] ?? r.data;
      _projects = (list is List) ? list.map((p) => ProjectModel.fromJson(p)).toList() : [];
      _projects.sort((a, b) { if (a.isPinned && !b.isPinned) return -1; if (!a.isPinned && b.isPinned) return 1; return b.updatedAt.compareTo(a.updatedAt); });
    } else { _error = r.message; }
    notifyListeners();
  }

  Future<ProjectModel?> createProject({required String name, required String type, required String framework, required bool isTeam, String? displayName}) async {
    final r = await _api.post(ApiEndpoints.projects, body: {'name': name, 'type': type, 'framework': framework, 'isTeam': isTeam, 'displayName': displayName});
    if (r.success && r.data != null) {
      final p = ProjectModel.fromJson(r.data['project'] ?? r.data);
      _projects.insert(0, p); notifyListeners(); return p;
    }
    return null;
  }

  Future<bool> deleteProject(String id) async {
    final r = await _api.delete(ApiEndpoints.projectDetail(id));
    if (r.success) { _projects.removeWhere((p) => p.id == id); notifyListeners(); }
    return r.success;
  }

  Future<void> togglePin(String id) async {
    final r = await _api.put(ApiEndpoints.projectPin(id));
    if (r.success) {
      final idx = _projects.indexWhere((p) => p.id == id);
      if (idx >= 0) { _projects[idx] = _projects[idx].copyWith(isPinned: !_projects[idx].isPinned); notifyListeners(); }
    }
  }

  Future<void> openProject(String id) async {
    _isLoading = true; notifyListeners();
    _socket.joinProject(id);
    final r = await _api.get(ApiEndpoints.projectDetail(id));
    if (r.success && r.data != null) {
      _currentProject = ProjectModel.fromJson(r.data['project'] ?? r.data);
      _members = ((r.data['members'] ?? []) as List).map((m) => TeamMemberModel.fromJson(m)).toList();
      _projectFiles = ((r.data['files'] ?? []) as List).map((f) => FileModel.fromJson(f)).toList();
    }
    // Fetch project chats
    final cr = await _api.get(ApiEndpoints.projectChats(id));
    if (cr.success && cr.data != null) {
      _projectChats = ((cr.data['chats'] ?? cr.data) as List).map((c) => ChatModel.fromJson(c)).toList();
    }
    // Fetch activity
    final ar = await _api.get(ApiEndpoints.projectActivity(id));
    if (ar.success && ar.data != null) {
      _activities = ((ar.data['activities'] ?? []) as List).map((a) => ActivityModel.fromJson(a)).toList();
    }
    _isLoading = false; notifyListeners();
  }

  Future<void> fetchMembers(String id) async {
    final r = await _api.get(ApiEndpoints.projectMembers(id));
    if (r.success && r.data != null) { _members = ((r.data['members'] ?? []) as List).map((m) => TeamMemberModel.fromJson(m)).toList(); notifyListeners(); }
  }

  Future<bool> inviteMember(String projectId, String email, String role) async {
    final r = await _api.post(ApiEndpoints.projectInvite(projectId), body: {'email': email, 'role': role});
    if (r.success) await fetchMembers(projectId);
    return r.success;
  }

  Future<bool> removeMember(String projectId, String userId) async {
    final r = await _api.delete('${ApiEndpoints.projectMembers(projectId)}/$userId');
    if (r.success) await fetchMembers(projectId);
    return r.success;
  }

  Future<bool> leaveProject(String id) async {
    final r = await _api.post(ApiEndpoints.projectLeave(id));
    return r.success;
  }

  void clearCurrentProject() {
    if (_currentProject != null) _socket.leaveProject(_currentProject!.id);
    _currentProject = null; _projectChats = []; _projectFiles = []; _members = []; _activities = [];
    notifyListeners();
  }

  Future<ChatModel?> createProjectChat(String projectId, {String title = 'New Chat'}) async {
    final r = await _api.post(ApiEndpoints.chats, body: {'projectId': projectId, 'title': title});
    if (r.success && r.data != null) {
      final chat = ChatModel.fromJson(r.data['chat'] ?? r.data);
      _projectChats.insert(0, chat); notifyListeners(); return chat;
    }
    return null;
  }

  Future<String?> exportZip(String id) async {
    return '${AppConstants.baseUrl}${ApiEndpoints.projectExport(id)}';
  }

  Future<bool> createGithubRepo(String projectId, String repoName) async {
    final r = await _api.post(ApiEndpoints.githubCreateRepo, body: {'projectId': projectId, 'repoName': repoName});
    if (r.success) await openProject(projectId);
    return r.success;
  }

  Future<bool> pushToGithub(String projectId) async {
    final r = await _api.post(ApiEndpoints.githubPush(projectId));
    return r.success;
  }

  Future<BuildModel?> getBuildStatus(String buildId) async {
    final r = await _api.get(ApiEndpoints.githubBuildStatus(buildId));
    if (r.success && r.data != null) return BuildModel.fromJson(r.data['build'] ?? r.data);
    return null;
  }

  Future<bool> fixBuildError(String buildId) async {
    final r = await _api.post(ApiEndpoints.githubFixError(buildId));
    return r.success;
  }
}
