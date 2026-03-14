import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocale {
  static final AppLocale _instance = AppLocale._();
  factory AppLocale() => _instance;
  AppLocale._();

  String _lang = 'en';
  String get lang => _lang;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('language') ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  String tr(String key) => (_strings[_lang]?[key]) ?? (_strings['en']?[key]) ?? key;

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // Common
      'app_name': 'TP Coder',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'save': 'Save',
      'create': 'Create',
      'invite': 'Invite',
      'retry': 'Retry',
      'ok': 'OK',
      'done': 'Done',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',

      // Auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'name': 'Full Name',
      'forgot_password': 'Forgot Password?',
      'sign_in_google': 'Sign in with Google',
      'sign_in_github': 'Sign in with GitHub',
      'terms_agree': 'By continuing, you agree to our',
      'terms': 'Terms of Service',
      'privacy': 'Privacy Policy',
      'enter_email': 'Enter your email',
      'enter_code': 'Enter 6-digit code',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
      'send_code': 'Send Code',
      'verify': 'Verify',
      'reset_password': 'Reset Password',
      'code_sent': 'Code sent to your email',
      'password_reset_success': 'Password reset successful',

      // Home
      'dashboard': 'Dashboard',
      'chats': 'Chats',
      'alerts': 'Alerts',
      'settings': 'Settings',
      'new_project': 'New Project',
      'no_projects': 'No projects yet',
      'create_first': 'Create your first project',
      'recent_activity': 'RECENT ACTIVITY',

      // Project
      'project_name': 'Project name',
      'project_type': 'PROJECT TYPE',
      'website': 'Website',
      'android': 'Android',
      'ios': 'iOS',
      'framework': 'FRAMEWORK',
      'personal': 'Personal',
      'team': 'Team',
      'display_name': 'Your display name',
      'create_project': 'Create Project',
      'delete_project': 'Delete Project?',
      'delete_project_msg': 'This cannot be undone.',
      'pin': 'Pin',
      'unpin': 'Unpin',
      'rename': 'Rename',

      // Chat
      'new_chat': 'New Chat',
      'no_chats': 'No chats yet',
      'ask_ai': 'Ask AI to build something...',
      'file_tree': 'File Tree',
      'export_zip': 'Export ZIP',
      'live_preview': 'Live Preview',
      'code_viewer': 'Code Viewer',
      'edit_warning': 'Editing manually may cause errors. AI cannot track manual changes.',
      'accept': 'Accept',
      'reject': 'Reject',
      'ai_typing': 'AI is thinking...',

      // Build
      'build_status': 'Build Status',
      'building': 'Building...',
      'build_success': 'Build Successful!',
      'build_failed': 'Build Failed',
      'download_apk': 'Download APK',
      'show_error': 'Show Error Log',
      'fix_error': 'Fix This Error with AI',
      'error_log': 'Error Log',

      // Team
      'team_members': 'Team',
      'no_members': 'No team members',
      'invite_member': 'Invite Member',
      'email_address': 'Email address',
      'editor': 'Editor',
      'viewer': 'Viewer',
      'owner': 'Owner',
      'remove_member': 'Remove Member?',
      'invite_sent': 'Invite sent!',

      // Settings
      'theme': 'Theme',
      'dark': 'Dark',
      'light': 'Light',
      'system': 'System',
      'language': 'Language',
      'english': 'English',
      'myanmar': 'Myanmar',
      'notifications': 'Notifications',
      'linked_accounts': 'Linked Accounts',
      'connected': 'Connected',
      'connect': 'Connect',
      'plan_points': 'Plan & Points',
      'feedback': 'Feedback',
      'terms_service': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',
      'logout': 'Logout',
      'delete_account': 'Delete Account',
      'delete_account_msg': 'This will permanently delete your account. Cannot be undone.',
      'edit_profile': 'Edit Profile',
      'change_password': 'Change Password',
      'current_password': 'Current Password',

      // Pricing
      'free_plan': 'Free',
      'pro_plan': 'Pro',
      'enterprise_plan': 'Enterprise',
      'contact_admin': 'Contact Admin',
      'daily_limit': 'Daily Limit',
      'points_based': 'Points Based',

      // Notifications
      'no_notifications': 'No notifications',
      'mark_all_read': 'Mark all read',

      // Feedback
      'feedback_type': 'Type',
      'bug_report': 'Bug Report',
      'suggestion': 'Suggestion',
      'general_feedback': 'General Feedback',
      'describe': 'Describe your feedback...',
      'submit': 'Submit',
      'feedback_sent': 'Feedback sent! Thank you.',

      // Onboarding
      'onboarding_1_title': 'Build Apps with AI',
      'onboarding_1_desc': 'Create websites, Android apps, and iOS apps just by chatting with AI',
      'onboarding_2_title': 'Smart Memory',
      'onboarding_2_desc': 'AI remembers your project files and writes compatible code',
      'onboarding_3_title': 'One-Tap Build',
      'onboarding_3_desc': 'Push to GitHub and download your APK automatically',
      'skip': 'Skip',
      'next': 'Next',
      'get_started': 'Get Started',
    },

    'mm': {
      // Common
      'app_name': 'TP Coder',
      'cancel': 'ပယ်ဖျက်',
      'delete': 'ဖျက်မယ်',
      'save': 'သိမ်းမယ်',
      'create': 'ဖန်တီးမယ်',
      'invite': 'ဖိတ်မယ်',
      'retry': 'ပြန်ကြိုးစားမယ်',
      'ok': 'အိုကေ',
      'done': 'ပြီးပြီ',
      'loading': 'ခဏစောင့်ပါ...',
      'error': 'အမှား',
      'success': 'အောင်မြင်ပါတယ်',

      // Auth
      'login': 'ဝင်ရောက်မယ်',
      'register': 'စာရင်းသွင်းမယ်',
      'email': 'အီးမေးလ်',
      'password': 'စကားဝှက်',
      'name': 'အမည်',
      'forgot_password': 'စကားဝှက်မေ့နေလား?',
      'sign_in_google': 'Google ဖြင့်ဝင်ရောက်မယ်',
      'sign_in_github': 'GitHub ဖြင့်ဝင်ရောက်မယ်',
      'terms_agree': 'ဆက်လက်ခြင်းဖြင့် သင်သဘောတူပါသည်',
      'terms': 'ဝန်ဆောင်မှုစည်းမျဉ်း',
      'privacy': 'ကိုယ်ရေးအချက်အလက်မူဝါဒ',
      'enter_email': 'အီးမေးလ်ထည့်ပါ',
      'enter_code': 'ကုဒ် ၆ လုံးထည့်ပါ',
      'new_password': 'စကားဝှက်အသစ်',
      'confirm_password': 'စကားဝှက်အတည်ပြုပါ',
      'send_code': 'ကုဒ်ပို့မယ်',
      'verify': 'အတည်ပြုမယ်',
      'reset_password': 'စကားဝှက်ပြန်သတ်မှတ်မယ်',
      'code_sent': 'ကုဒ်ပို့ပြီးပါပြီ',
      'password_reset_success': 'စကားဝှက်ပြောင်းပြီးပါပြီ',

      // Home
      'dashboard': 'ပင်မစာမျက်နှာ',
      'chats': 'ချတ်များ',
      'alerts': 'အကြောင်းကြားချက်',
      'settings': 'ဆက်တင်',
      'new_project': 'ပရောဂျက်အသစ်',
      'no_projects': 'ပရောဂျက်မရှိသေးပါ',
      'create_first': 'ပထမဆုံးပရောဂျက်ဖန်တီးပါ',
      'recent_activity': 'မကြာသေးမီ လှုပ်ရှားမှု',

      // Project
      'project_name': 'ပရောဂျက်အမည်',
      'project_type': 'ပရောဂျက်အမျိုးအစား',
      'website': 'ဝဘ်ဆိုက်',
      'android': 'Android',
      'ios': 'iOS',
      'framework': 'ဖရိမ်ဝေါ့',
      'personal': 'တစ်ကိုယ်ရေ',
      'team': 'အဖွဲ့',
      'display_name': 'ပြသမည့်အမည်',
      'create_project': 'ပရောဂျက်ဖန်တီးမယ်',
      'delete_project': 'ပရောဂျက်ဖျက်မှာလား?',
      'delete_project_msg': 'ပြန်မရနိုင်ပါ။',
      'pin': 'ပင်ထိုး',
      'unpin': 'ပင်ဖြုတ်',
      'rename': 'အမည်ပြောင်း',

      // Chat
      'new_chat': 'ချတ်အသစ်',
      'no_chats': 'ချတ်မရှိသေးပါ',
      'ask_ai': 'AI ကို တည်ဆောက်ခိုင်းပါ...',
      'file_tree': 'ဖိုင်များ',
      'export_zip': 'ZIP ဒေါင်းလုဒ်',
      'live_preview': 'အသက်ရှင် Preview',
      'code_viewer': 'ကုဒ်ကြည့်ရှုရန်',
      'edit_warning': 'ကိုယ်တိုင်ပြင်ခြင်းသည် error ဖြစ်စေနိုင်ပါသည်။',
      'accept': 'လက်ခံမယ်',
      'reject': 'ပယ်မယ်',
      'ai_typing': 'AI စဉ်းစားနေသည်...',

      // Build
      'build_status': 'Build အခြေအနေ',
      'building': 'Build လုပ်နေသည်...',
      'build_success': 'Build အောင်မြင်ပါတယ်!',
      'build_failed': 'Build မအောင်မြင်ပါ',
      'download_apk': 'APK ဒေါင်းလုဒ်',
      'show_error': 'Error Log ကြည့်မယ်',
      'fix_error': 'AI နဲ့ Error ပြင်မယ်',
      'error_log': 'Error မှတ်တမ်း',

      // Team
      'team_members': 'အဖွဲ့',
      'no_members': 'အဖွဲ့ဝင်မရှိသေးပါ',
      'invite_member': 'အဖွဲ့ဝင်ဖိတ်ခေါ်မယ်',
      'email_address': 'အီးမေးလ်',
      'editor': 'တည်းဖြတ်သူ',
      'viewer': 'ကြည့်ရှုသူ',
      'owner': 'ပိုင်ရှင်',
      'remove_member': 'အဖွဲ့ဝင်ဖယ်ထုတ်မှာလား?',
      'invite_sent': 'ဖိတ်စာပို့ပြီးပါပြီ!',

      // Settings
      'theme': 'အရောင်',
      'dark': 'အမှောင်',
      'light': 'အလင်း',
      'system': 'စနစ်',
      'language': 'ဘာသာစကား',
      'english': 'English',
      'myanmar': 'မြန်မာ',
      'notifications': 'အကြောင်းကြားချက်',
      'linked_accounts': 'ချိတ်ဆက်ထားသော အကောင့်',
      'connected': 'ချိတ်ဆက်ပြီး',
      'connect': 'ချိတ်ဆက်မယ်',
      'plan_points': 'Plan နှင့် Points',
      'feedback': 'တုံ့ပြန်ချက်',
      'terms_service': 'ဝန်ဆောင်မှုစည်းမျဉ်း',
      'privacy_policy': 'ကိုယ်ရေးအချက်အလက်မူဝါဒ',
      'logout': 'ထွက်မယ်',
      'delete_account': 'အကောင့်ဖျက်မယ်',
      'delete_account_msg': 'အကောင့်နှင့် ဒေတာအားလုံး အပြီးတိုင်ဖျက်ပါမည်။',
      'edit_profile': 'ပရိုဖိုင်ပြင်မယ်',
      'change_password': 'စကားဝှက်ပြောင်းမယ်',
      'current_password': 'လက်ရှိစကားဝှက်',

      // Pricing
      'free_plan': 'အခမဲ့',
      'pro_plan': 'Pro',
      'enterprise_plan': 'Enterprise',
      'contact_admin': 'Admin ကိုဆက်သွယ်ပါ',
      'daily_limit': 'နေ့စဉ်ကန့်သတ်ချက်',
      'points_based': 'Points အခြေခံ',

      // Notifications
      'no_notifications': 'အကြောင်းကြားချက်မရှိပါ',
      'mark_all_read': 'အားလုံးဖတ်ပြီးသတ်မှတ်',

      // Feedback
      'feedback_type': 'အမျိုးအစား',
      'bug_report': 'Bug တင်မယ်',
      'suggestion': 'အကြံပေးချက်',
      'general_feedback': 'အထွေထွေ',
      'describe': 'ဖော်ပြပါ...',
      'submit': 'တင်မယ်',
      'feedback_sent': 'တုံ့ပြန်ချက်ပို့ပြီးပါပြီ! ကျေးဇူးတင်ပါသည်။',

      // Onboarding
      'onboarding_1_title': 'AI နဲ့ App တည်ဆောက်ပါ',
      'onboarding_1_desc': 'AI နဲ့ စကားပြောပြီး ဝဘ်ဆိုက်၊ Android နဲ့ iOS app တွေ ဖန်တီးပါ',
      'onboarding_2_title': 'စမတ်မှတ်ဉာဏ်',
      'onboarding_2_desc': 'AI က ပရောဂျက်ဖိုင်တွေ မှတ်မိပြီး ကိုက်ညီတဲ့ code ရေးပေးပါတယ်',
      'onboarding_3_title': 'တစ်ချက်နှိပ် Build',
      'onboarding_3_desc': 'GitHub ကို push ပြီး APK ကို အလိုအလျောက် ဒေါင်းလုဒ်လုပ်ပါ',
      'skip': 'ကျော်မယ်',
      'next': 'ရှေ့ဆက်',
      'get_started': 'စတင်မယ်',
    },
  };
}

// Global shortcut
String tr(String key) => AppLocale().tr(key);
