import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  final _pages = const [
    _PageData(icon: Icons.code_rounded, title: 'Build with AI', subtitle: 'Tell AI what you want and watch it write production-ready code in real time', color: AppColors.primary),
    _PageData(icon: Icons.language, title: 'Any Platform', subtitle: 'Build websites, Android apps, and iOS apps with your choice of frameworks', color: AppColors.accent),
    _PageData(icon: Icons.people_rounded, title: 'Collaborate', subtitle: 'Work together in real-time with team features and smart queue management', color: AppColors.accentGreen),
    _PageData(icon: Icons.rocket_launch_rounded, title: 'Deploy Instantly', subtitle: 'Connect GitHub, auto-build APKs, and deploy websites with one tap', color: AppColors.accentOrange),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboarded, true);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        // Skip
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _finish, child: const Text('Skip', style: TextStyle(color: AppColors.darkTextMuted)))),

        // Pages
        Expanded(child: PageView.builder(
          controller: _pageCtrl, itemCount: _pages.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (ctx, i) {
            final p = _pages[i];
            return Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 100, height: 100,
                decoration: BoxDecoration(color: p.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(30)),
                child: Icon(p.icon, size: 48, color: p.color)),
              const SizedBox(height: 40),
              Text(p.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(p.subtitle, style: const TextStyle(fontSize: 14, color: AppColors.darkTextMuted, height: 1.5), textAlign: TextAlign.center),
            ]));
          },
        )),

        // Dots
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == _currentPage ? 24 : 8, height: 8,
          decoration: BoxDecoration(color: i == _currentPage ? AppColors.primary : AppColors.darkBorder, borderRadius: BorderRadius.circular(4)),
        ))),
        const SizedBox(height: 32),

        // Button
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: GradientButton(
          text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
          onPressed: () { if (_currentPage < _pages.length - 1) _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); else _finish(); },
        )),
        const SizedBox(height: 32),
      ])),
    );
  }
}

class _PageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _PageData({required this.icon, required this.title, required this.subtitle, required this.color});
}
