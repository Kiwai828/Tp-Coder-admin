import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  Map<String, dynamic>? _planData;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await ApiService().get(ApiEndpoints.plan);
    if (r.success && r.data != null && mounted) {
      setState(() { _planData = r.data; _loading = false; });
    } else if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final plan = user?.plan ?? 'free';
    final points = _planData?['points_balance'] ?? user?.pointsBalance ?? 0;
    final tokenUsed = _planData?['daily_token_used'] ?? user?.dailyTokenUsed ?? 0;
    final tokenLimit = _planData?['daily_token_limit'] ?? user?.dailyTokenLimit ?? 5000;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan & Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () => Navigator.pop(context))),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
          // Current plan
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.diamond, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${plan.toUpperCase()} Plan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Tokens: $tokenUsed / $tokenLimit', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ])),
              ]),
              if (plan != 'free') ...[
                const SizedBox(height: 12),
                Text('Points: ${(points as num).toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: tokenLimit > 0 ? tokenUsed / tokenLimit : 0, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 6)),
            ])),
          const SizedBox(height: 20),

          _planCard('Free', '\$0', 'For trying out', ['20 AI requests/day', '5,000 daily tokens', '3 projects', 'Community support'], plan == 'free'),
          const SizedBox(height: 12),
          _planCard('Pro', '\$9.99/mo', 'For serious builders', ['Unlimited requests', '50,000 daily tokens', 'Unlimited projects', 'Priority support', 'GitHub CI/CD', 'Team collaboration'], plan == 'pro'),
          const SizedBox(height: 12),
          _planCard('Enterprise', '\$29.99/mo', 'For teams', ['Everything in Pro', 'Custom AI models', 'Advanced analytics', 'Priority queue', 'Dedicated support'], plan == 'enterprise'),
          const SizedBox(height: 20),

          // Contact admin
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder)),
            child: Column(children: [
              const Text('Want to upgrade?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Contact admin to change your plan', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
              const SizedBox(height: 12),
              GradientButton(text: 'Contact Admin', onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact admin to upgrade your plan')));
              }),
            ])),
        ])),
    );
  }

  Widget _planCard(String name, String price, String desc, List<String> features, bool current) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: current ? AppColors.primary : AppColors.darkBorder, width: current ? 2 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
          ])),
          Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryLight)),
        ]),
        if (current) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: const Text('CURRENT PLAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryLight))),
        const SizedBox(height: 12),
        for (final f in features) Padding(padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [const Icon(Icons.check_circle, size: 16, color: AppColors.accentGreen), const SizedBox(width: 8), Text(f, style: const TextStyle(fontSize: 13))])),
      ]),
    );
  }
}
