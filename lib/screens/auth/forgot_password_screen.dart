import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  int _step = 0; // 0=email, 1=code, 2=new password

  @override
  void dispose() { _email.dispose(); _code.dispose(); _newPassword.dispose(); _confirmPassword.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password'), leading: IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () => Navigator.pop(context))),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Consumer<AuthProvider>(builder: (ctx, auth, _) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Step indicator
          Row(children: List.generate(3, (i) => Expanded(child: Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: i <= _step ? AppColors.primary : AppColors.darkBorder, borderRadius: BorderRadius.circular(2)))))),
          const SizedBox(height: 32),

          if (auth.error != null) Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.accentRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(auth.error!, style: const TextStyle(color: AppColors.accentRed, fontSize: 13))),

          // Step 0: Email
          if (_step == 0) ...[
            const Text('Enter your email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('We\'ll send a 6-digit code to reset your password', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted)),
            const SizedBox(height: 24),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.darkTextMuted))),
            const SizedBox(height: 24),
            GradientButton(text: 'Send Code', isLoading: auth.isLoading, onPressed: () async {
              final ok = await auth.forgotPassword(_email.text.trim());
              if (ok && mounted) setState(() => _step = 1);
            }),
          ],

          // Step 1: Code
          if (_step == 1) ...[
            const Text('Enter verification code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Code sent to ${_email.text}', style: const TextStyle(fontSize: 13, color: AppColors.darkTextMuted)),
            const SizedBox(height: 24),
            TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
              decoration: InputDecoration(hintText: '000000', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 24),
            GradientButton(text: 'Verify Code', isLoading: auth.isLoading, onPressed: () async {
              final ok = await auth.verifyCode(_email.text.trim(), _code.text.trim());
              if (ok && mounted) setState(() => _step = 2);
            }),
            const SizedBox(height: 12),
            Center(child: TextButton(onPressed: () async { await auth.forgotPassword(_email.text.trim()); },
              child: const Text('Resend Code', style: TextStyle(fontSize: 13)))),
          ],

          // Step 2: New Password
          if (_step == 2) ...[
            const Text('Set new password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Enter your new password', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted)),
            const SizedBox(height: 24),
            TextField(controller: _newPassword, obscureText: true, decoration: const InputDecoration(hintText: 'New Password', prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.darkTextMuted))),
            const SizedBox(height: 12),
            TextField(controller: _confirmPassword, obscureText: true, decoration: const InputDecoration(hintText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.darkTextMuted))),
            const SizedBox(height: 24),
            GradientButton(text: 'Reset Password', isLoading: auth.isLoading, onPressed: () async {
              if (_newPassword.text != _confirmPassword.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'))); return; }
              final ok = await auth.resetPassword(_newPassword.text);
              if (ok && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful!'))); Navigator.pushReplacementNamed(context, '/login'); }
            }),
          ],
        ]);
      }))),
    );
  }
}
