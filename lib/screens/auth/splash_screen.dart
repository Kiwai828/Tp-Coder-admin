import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)));
    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check onboarding
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool(AppConstants.prefOnboarded) ?? false;
    if (!onboarded) {
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final isLoggedIn = await context.read<AuthProvider>().checkAuth();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/login');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(color: AppColors.darkBg, child: Center(
        child: AnimatedBuilder(animation: _ctrl, builder: (context, child) {
          return Opacity(opacity: _fade.value, child: Transform.scale(scale: _scale.value, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 80, height: 80,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 10))]),
              child: const Icon(Icons.code_rounded, color: Colors.white, size: 40)),
            const SizedBox(height: 20),
            const Text('TP Coder', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkText, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('Build anything with AI', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted)),
            const SizedBox(height: 40),
            SizedBox(width: 32, child: ClipRRect(borderRadius: BorderRadius.circular(2), child: const LinearProgressIndicator(backgroundColor: AppColors.darkSurface, valueColor: AlwaysStoppedAnimation(AppColors.primary), minHeight: 3))),
          ])));
        }),
      )),
    );
  }
}
