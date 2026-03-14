import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/theme.dart';
import '../../providers/chat_provider.dart';

class LivePreviewScreen extends StatefulWidget {
  final String projectId;
  final String html;
  const LivePreviewScreen({super.key, required this.projectId, required this.html});
  @override
  State<LivePreviewScreen> createState() => _LivePreviewScreenState();
}

class _LivePreviewScreenState extends State<LivePreviewScreen> {
  bool _isDesktop = false;
  bool _loading = true;
  String? _error;
  String _combinedHtml = '';
  WebViewController? _webCtrl;

  @override
  void initState() {
    super.initState();
    _loadAndBuild();
  }

  Future<void> _loadAndBuild() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.html.isNotEmpty) {
        _combinedHtml = widget.html;
      } else {
        _combinedHtml = await _buildFromChatFiles();
      }

      if (_combinedHtml.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      _webCtrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
          onWebResourceError: (err) { if (mounted) setState(() { _loading = false; _error = err.description; }); },
        ))
        ..loadHtmlString(_combinedHtml);

      setState(() {});
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<String> _buildFromChatFiles() async {
    final chatProv = context.read<ChatProvider>();
    final files = chatProv.chatFiles;
    if (files.isEmpty) return '';

    String? htmlContent;
    final cssParts = <String>[];
    final jsParts = <String>[];

    final htmlFiles = files.where((f) => f.fileName.endsWith('.html')).toList();
    final cssFiles = files.where((f) => f.fileName.endsWith('.css')).toList();
    final jsFiles = files.where((f) => f.fileName.endsWith('.js')).toList();

    for (final f in htmlFiles) {
      final full = await chatProv.getFileContent(f.id);
      if (full?.fileContent != null) {
        if (f.fileName == 'index.html' || htmlContent == null) {
          htmlContent = full!.fileContent;
        }
      }
    }

    for (final f in cssFiles) {
      final full = await chatProv.getFileContent(f.id);
      if (full?.fileContent != null) cssParts.add(full!.fileContent!);
    }

    for (final f in jsFiles) {
      final full = await chatProv.getFileContent(f.id);
      if (full?.fileContent != null) jsParts.add(full!.fileContent!);
    }

    if (htmlContent == null && cssParts.isEmpty && jsParts.isEmpty) return '';

    if (htmlContent != null) {
      return _injectAssets(htmlContent, cssParts, jsParts);
    }
    return _buildMinimalHtml(cssParts, jsParts);
  }

  String _injectAssets(String html, List<String> css, List<String> js) {
    var result = html;

    if (css.isNotEmpty) {
      final block = '<style>\n${css.join('\n')}\n</style>';
      if (result.contains('</head>')) {
        result = result.replaceFirst('</head>', '$block\n</head>');
      } else if (result.contains('<body')) {
        result = result.replaceFirst('<body', '$block\n<body');
      } else {
        result = '$block\n$result';
      }
    }

    if (js.isNotEmpty) {
      final block = '<script>\n${js.join('\n')}\n</script>';
      if (result.contains('</body>')) {
        result = result.replaceFirst('</body>', '$block\n</body>');
      } else {
        result = '$result\n$block';
      }
    }

    if (!result.contains('<html')) {
      result = '<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head><body>$result</body></html>';
    }
    return result;
  }

  String _buildMinimalHtml(List<String> css, List<String> js) {
    return '''<!DOCTYPE html>
<html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>${css.join('\n')}</style></head>
<body><script>${js.join('\n')}</script></body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () => Navigator.pop(context)),
        title: const Text('Live Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(_isDesktop ? Icons.phone_android : Icons.desktop_mac_outlined, size: 20, color: AppColors.darkTextSecondary),
            onPressed: () => setState(() => _isDesktop = !_isDesktop),
          ),
          IconButton(icon: const Icon(Icons.refresh, size: 20, color: AppColors.darkTextSecondary), onPressed: _loadAndBuild),
        ],
      ),
      body: Column(children: [
        // URL Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.darkBorder)),
          child: Row(children: [
            const Icon(Icons.lock_outline, size: 14, color: AppColors.accentGreen),
            const SizedBox(width: 8),
            const Expanded(child: Text('preview://localhost', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted, fontFamily: 'monospace'))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
              child: const Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.accentGreen)),
            ),
          ]),
        ),

        // Preview Area
        Expanded(
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isDesktop ? double.infinity : 375,
              margin: EdgeInsets.symmetric(horizontal: _isDesktop ? 0 : 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_isDesktop ? 0 : 12),
                border: _isDesktop ? null : Border.all(color: AppColors.darkBorder),
                boxShadow: _isDesktop ? null : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_isDesktop ? 0 : 12),
                child: _buildContent(),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(_isDesktop ? 'Desktop View' : 'Mobile View (375 x 812)', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
        ),
      ]),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        const SizedBox(height: 16),
        Text('Loading preview...', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ]);
    }

    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text('Preview Error', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(fontSize: 12, color: Colors.grey[500]), textAlign: TextAlign.center),
        ]),
      ));
    }

    if (_combinedHtml.isEmpty || _webCtrl == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.web_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('No preview available', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('Create HTML/CSS/JS files to see preview', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]));
    }

    return WebViewWidget(controller: _webCtrl!);
  }
}
