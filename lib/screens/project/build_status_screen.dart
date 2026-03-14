import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/project_provider.dart';
import '../../widgets/common_widgets.dart';

class BuildStatusScreen extends StatefulWidget {
  final String buildId;
  const BuildStatusScreen({super.key, required this.buildId});
  @override
  State<BuildStatusScreen> createState() => _BuildStatusScreenState();
}

class _BuildStatusScreenState extends State<BuildStatusScreen> {
  BuildModel? _build;
  bool _loading = true;
  String? _errorLog;

  @override
  void initState() { super.initState(); _loadBuild(); }

  Future<void> _loadBuild() async {
    final b = await context.read<ProjectProvider>().getBuildStatus(widget.buildId);
    if (mounted) setState(() { _build = b; _loading = false; _errorLog = b?.errorLog; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () => Navigator.pop(context))),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _build == null ? const Center(child: Text('Build not found'))
        : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status Card
          Container(padding: const EdgeInsets.all(20), width: double.infinity,
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder)),
            child: Column(children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(
                color: _build!.isSuccess ? AppColors.accentGreen.withValues(alpha: 0.12) : _build!.isFailed ? AppColors.accentRed.withValues(alpha: 0.12) : AppColors.accentYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
                child: Icon(_build!.isSuccess ? Icons.check_circle : _build!.isFailed ? Icons.error : Icons.hourglass_top, size: 32,
                  color: _build!.isSuccess ? AppColors.accentGreen : _build!.isFailed ? AppColors.accentRed : AppColors.accentYellow)),
              const SizedBox(height: 16),
              Text(_build!.isSuccess ? 'Build Successful!' : _build!.isFailed ? 'Build Failed' : 'Building...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _build!.isSuccess ? AppColors.accentGreen : _build!.isFailed ? AppColors.accentRed : AppColors.accentYellow)),
              const SizedBox(height: 8), StatusBadge(status: _build!.status),
            ])),
          const SizedBox(height: 16),

          // Actions
          if (_build!.isSuccess && _build!.artifactUrl != null)
            GradientButton(text: 'Download APK', icon: Icons.download, onPressed: () {}),

          if (_build!.isFailed) ...[
            // Error Log
            const SizedBox(height: 16),
            const Text('ERROR LOG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentRed, shape: BoxShape.circle)),
                  const SizedBox(width: 5), Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentYellow, shape: BoxShape.circle)),
                  const SizedBox(width: 5), Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 12), const Text('error.log', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted))]),
                const SizedBox(height: 12),
                Text(_errorLog ?? 'No error log available', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.accentRed, height: 1.6)),
              ])),
            const SizedBox(height: 16),

            // Fix Button
            GradientButton(text: 'Fix This Error with AI', icon: Icons.auto_fix_high, onPressed: () async {
              final ok = await context.read<ProjectProvider>().fixBuildError(widget.buildId);
              if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI is fixing the error...')));
            }),
          ],

          if (_build!.isBuilding) ...[
            const SizedBox(height: 24),
            const Center(child: Column(children: [
              SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: AppColors.accentYellow, strokeWidth: 3)),
              SizedBox(height: 16), Text('Build in progress...', style: TextStyle(fontSize: 14, color: AppColors.darkTextMuted)),
              SizedBox(height: 4), Text('This may take a few minutes', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
            ])),
          ],
        ])),
    );
  }
}
