import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'dashboard_tab.dart';
import 'chats_tab.dart';
import 'notifications_tab.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  final _screens = const [DashboardTab(), ChatsTab(), NotificationsTab(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.darkSurface, border: Border(top: BorderSide(color: AppColors.darkBorder))),
        child: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            _nav(Icons.home_rounded, 'Home', 0),
            _nav(Icons.chat_bubble_rounded, 'Chats', 1),
            _nav(Icons.notifications_rounded, 'Alerts', 2, badge: true),
            _nav(Icons.settings_rounded, 'Settings', 3),
          ]))),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int idx, {bool badge = false}) {
    final active = _idx == idx;
    return Expanded(child: InkWell(onTap: () => setState(() => _idx = idx),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(duration: const Duration(milliseconds: 200), width: 20, height: 3, margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(gradient: active ? AppColors.primaryGradient : null, borderRadius: BorderRadius.circular(2))),
        Stack(clipBehavior: Clip.none, children: [
          Icon(icon, size: 22, color: active ? AppColors.primary : AppColors.darkTextMuted),
          if (badge) Positioned(top: -2, right: -4, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.accentRed, shape: BoxShape.circle, border: Border.all(color: AppColors.darkSurface, width: 1.5)))),
        ]),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.darkTextMuted)),
      ])));
  }
}
