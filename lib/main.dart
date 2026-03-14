import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'l10n/app_locale.dart';
import 'providers/auth_provider.dart';
import 'providers/project_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/pricing_screen.dart';
import 'screens/home/feedback_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/live_preview_screen.dart';
import 'screens/project/project_detail_screen.dart';
import 'screens/project/build_status_screen.dart';
import 'screens/project/team_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale().init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.darkSurface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const TPCoderApp());
}

class TPCoderApp extends StatelessWidget {
  const TPCoderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(builder: (ctx, theme, _) {
        return MaterialApp(
          title: 'TP Coder',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.themeMode,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/': return _route(const SplashScreen(), settings);
              case '/login': return _route(const LoginScreen(), settings);
              case '/onboarding': return _route(const OnboardingScreen(), settings);
              case '/forgot-password': return _route(const ForgotPasswordScreen(), settings);
              case '/home': return _route(const HomeScreen(), settings);
              case '/pricing': return _route(const PricingScreen(), settings);
              case '/feedback': return _route(const FeedbackScreen(), settings);
              case '/chat':
                return _route(ChatScreen(chatId: settings.arguments as String), settings);
              case '/project':
                return _route(ProjectDetailScreen(projectId: settings.arguments as String), settings);
              case '/build':
                return _route(BuildStatusScreen(buildId: settings.arguments as String), settings);
              case '/team':
                return _route(TeamScreen(projectId: settings.arguments as String), settings);
              case '/preview':
                final args = settings.arguments as Map<String, String>;
                return _route(LivePreviewScreen(projectId: args['projectId']!, html: args['html'] ?? ''), settings);
              default: return _route(const SplashScreen(), settings);
            }
          },
        );
      }),
    );
  }

  MaterialPageRoute _route(Widget page, RouteSettings s) => MaterialPageRoute(builder: (_) => page, settings: s);
}
