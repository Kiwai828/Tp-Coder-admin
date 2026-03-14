import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPw = TextEditingController();
  final _name = TextEditingController();
  bool _obscure = true;
  bool _obscure2 = true;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); _email.dispose(); _password.dispose(); _confirmPw.dispose(); _name.dispose(); super.dispose(); }

  Future<void> _handleLogin() async {
    final ok = await context.read<AuthProvider>().login(_email.text.trim(), _password.text);
    if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _handleRegister() async {
    if (_password.text != _confirmPw.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'))); return; }
    final ok = await context.read<AuthProvider>().register(_name.text.trim(), _email.text.trim(), _password.text);
    if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Consumer<AuthProvider>(builder: (ctx, auth, _) {
      return Column(children: [
        const SizedBox(height: 40),
        Container(width: 56, height: 56, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 8))]),
          child: const Icon(Icons.code_rounded, color: Colors.white, size: 28)),
        const SizedBox(height: 12),
        const Text('TP Coder', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('AI-Powered Code Builder', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted)),
        const SizedBox(height: 32),

        // Tabs
        Container(decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(3),
          child: TabBar(controller: _tabCtrl, indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            indicatorSize: TabBarIndicatorSize.tab, labelColor: Colors.white, unselectedLabelColor: AppColors.darkTextSecondary,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'Login'), Tab(text: 'Register')])),
        const SizedBox(height: 24),

        // Social
        Row(children: [
          Expanded(child: _socialBtn('G', 'Google', () async {
            final ok = await context.read<AuthProvider>().signInWithGoogle();
            if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
          })),
          const SizedBox(width: 10),
          Expanded(child: _socialBtn(null, 'GitHub', () async {
            final ok = await context.read<AuthProvider>().launchGithubOAuthAndSignIn();
            if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
          }, iconWidget: const Icon(Icons.code, size: 18, color: Colors.white))),
        ]),
        const SizedBox(height: 20),
        Row(children: [const Expanded(child: Divider(color: AppColors.darkBorder)), const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted))), const Expanded(child: Divider(color: AppColors.darkBorder))]),
        const SizedBox(height: 20),

        // Error
        if (auth.error != null) Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.accentRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accentRed.withOpacity(0.3))),
          child: Row(children: [const Icon(Icons.error_outline, color: AppColors.accentRed, size: 18), const SizedBox(width: 8), Expanded(child: Text(auth.error!, style: const TextStyle(color: AppColors.accentRed, fontSize: 13)))])),

        // Form
        AnimatedBuilder(animation: _tabCtrl, builder: (ctx, _) {
          final isReg = _tabCtrl.index == 1;
          return Column(children: [
            if (isReg) ...[_field(_name, 'Full Name', Icons.person_outline), const SizedBox(height: 12)],
            _field(_email, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_password, 'Password', Icons.lock_outline, obscure: _obscure, suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.darkTextMuted, size: 20), onPressed: () => setState(() => _obscure = !_obscure))),
            if (!isReg) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pushNamed(context, '/forgot-password'), child: const Text('Forgot Password?', style: TextStyle(fontSize: 12)))),
            if (isReg) ...[const SizedBox(height: 12), _field(_confirmPw, 'Confirm Password', Icons.lock_outline, obscure: _obscure2, suffix: IconButton(icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: AppColors.darkTextMuted, size: 20), onPressed: () => setState(() => _obscure2 = !_obscure2)))],
            const SizedBox(height: 20),
            GradientButton(text: isReg ? 'Create Account' : 'Sign In', onPressed: isReg ? _handleRegister : _handleLogin, isLoading: auth.isLoading),
          ]);
        }),
        const SizedBox(height: 16),
        RichText(textAlign: TextAlign.center, text: TextSpan(style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted), children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(text: 'Terms', style: TextStyle(color: AppColors.primaryLight)),
          const TextSpan(text: ' & '),
          TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.primaryLight)),
        ])),
        const SizedBox(height: 24),
      ]);
    }))));
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false, Widget? suffix, TextInputType type = TextInputType.text}) {
    return TextField(controller: ctrl, obscureText: obscure, keyboardType: type, style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20, color: AppColors.darkTextMuted), suffixIcon: suffix));
  }

  Widget _socialBtn(String? label, String name, VoidCallback onTap, {Widget? iconWidget}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (iconWidget != null) iconWidget else Text(label!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 8), Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ])));
  }
}
