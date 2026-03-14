import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/constants.dart';
import '../../widgets/common_widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _ctrl = TextEditingController();
  String _type = 'feedback';
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Row(children: [
          for (final t in [('feedback', 'Feedback', Icons.feedback_outlined), ('bug', 'Bug Report', Icons.bug_report_outlined), ('feature', 'Feature', Icons.lightbulb_outline)]) ...[
            Expanded(child: GestureDetector(onTap: () => setState(() => _type = t.$1),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(
                color: _type == t.$1 ? AppColors.primary.withValues(alpha: 0.12) : AppColors.darkSurface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _type == t.$1 ? AppColors.primary : AppColors.darkBorder, width: _type == t.$1 ? 2 : 1)),
                child: Column(children: [Icon(t.$3, size: 20, color: _type == t.$1 ? AppColors.primaryLight : AppColors.darkTextMuted), const SizedBox(height: 4),
                  Text(t.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _type == t.$1 ? AppColors.primaryLight : AppColors.darkTextMuted))])))),
            if (t.$1 != 'feature') const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 20),
        const Text('MESSAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        TextField(controller: _ctrl, maxLines: 8, decoration: const InputDecoration(hintText: 'Describe your feedback...', alignLabelWithHint: true)),
        const SizedBox(height: 24),
        GradientButton(text: 'Submit', isLoading: _sending, onPressed: () async {
          if (_ctrl.text.trim().isEmpty) return;
          setState(() => _sending = true);
          await ApiService().post(ApiEndpoints.feedback, body: {'type': _type, 'message': _ctrl.text.trim()});
          setState(() => _sending = false);
          if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!'))); Navigator.pop(context); }
        }),
      ])),
    );
  }
}
