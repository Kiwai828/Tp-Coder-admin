class AppConstants {
  static const String appName = 'TP Coder';
  static const String packageName = 'com.builder.tpo';
  static const String appVersion = '1.0.0';
  static const String baseUrl = 'https://coder.recapmaker.online/api';
  static const String socketUrl = 'https://coder.recapmaker.online';

  static const String githubClientId = 'Ov23li3xZkOXrn6LrEU3';
  static const String githubRedirectUri = 'https://coder.recapmaker.online/api/auth/github/callback';

  static const int maxFileSizeMB = 20;
  static const int freeRequestsPerDay = 20;
  static const int maxLoginAttempts = 5;
  static const int loginBlockMinutes = 15;
  static const int resetCodeExpireMinutes = 5;

  static const Map<String, String> aiProviders = {
    'openai': 'https://api.openai.com/v1',
    'gemini': 'https://generativelanguage.googleapis.com',
    'groq': 'https://api.groq.com/openai/v1',
    'openrouter': 'https://openrouter.ai/api/v1',
  };

  static const List<String> projectTypes = ['website', 'android', 'ios'];

  static const Map<String, List<String>> frameworks = {
    'website': ['HTML/CSS/JS', 'React', 'Vue', 'Angular', 'Next.js', 'Svelte'],
    'android': ['Kotlin', 'Java', 'Flutter', 'React Native', 'Jetpack Compose'],
    'ios': ['Swift', 'SwiftUI', 'Flutter', 'React Native'],
  };

  static const String prefToken = 'auth_token';
  static const String prefTheme = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefUserId = 'user_id';
  static const String prefOnboarded = 'onboarded';
}

class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String githubAuth = '/auth/github';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyCode = '/auth/verify-code';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String deleteAccount = '/auth/delete-account';
  static const String profile = '/user/profile';
  static const String changePassword = '/user/change-password';
  static const String plan = '/user/plan';
  static const String notifications = '/user/notifications';
  static String notificationDelete(String id) => '/user/notifications/$id';
  static const String linkedAccounts = '/user/linked-accounts';
  static const String projects = '/projects';
  static String projectDetail(String id) => '/projects/$id';
  static String projectPin(String id) => '/projects/$id/pin';
  static String projectActivity(String id) => '/projects/$id/activity';
  static String projectExport(String id) => '/projects/$id/export-zip';
  static String projectInvite(String id) => '/projects/$id/invite';
  static String projectMembers(String id) => '/projects/$id/members';
  static String projectLeave(String id) => '/projects/$id/leave';
  static String projectChats(String id) => '/chats/project/$id';
  static const String chats = '/chats';
  static String chatMessages(String id) => '/chats/$id/messages';
  static String chatDetail(String id) => '/chats/$id';
  static String chatUpload(String id) => '/chats/$id/upload';
  static String chatUploadZip(String id) => '/chats/$id/upload-zip';
  static String projectFiles(String id) => '/files/project/$id';
  static String fileContent(String id) => '/files/$id/content';
  static String fileRename(String id) => '/files/$id/rename';
  static String fileDelete(String id) => '/files/$id';
  static String chatExport(String id) => '/chats/$id/export-zip';
  static const String authMe = '/auth/me';
  static const String githubCreateRepo = '/github/create-repo';
  static String githubPush(String id) => '/github/push/$id';
  static String githubBuildStatus(String id) => '/github/build-status/$id';
  static String githubBuildLog(String id) => '/github/build-log/$id';
  static String githubFixError(String id) => '/github/fix-error/$id';
  static String githubDownload(String id) => '/github/download/$id';
  static const String aiChat = '/ai/chat';
  static const String aiModels = '/ai/models';
  static const String feedback = '/feedback';
}
