import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../config/constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  static const _deepLinkChannel = MethodChannel('com.builder.tpo/deeplink');
  static const _deepLinkEvents = EventChannel('com.builder.tpo/deeplink_events');
  StreamSubscription? _linkSub;
  Completer<String?>? _githubCodeCompleter;

  UserModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;
  String? _resetToken;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;

  AuthProvider() {
    _initDeepLinks();
  }

  // === Deep Link Handling (no external package needed) ===
  void _initDeepLinks() {
    // Listen for deep links via EventChannel (when app is running)
    try {
      _linkSub = _deepLinkEvents.receiveBroadcastStream().listen((dynamic link) {
        if (link is String) _handleDeepLink(Uri.tryParse(link));
      }, onError: (_) {});
    } catch (_) {
      // EventChannel not available — fallback: check initial link only
    }

    // Check initial deep link (app cold start via link)
    _deepLinkChannel.invokeMethod<String>('getInitialLink').then((link) {
      if (link != null) _handleDeepLink(Uri.tryParse(link));
    }).catchError((_) {});
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme == 'tpcoder' && uri.host == 'github-callback') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        if (_githubCodeCompleter != null && !_githubCodeCompleter!.isCompleted) {
          _githubCodeCompleter!.complete(code);
        } else {
          signInWithGithub(code);
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  // === Email Auth ===
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    final r = await _api.post(ApiEndpoints.register, body: {'name': name, 'email': email, 'password': password});
    _isLoading = false;
    if (r.success && r.data != null) { await _api.setToken(r.data['token']); _user = UserModel.fromJson(r.data['user']); _isLoggedIn = true; _connectSocket(); }
    else { _error = r.message ?? 'Registration failed'; }
    notifyListeners(); return r.success;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    final r = await _api.post(ApiEndpoints.login, body: {'email': email, 'password': password});
    _isLoading = false;
    if (r.success && r.data != null) { await _api.setToken(r.data['token']); _user = UserModel.fromJson(r.data['user']); _isLoggedIn = true; _connectSocket(); }
    else { _error = r.message ?? 'Login failed'; }
    notifyListeners(); return r.success;
  }

  // === Google Sign In ===
  Future<bool> signInWithGoogle() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) { _isLoading = false; _error = 'Google sign in cancelled'; notifyListeners(); return false; }
      final r = await _api.post(ApiEndpoints.googleAuth, body: {'googleId': account.id, 'name': account.displayName ?? account.email.split('@')[0], 'email': account.email});
      _isLoading = false;
      if (r.success && r.data != null) { await _api.setToken(r.data['token']); _user = UserModel.fromJson(r.data['user']); _isLoggedIn = true; _connectSocket(); }
      else { _error = r.message ?? 'Google sign in failed'; }
      notifyListeners(); return r.success;
    } catch (e) {
      _isLoading = false; _error = 'Google sign in error: ${e.toString().split('\n').first}'; notifyListeners(); return false;
    }
  }

  // === GitHub OAuth ===
  Future<bool> signInWithGithub(String code) async {
    _isLoading = true; _error = null; notifyListeners();
    final r = await _api.post(ApiEndpoints.githubAuth, body: {'code': code});
    _isLoading = false;
    if (r.success && r.data != null) { await _api.setToken(r.data['token']); _user = UserModel.fromJson(r.data['user']); _isLoggedIn = true; _connectSocket(); }
    else { _error = r.message ?? 'GitHub sign in failed'; }
    notifyListeners(); return r.success;
  }

  Future<void> launchGithubOAuth() async {
    final url = 'https://github.com/login/oauth/authorize'
        '?client_id=${AppConstants.githubClientId}'
        '&redirect_uri=${Uri.encodeComponent(AppConstants.githubRedirectUri)}'
        '&scope=user,repo';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// Launch GitHub OAuth and wait for the code via deep link, then auto sign-in
  Future<bool> launchGithubOAuthAndSignIn() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _githubCodeCompleter = Completer<String?>();
      await launchGithubOAuth();
      // Wait for deep link callback (timeout 120s)
      final code = await _githubCodeCompleter!.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () => null,
      );
      _githubCodeCompleter = null;
      if (code == null) {
        _isLoading = false; _error = 'GitHub sign in cancelled or timed out'; notifyListeners();
        return false;
      }
      // Now sign in with the code
      _isLoading = false; notifyListeners();
      return await signInWithGithub(code);
    } catch (e) {
      _githubCodeCompleter = null;
      _isLoading = false; _error = 'GitHub sign in error: ${e.toString().split('\n').first}'; notifyListeners();
      return false;
    }
  }

  /// Launch GitHub OAuth and wait for code, then connect account (from Settings)
  Future<bool> launchGithubOAuthAndConnect() async {
    try {
      _githubCodeCompleter = Completer<String?>();
      await launchGithubOAuth();
      final code = await _githubCodeCompleter!.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () => null,
      );
      _githubCodeCompleter = null;
      if (code == null) return false;
      return await connectGithub(code);
    } catch (_) {
      _githubCodeCompleter = null;
      return false;
    }
  }

  // === Connect Google (from Settings) ===
  Future<bool> connectGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      final r = await _api.post(ApiEndpoints.googleAuth, body: {'googleId': account.id, 'name': account.displayName ?? '', 'email': account.email});
      if (r.success) { await _refreshUser(); return true; }
      return false;
    } catch (_) { return false; }
  }

  // === Connect GitHub (from Settings) ===
  Future<bool> connectGithub(String code) async {
    final r = await _api.post(ApiEndpoints.githubAuth, body: {'code': code});
    if (r.success) { await _refreshUser(); return true; }
    return false;
  }

  // === Disconnect ===
  Future<bool> disconnectProvider(String provider) async {
    final r = await _api.delete('${ApiEndpoints.linkedAccounts}/$provider');
    if (r.success) await _refreshUser();
    return r.success;
  }

  // === Password Reset ===
  Future<bool> forgotPassword(String email) async {
    _isLoading = true; _error = null; notifyListeners();
    final r = await _api.post(ApiEndpoints.forgotPassword, body: {'email': email});
    _isLoading = false;
    if (!r.success) _error = r.message ?? 'Failed to send code';
    notifyListeners(); return r.success;
  }

  Future<bool> verifyCode(String email, String code) async {
    _isLoading = true; _error = null; notifyListeners();
    final r = await _api.post(ApiEndpoints.verifyCode, body: {'email': email, 'code': code});
    _isLoading = false;
    if (r.success && r.data != null) { _resetToken = r.data['resetToken']; }
    else { _error = r.message ?? 'Invalid code'; }
    notifyListeners(); return r.success;
  }

  Future<bool> resetPassword(String newPassword) async {
    _isLoading = true; _error = null; notifyListeners();
    final r = await _api.post(ApiEndpoints.resetPassword, body: {'resetToken': _resetToken, 'newPassword': newPassword});
    _isLoading = false;
    if (r.success) { _resetToken = null; }
    else { _error = r.message ?? 'Password reset failed'; }
    notifyListeners(); return r.success;
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true; _error = null; notifyListeners();
    final r = await _api.put(ApiEndpoints.changePassword, body: {'currentPassword': currentPassword, 'newPassword': newPassword});
    _isLoading = false;
    if (!r.success) _error = r.message ?? 'Failed';
    notifyListeners(); return r.success;
  }

  // === Session ===
  Future<bool> checkAuth() async {
    final token = await _api.token;
    if (token == null) return false;
    final r = await _api.get(ApiEndpoints.profile);
    if (r.success && r.data != null) {
      _user = UserModel.fromJson(r.data['user'] ?? r.data);
      _isLoggedIn = true; _connectSocket(); notifyListeners(); return true;
    }
    await _api.clearToken(); return false;
  }

  Future<void> logout() async {
    await _api.post(ApiEndpoints.logout);
    await _api.clearToken(); _socket.disconnect();
    try { await _googleSignIn.signOut(); } catch (_) {}
    _user = null; _isLoggedIn = false; notifyListeners();
  }

  Future<bool> deleteAccount() async {
    final r = await _api.delete(ApiEndpoints.deleteAccount);
    if (r.success) { await _api.clearToken(); _socket.disconnect(); _user = null; _isLoggedIn = false; }
    notifyListeners(); return r.success;
  }

  Future<bool> updateProfile({String? name, String? language, String? theme}) async {
    final r = await _api.put(ApiEndpoints.profile, body: {
      if (name != null) 'name': name,
      if (language != null) 'language': language,
      if (theme != null) 'theme': theme,
    });
    if (r.success && r.data != null) { _user = UserModel.fromJson(r.data['user'] ?? r.data); notifyListeners(); }
    return r.success;
  }

  Future<void> _refreshUser() async {
    final r = await _api.get(ApiEndpoints.profile);
    if (r.success && r.data != null) { _user = UserModel.fromJson(r.data['user'] ?? r.data); notifyListeners(); }
  }

  void _connectSocket() {
    if (_user != null) { _api.token.then((t) { if (t != null) _socket.connect(t, _user!.id); }); }
  }
}
