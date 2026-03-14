import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_locale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../config/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _githubLinked = false;
  bool _googleLinked = false;
  bool _notificationsOn = true;

  @override
  void initState() {
    super.initState();
    _loadLinkedAccounts();
  }

  Future<void> _loadLinkedAccounts() async {
    final r = await ApiService().get(ApiEndpoints.linkedAccounts);
    if (r.success && r.data != null && mounted) {
      setState(() { _githubLinked = r.data['github'] == true; _googleLinked = r.data['google'] == true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 12), child: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),

      // Profile
      Consumer<AuthProvider>(builder: (ctx, auth, _) {
        final u = auth.user;
        return GestureDetector(
          onTap: () => _editProfile(context, u?.name ?? '', u?.email ?? ''),
          child: Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder)),
            child: Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text((u?.name ?? 'U').substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u?.name ?? 'User', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2), Text(u?.email ?? '', style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
                const SizedBox(height: 2), Text(tr('edit_profile'), style: const TextStyle(fontSize: 11, color: AppColors.primaryLight)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text((u?.plan ?? 'Free').toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryLight))),
            ])));
      }),
      const SizedBox(height: 16),

      _group([
        _tile(Icons.dark_mode_outlined, tr('theme'), context.watch<ThemeProvider>().isDark ? tr('dark') : tr('light'), () => _themeDialog(context)),
        _tile(Icons.language, tr('language'), AppLocale().lang == 'mm' ? tr('myanmar') : tr('english'), () => _langDialog(context)),
        _tile(Icons.lock_outlined, tr('change_password'), null, () => _changePassword(context)),
        _tile(Icons.notifications_outlined, tr('notifications'), _notificationsOn ? 'On' : 'Off', () {
          setState(() => _notificationsOn = !_notificationsOn);
        }),
      ]),
      const SizedBox(height: 12),
      _group([
        _tile(Icons.code, 'GitHub', _githubLinked ? tr('connected') : tr('connect'), () => _githubAction(), valueColor: _githubLinked ? AppColors.accentGreen : AppColors.darkTextMuted),
        _tile(Icons.g_mobiledata, 'Google', _googleLinked ? tr('connected') : tr('connect'), () => _googleAction(), valueColor: _googleLinked ? AppColors.accentGreen : AppColors.darkTextMuted),
      ]),
      const SizedBox(height: 12),
      _group([
        _tile(Icons.star_outline, tr('plan_points'), null, () => Navigator.pushNamed(context, '/pricing')),
        _tile(Icons.feedback_outlined, tr('feedback'), null, () => Navigator.pushNamed(context, '/feedback')),
        _tile(Icons.description_outlined, tr('terms_service'), null, () => _showInfo(context, 'Terms of Service', 'Terms of Service for TP Coder app.')),
        _tile(Icons.lock_outline, tr('privacy_policy'), null, () => _showInfo(context, 'Privacy Policy', 'Your data is secure with TP Coder.')),
      ]),
      const SizedBox(height: 12),

      Container(margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder)),
        child: Column(children: [
          _tileWidget(Icons.logout, tr('logout'), AppColors.accentYellow, () async { await context.read<AuthProvider>().logout(); if (context.mounted) Navigator.pushReplacementNamed(context, '/login'); }),
          const Divider(height: 0, indent: 16, endIndent: 16),
          _tileWidget(Icons.delete_forever_outlined, tr('delete_account'), AppColors.accentRed, () => _deleteDialog(context)),
        ])),
      const SizedBox(height: 24),
      const Center(child: Text('TP Coder v1.0.0', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted))),
      const SizedBox(height: 80),
    ])));
  }

  Widget _group(List<Widget> items) => Container(margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder)),
    child: Column(children: [for (int i = 0; i < items.length; i++) ...[items[i], if (i < items.length - 1) const Divider(height: 0, indent: 16, endIndent: 16)]]));

  Widget _tile(IconData icon, String label, String? value, VoidCallback onTap, {Color? valueColor}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [
        Icon(icon, size: 20, color: AppColors.darkTextSecondary), const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        if (value != null) Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? AppColors.darkTextMuted)),
        const SizedBox(width: 4), const Icon(Icons.chevron_right, size: 18, color: AppColors.darkTextMuted),
      ])));
  }

  Widget _tileWidget(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 12), Text(label, style: TextStyle(fontSize: 14, color: color))])));
  }

  void _themeDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(tr('theme')), content: Column(mainAxisSize: MainAxisSize.min, children: [
      for (final entry in [('dark', tr('dark'), Icons.dark_mode), ('light', tr('light'), Icons.light_mode), ('system', tr('system'), Icons.settings_suggest)])
        ListTile(leading: Icon(entry.$3, size: 20), title: Text(entry.$2), onTap: () { context.read<ThemeProvider>().setTheme(entry.$1); Navigator.pop(context); }),
    ])));
  }

  void _langDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(tr('language')), content: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Text('EN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        title: const Text('English'),
        trailing: AppLocale().lang == 'en' ? const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20) : null,
        onTap: () async {
          await AppLocale().setLanguage('en');
          await context.read<AuthProvider>().updateProfile(language: 'en');
          if (mounted) { Navigator.pop(context); setState(() {}); }
        },
      ),
      ListTile(
        leading: const Text('MM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        title: const Text('Myanmar'),
        trailing: AppLocale().lang == 'mm' ? const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20) : null,
        onTap: () async {
          await AppLocale().setLanguage('mm');
          await context.read<AuthProvider>().updateProfile(language: 'mm');
          if (mounted) { Navigator.pop(context); setState(() {}); }
        },
      ),
    ])));
  }

  void _editProfile(BuildContext context, String name, String email) {
    final nameCtrl = TextEditingController(text: name);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(tr('edit_profile')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: tr('name'))),
        const SizedBox(height: 8),
        TextField(enabled: false, decoration: InputDecoration(labelText: tr('email'), hintText: email)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
        TextButton(onPressed: () async {
          await context.read<AuthProvider>().updateProfile(name: nameCtrl.text);
          if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('success')))); }
        }, child: Text(tr('save'))),
      ],
    ));
  }

  void _changePassword(BuildContext context) {
    final current = TextEditingController();
    final newPass = TextEditingController();
    final confirm = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(tr('change_password')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: current, obscureText: true, decoration: InputDecoration(labelText: tr('current_password'))),
        const SizedBox(height: 8),
        TextField(controller: newPass, obscureText: true, decoration: InputDecoration(labelText: tr('new_password'))),
        const SizedBox(height: 8),
        TextField(controller: confirm, obscureText: true, decoration: InputDecoration(labelText: tr('confirm_password'))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
        TextButton(onPressed: () async {
          if (newPass.text != confirm.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'))); return; }
          final ok = await context.read<AuthProvider>().changePassword(current.text, newPass.text);
          if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? tr('success') : 'Failed'))); }
        }, child: Text(tr('save'))),
      ],
    ));
  }

  void _googleAction() {
    if (_googleLinked) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Disconnect Google?'),
        content: const Text('You can reconnect later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            final ok = await context.read<AuthProvider>().disconnectProvider('google');
            if (mounted) { Navigator.pop(context); if (ok) setState(() => _googleLinked = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Google disconnected' : 'Failed'))); }
          }, child: const Text('Disconnect', style: TextStyle(color: AppColors.accentRed))),
        ],
      ));
    } else {
      _connectGoogle();
    }
  }

  Future<void> _connectGoogle() async {
    final ok = await context.read<AuthProvider>().connectGoogle();
    if (mounted) {
      if (ok) setState(() => _googleLinked = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Google connected!' : 'Connection failed')));
    }
  }

  void _githubAction() {
    if (_githubLinked) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Disconnect GitHub?'),
        content: const Text('You will lose access to GitHub features.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            final ok = await context.read<AuthProvider>().disconnectProvider('github');
            if (mounted) { Navigator.pop(context); if (ok) setState(() => _githubLinked = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'GitHub disconnected' : 'Failed'))); }
          }, child: const Text('Disconnect', style: TextStyle(color: AppColors.accentRed))),
        ],
      ));
    } else {
      _connectGithub();
    }
  }

  Future<void> _connectGithub() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening GitHub...')));
    final ok = await context.read<AuthProvider>().launchGithubOAuthAndConnect();
    if (mounted) {
      if (ok) setState(() => _githubLinked = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'GitHub connected!' : 'Connection failed or cancelled')));
    }
  }

  void _showInfo(BuildContext context, String title, String content) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(title), content: Text(content, style: const TextStyle(fontSize: 14)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  void _deleteDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(tr('delete_account')), content: Text(tr('delete_account_msg')), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
      TextButton(onPressed: () async {
        final ok = await context.read<AuthProvider>().deleteAccount();
        if (context.mounted) { Navigator.pop(context); if (ok) Navigator.pushReplacementNamed(context, '/login'); }
      }, child: Text(tr('delete'), style: const TextStyle(color: AppColors.accentRed))),
    ]));
  }
}
