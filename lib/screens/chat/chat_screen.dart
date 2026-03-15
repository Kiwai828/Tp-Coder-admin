import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/models.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/markdown_code_view.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() { if (_hasText != _msgCtrl.text.isNotEmpty) setState(() => _hasText = _msgCtrl.text.isNotEmpty); });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openChat(widget.chatId);
      context.read<ChatProvider>().fetchModels();
    });
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () { if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); });
  }

  @override
  Widget build(BuildContext context) {
    final userPlan = context.read<AuthProvider>().user?.plan ?? 'free';
    return Scaffold(body: SafeArea(child: Consumer<ChatProvider>(builder: (ctx, prov, _) {
      return Column(children: [
        // App Bar
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.darkBorder))),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () { prov.closeChat(); Navigator.pop(context); }),
            Expanded(child: Text(prov.currentChat?.title ?? 'Chat', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
            // Export ZIP button
            IconButton(icon: const Icon(Icons.download_outlined, size: 20, color: AppColors.darkTextSecondary),
              onPressed: () => _exportCode(context, prov),
              tooltip: 'Export ZIP'),
            // File tree button with count
            Stack(children: [
              IconButton(icon: const Icon(Icons.account_tree_outlined, size: 20, color: AppColors.darkTextSecondary), onPressed: () => _showFileTree(context, prov)),
              if (prov.chatFiles.isNotEmpty) Positioned(top: 4, right: 4, child: Container(padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: Text('${prov.chatFiles.length}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)))),
            ]),
            IconButton(icon: const Icon(Icons.play_circle_outline, size: 20, color: AppColors.accent), onPressed: () {
              final pid = prov.currentChat?.projectId ?? widget.chatId;
              Navigator.pushNamed(context, '/preview', arguments: {'projectId': pid, 'html': ''});
            }),
          ])),

        // Model Selector
        if (prov.availableModels.isNotEmpty)
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.darkBorder))),
            child: Row(children: [
              const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.darkTextMuted),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () => _showModelPicker(context, prov, userPlan),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.darkBorder)),
                  child: Row(children: [
                    Expanded(child: Text(prov.availableModels.where((m) => m.id == prov.selectedModelId).firstOrNull?.displayName ?? 'Select Model',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.unfold_more, size: 16, color: AppColors.darkTextMuted),
                  ])),
              )),
            ])),

        // Messages
        Expanded(child: prov.isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : prov.messages.isEmpty && !prov.isUploadingZip
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.darkTextMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                const Text('Start a conversation', style: TextStyle(fontSize: 14, color: AppColors.darkTextMuted)),
              ]))
            : ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(16),
                itemCount: prov.messages.length + (prov.aiTyping ? 1 : 0) + (prov.isUploadingZip ? 1 : 0),
                itemBuilder: (ctx, i) {
                  // ZIP uploading indicator at the bottom
                  final extraCount = (prov.aiTyping ? 1 : 0) + (prov.isUploadingZip ? 1 : 0);
                  if (prov.isUploadingZip && i == prov.messages.length + extraCount - 1) return _ZipUploadBubble(status: prov.zipUploadStatus);
                  if (prov.aiTyping && i == prov.messages.length) return _TypingBubble(code: prov.currentCode, fileName: prov.currentFileName);
                  if (i >= prov.messages.length) return const SizedBox.shrink();
                  final msg = prov.messages[i];
                  return msg.isUser ? _UserBubble(msg: msg) : _AiBubble(msg: msg, fileOps: (i == prov.messages.length - 1) ? prov.lastFileOps : [], onFileTap: (f) => _openFileViewer(context, prov, f));
                })),

        // Input
        Container(padding: const EdgeInsets.fromLTRB(8, 8, 8, 12), decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.darkBorder))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            GestureDetector(onTap: () => _showAttachOptions(context),
              child: Container(width: 40, height: 44, margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
                child: const Icon(Icons.attach_file, size: 20, color: AppColors.darkTextMuted))),
            Expanded(child: Container(decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder)),
              child: TextField(controller: _msgCtrl, maxLines: 4, minLines: 1, style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(hintText: 'Ask AI...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                onSubmitted: (_) => _send()))),
            const SizedBox(width: 6),
            GestureDetector(onTap: _hasText ? _send : null, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 44, height: 44,
              decoration: BoxDecoration(gradient: _hasText ? AppColors.primaryGradient : null, color: _hasText ? null : AppColors.darkSurface, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.send_rounded, size: 20, color: _hasText ? Colors.white : AppColors.darkTextMuted))),
          ])),
      ]);
    })));
  }

  // ========== EXPORT CODE ==========
  void _exportCode(BuildContext context, ChatProvider prov) async {
    if (prov.chatFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No files to export')));
      return;
    }

    final chatId = prov.currentChat?.projectId ?? prov.currentChat?.id ?? widget.chatId;
    final token = await prov.getExportToken();
    final isProject = prov.currentChat?.projectId != null;
    final url = isProject
      ? '${AppConstants.baseUrl}${ApiEndpoints.projectExport(chatId)}${token != null ? '?token=$token' : ''}'
      : '${prov.getExportUrl(prov.currentChat!.id)}${token != null ? '?token=$token' : ''}';

    if (!context.mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Row(children: [
        Icon(Icons.download_rounded, color: AppColors.accent, size: 22),
        SizedBox(width: 8),
        Text('Export Code', style: TextStyle(fontSize: 16)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${prov.chatFiles.length} files will be exported as ZIP', style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: prov.chatFiles.take(5).map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Icon(_fileIconData(f.fileName), size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(child: Text(f.filePath.isNotEmpty ? '${f.filePath}/${f.fileName}' : f.fileName,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.darkTextSecondary), overflow: TextOverflow.ellipsis)),
              ]),
            )).toList()
            ..addAll(prov.chatFiles.length > 5 ? [Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${prov.chatFiles.length - 5} more files', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
            )] : []),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: ${e.toString().split('\n').first}')));
            }
          },
          child: const Text('Download ZIP', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  IconData _fileIconData(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'html': return Icons.language;
      case 'css': return Icons.palette_outlined;
      case 'js': case 'ts': return Icons.javascript;
      case 'dart': return Icons.code;
      case 'json': return Icons.data_object;
      case 'md': return Icons.article_outlined;
      case 'png': case 'jpg': case 'svg': return Icons.image_outlined;
      default: return Icons.description_outlined;
    }
  }

  // ========== FILE TREE ==========
  void _showFileTree(BuildContext context, ChatProvider prov) {
    prov.refreshFiles();
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.85, expand: false,
        builder: (ctx, scrollCtrl) => Consumer<ChatProvider>(builder: (ctx, p, _) {
          final tree = _buildTree(p.chatFiles);
          return Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorderLight, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('File Tree (${p.chatFiles.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.refresh, size: 20, color: AppColors.darkTextMuted), onPressed: () => p.refreshFiles()),
              ]),
            ])),
            Expanded(child: p.chatFiles.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.folder_open_outlined, size: 40, color: AppColors.darkTextMuted),
                  SizedBox(height: 8),
                  Text('No files yet', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted)),
                  SizedBox(height: 4),
                  Text('Ask AI to create files', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
                ]))
              : ListView(controller: scrollCtrl, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                  for (final node in tree) _treeNode(context, p, node, 0),
                  const SizedBox(height: 20),
                ])),
          ]);
        })));
  }

  List<_TreeNode> _buildTree(List<FileModel> files) {
    final Map<String, _TreeNode> folders = {};
    final List<_TreeNode> roots = [];
    for (final f in files) {
      final path = f.filePath.isEmpty ? '' : f.filePath;
      if (path.isEmpty) { roots.add(_TreeNode(name: f.fileName, file: f)); continue; }
      final parts = path.split('/');
      String current = '';
      _TreeNode? parent;
      for (final part in parts) {
        current = current.isEmpty ? part : '$current/$part';
        if (!folders.containsKey(current)) {
          final node = _TreeNode(name: part, isFolder: true);
          folders[current] = node;
          if (parent != null) parent.children.add(node); else roots.add(node);
        }
        parent = folders[current];
      }
      parent?.children.add(_TreeNode(name: f.fileName, file: f));
    }
    return roots;
  }

  Widget _treeNode(BuildContext context, ChatProvider prov, _TreeNode node, int depth) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: () { if (!node.isFolder && node.file != null) { Navigator.pop(context); _openFileViewer(context, prov, node.file!); } },
        onLongPress: () { if (node.file != null) _fileActions(context, prov, node.file!); },
        child: Padding(padding: EdgeInsets.only(left: depth * 16.0, top: 4, bottom: 4),
          child: Row(children: [
            Icon(node.isFolder ? Icons.folder : _fileIconData(node.name), size: 18, color: node.isFolder ? AppColors.accentYellow : AppColors.accent),
            const SizedBox(width: 8),
            Expanded(child: Text(node.name, style: TextStyle(fontSize: 13, fontWeight: node.isFolder ? FontWeight.w600 : FontWeight.normal,
              color: node.isFolder ? AppColors.darkText : AppColors.darkTextSecondary))),
            if (node.file != null) ...[
              Text(_formatSize(node.file!.fileSize), style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
              const SizedBox(width: 4),
              GestureDetector(onTap: () => _fileActions(context, prov, node.file!),
                child: const Icon(Icons.more_vert, size: 16, color: AppColors.darkTextMuted)),
            ],
          ])),
      ),
      if (node.isFolder) for (final child in node.children) _treeNode(context, prov, child, depth + 1),
    ]);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _fileActions(BuildContext context, ChatProvider prov, FileModel file) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorderLight, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 12),
        Text(file.fileName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ListTile(leading: const Icon(Icons.visibility, size: 20), title: const Text('View / Edit'), onTap: () { Navigator.pop(context); _openFileViewer(context, prov, file); }),
        ListTile(leading: const Icon(Icons.delete_outline, size: 20, color: AppColors.accentRed), title: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
          onTap: () { Navigator.pop(context); _confirmDeleteFile(context, prov, file); }),
      ])));
  }

  void _confirmDeleteFile(BuildContext context, ChatProvider prov, FileModel file) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Delete ${file.fileName}?'), content: const Text('This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () async {
          await prov.deleteFile(file.id);
          if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${file.fileName} deleted'))); }
        }, child: const Text('Delete', style: TextStyle(color: AppColors.accentRed))),
      ],
    ));
  }

  void _openFileViewer(BuildContext context, ChatProvider prov, FileModel file) async {
    final full = await prov.getFileContent(file.id);
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => _CodeViewerScreen(file: full ?? file, prov: prov)));
  }

  // ========== MODEL PICKER ==========
  void _showModelPicker(BuildContext context, ChatProvider prov, String userPlan) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorderLight, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('Select AI Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...prov.availableModels.map((m) {
          final selected = m.id == prov.selectedModelId;
          final canUse = userPlan == 'enterprise' || m.userGroup == 'free' || m.userGroup == userPlan;
          final gc = m.userGroup == 'pro' ? AppColors.accent : m.userGroup == 'enterprise' ? AppColors.accentYellow : AppColors.darkTextMuted;
          return GestureDetector(
            onTap: () {
              if (canUse) { prov.selectModel(m.id); Navigator.pop(context); }
              else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upgrade to ${m.userGroup.toUpperCase()} plan'), action: SnackBarAction(label: 'Upgrade', onPressed: () => Navigator.pushNamed(context, '/pricing')))); }
            },
            child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.primary : AppColors.darkBorder)),
              child: Row(children: [
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: selected ? AppColors.primary : AppColors.darkTextMuted),
                const SizedBox(width: 12),
                Expanded(child: Text(m.displayName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: canUse ? AppColors.darkText : AppColors.darkTextMuted))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: gc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(m.userGroup.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: gc))),
                if (!canUse) ...[const SizedBox(width: 6), const Icon(Icons.lock, size: 14, color: AppColors.darkTextMuted)],
              ])),
          );
        }),
        const SizedBox(height: 8),
      ])));
  }

  // ========== ATTACH ==========
  void _showAttachOptions(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.image, size: 20, color: AppColors.accent)),
          title: const Text('Image'), subtitle: const Text('Send for analysis', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
          onTap: () async {
            Navigator.pop(context);
            try {
              final picker = ImagePicker();
              final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
              if (img != null && mounted) context.read<ChatProvider>().uploadFile(img.path, img.name);
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().split('\n').first}'))); }
          }),
        const Divider(color: AppColors.darkBorder),
        ListTile(leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accentYellow.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.camera_alt, size: 20, color: AppColors.accentYellow)),
          title: const Text('Camera'), subtitle: const Text('Take a photo', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
          onTap: () async {
            Navigator.pop(context);
            try {
              final picker = ImagePicker();
              final img = await picker.pickImage(source: ImageSource.camera);
              if (img != null && mounted) context.read<ChatProvider>().uploadFile(img.path, img.name);
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().split('\n').first}'))); }
          }),
        const Divider(color: AppColors.darkBorder),
        ListTile(leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.description, size: 20, color: AppColors.accentGreen)),
          title: const Text('File'), subtitle: const Text('Send for review', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
          onTap: () async {
            Navigator.pop(context);
            try {
              final result = await FilePicker.platform.pickFiles(type: FileType.custom,
                allowedExtensions: ['txt', 'json', 'html', 'css', 'js', 'ts', 'dart', 'py', 'md', 'csv', 'xml', 'pdf']);
              if (result != null && result.files.single.path != null && mounted) {
                context.read<ChatProvider>().uploadFile(result.files.single.path!, result.files.single.name);
              }
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().split('\n').first}'))); }
          }),
        const Divider(color: AppColors.darkBorder),
        // ZIP Project Upload
        ListTile(leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.folder_zip_outlined, size: 20, color: AppColors.primary)),
          title: const Text('ZIP Project'), subtitle: const Text('Extract & add to file tree', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
          onTap: () async {
            Navigator.pop(context);
            try {
              final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
              if (result != null && result.files.single.path != null && mounted) {
                context.read<ChatProvider>().uploadZip(result.files.single.path!, result.files.single.name);
              }
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().split('\n').first}'))); }
          }),
      ])));
  }
}

// ========== TREE NODE ==========
class _TreeNode {
  final String name;
  final bool isFolder;
  final FileModel? file;
  final List<_TreeNode> children = [];
  _TreeNode({required this.name, this.isFolder = false, this.file});
}

// ========== CODE VIEWER/EDITOR SCREEN (TERMINAL STYLE) ==========
class _CodeViewerScreen extends StatefulWidget {
  final FileModel file;
  final ChatProvider prov;
  const _CodeViewerScreen({required this.file, required this.prov});
  @override
  State<_CodeViewerScreen> createState() => _CodeViewerScreenState();
}

class _CodeViewerScreenState extends State<_CodeViewerScreen> {
  late TextEditingController _editCtrl;
  bool _editing = false;
  bool _saving = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.file.fileContent ?? '// No content');
  }

  @override
  void dispose() { _editCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final content = _editCtrl.text;
    final lines = content.split('\n');

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(_getExtIcon(widget.file.fileName), size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(child: Text(widget.file.fileName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
        ]),
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () {
          if (_changed) { _confirmExit(context); } else Navigator.pop(context);
        }),
        actions: [
          IconButton(icon: const Icon(Icons.copy, size: 18, color: AppColors.darkTextSecondary), tooltip: 'Copy', onPressed: () {
            Clipboard.setData(ClipboardData(text: content));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)));
          }),
          if (!_editing) IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showEditWarning()),
          if (_editing) ...[
            if (_saving) const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))
            else IconButton(icon: const Icon(Icons.save, size: 20, color: AppColors.accentGreen), onPressed: _save),
          ],
        ]),
      body: _editing
        ? Container(
            color: const Color(0xFF0D1117),
            child: TextField(controller: _editCtrl, maxLines: null, expands: true,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace', height: 1.6, color: Color(0xFFE6EDF3)),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
              onChanged: (_) { if (!_changed) setState(() => _changed = true); }),
          )
        // Terminal-style code display with line numbers
        : Container(
            color: const Color(0xFF0D1117),
            child: Column(children: [
              // Terminal header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF161B22),
                  border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
                ),
                child: Row(children: [
                  const _TerminalDot(color: Color(0xFFFF5F56)),
                  const SizedBox(width: 6),
                  const _TerminalDot(color: Color(0xFFFFBD2E)),
                  const SizedBox(width: 6),
                  const _TerminalDot(color: Color(0xFF27C93F)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    widget.file.filePath.isNotEmpty ? '${widget.file.filePath}/${widget.file.fileName}' : widget.file.fileName,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF8B949E)),
                    overflow: TextOverflow.ellipsis,
                  )),
                  Text('${lines.length} lines', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF484F58))),
                ]),
              ),
              // Code area with line numbers
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Line numbers gutter
                      Container(
                        width: lines.length > 999 ? 52 : 44,
                        padding: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFF21262D)))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          for (int i = 0; i < lines.length; i++)
                            SizedBox(height: 21, child: Text('${i + 1}', style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF484F58), height: 1.6))),
                        ]),
                      ),
                      // Code content
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 16),
                        child: SelectableText(content,
                          style: const TextStyle(fontSize: 13, fontFamily: 'monospace', height: 1.615, color: Color(0xFFE6EDF3))),
                      ),
                    ])),
                  ),
                ),
              ),
            ]),
          ),
    );
  }

  IconData _getExtIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'html': return Icons.language;
      case 'css': return Icons.palette_outlined;
      case 'js': case 'ts': return Icons.javascript;
      case 'dart': return Icons.code;
      case 'json': return Icons.data_object;
      case 'py': return Icons.code;
      case 'md': return Icons.article_outlined;
      default: return Icons.description_outlined;
    }
  }

  void _showEditWarning() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Edit File'), content: const Text('Manual edits may cause errors. AI cannot track manual changes.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(context); setState(() => _editing = true); }, child: const Text('Edit Anyway')),
      ],
    ));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.prov.updateFileContent(widget.file.id, _editCtrl.text);
    setState(() { _saving = false; _changed = false; });
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Saved!' : 'Save failed')));
  }

  void _confirmExit(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Unsaved Changes'), content: const Text('Discard changes?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Discard', style: TextStyle(color: AppColors.accentRed))),
      ],
    ));
  }
}

// ========== BUBBLES ==========
class _UserBubble extends StatelessWidget {
  final MessageModel msg;
  const _UserBubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.centerRight, child: Container(
      margin: const EdgeInsets.only(bottom: 12, left: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18).copyWith(bottomRight: const Radius.circular(4))),
      child: Text(msg.content, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4)),
    ));
  }
}

// ========== AI BUBBLE WITH MARKDOWN RENDERING ==========
class _AiBubble extends StatelessWidget {
  final MessageModel msg;
  final List<Map<String, dynamic>> fileOps;
  final Function(FileModel) onFileTap;
  const _AiBubble({required this.msg, this.fileOps = const [], required this.onFileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 32),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.smart_toy, size: 16, color: AppColors.accent)),
        const SizedBox(width: 8),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(18).copyWith(topLeft: const Radius.circular(4)), border: Border.all(color: AppColors.darkBorder)),
            child: _MarkdownContent(content: msg.content),
          ),
          // File chips
          if (fileOps.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6),
            child: Wrap(spacing: 6, runSpacing: 4, children: fileOps.map((f) {
              final path = f['path'] ?? '';
              final action = f['action'] ?? 'create';
              final color = action == 'delete' ? AppColors.accentRed : action == 'edit' ? AppColors.accentYellow : AppColors.accentGreen;
              return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(action == 'delete' ? Icons.remove_circle_outline : action == 'edit' ? Icons.edit_outlined : Icons.add_circle_outline, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(path.toString().split('/').last, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, fontFamily: 'monospace')),
                ]));
            }).toList())),
        ])),
      ]),
    );
  }
}

// ========== MARKDOWN CONTENT WIDGET ==========
class _MarkdownContent extends StatelessWidget {
  final String content;
  const _MarkdownContent({required this.content});

  @override
  Widget build(BuildContext context) {
    // Check if content has any markdown or code
    final hasCodeBlock = content.contains('```');
    final hasMarkdown = RegExp(r'(\*\*|__|##|```|`[^`]+`|\n-\s|\n\d+\.\s|\[.+\]\(.+\))').hasMatch(content);

    // Plain text - no formatting needed
    if (!hasMarkdown && !hasCodeBlock) {
      return SelectableText(content, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.darkText));
    }

    // Has code blocks - use terminal-style renderer
    if (hasCodeBlock) {
      return AiMarkdownBody(content: content);
    }

    // Markdown without code blocks - use standard flutter_markdown
    return MarkdownBody(
      data: content,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.darkText),
        h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkText, height: 1.4),
        h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText, height: 1.4),
        h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText, height: 1.4),
        strong: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText),
        em: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.darkTextSecondary),
        code: TextStyle(fontSize: 12.5, fontFamily: 'monospace', color: AppColors.accent, backgroundColor: const Color(0xFF0D1117).withValues(alpha: 0.6)),
        codeblockDecoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF21262D))),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockTextStyle: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFE6EDF3), height: 1.5),
        listBullet: const TextStyle(fontSize: 14, color: AppColors.accent),
        blockquoteDecoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.accent.withValues(alpha: 0.5), width: 3))),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        a: const TextStyle(color: AppColors.accent, decoration: TextDecoration.underline),
        horizontalRuleDecoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.5)))),
        pPadding: const EdgeInsets.only(bottom: 4),
      ),
      onTapLink: (text, href, title) {
        if (href != null) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
      },
    );
  }
}

// ========== TYPING BUBBLE WITH TERMINAL STYLE ==========
class _TypingBubble extends StatelessWidget {
  final String? code;
  final String? fileName;
  const _TypingBubble({this.code, this.fileName});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.smart_toy, size: 16, color: AppColors.accent)),
        const SizedBox(width: 8),
        Flexible(child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(18).copyWith(topLeft: const Radius.circular(4)), border: Border.all(color: AppColors.darkBorder)),
          child: code != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Terminal header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22),
                    border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
                  ),
                  child: Row(children: [
                    const _TerminalDot(color: Color(0xFFFF5F56)),
                    const SizedBox(width: 4),
                    const _TerminalDot(color: Color(0xFFFFBD2E)),
                    const SizedBox(width: 4),
                    const _TerminalDot(color: Color(0xFF27C93F)),
                    const SizedBox(width: 10),
                    if (fileName != null) Expanded(child: Text(fileName!, style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E), fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent.withValues(alpha: 0.6))),
                  ]),
                ),
                // Code content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: const Color(0xFF0D1117),
                  child: Text(code!, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFE6EDF3), height: 1.5), maxLines: 15, overflow: TextOverflow.ellipsis),
                ),
              ])
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent.withValues(alpha: 0.5))),
                  const SizedBox(width: 8),
                  const Text('AI is thinking...', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted)),
                ]),
              ),
        )),
      ]));
  }
}

class _TerminalDot extends StatelessWidget {
  final Color color;
  const _TerminalDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

// ========== ZIP UPLOAD PROGRESS BUBBLE ==========
class _ZipUploadBubble extends StatelessWidget {
  final String status;
  const _ZipUploadBubble({required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.folder_zip, size: 16, color: AppColors.primary)),
        const SizedBox(width: 8),
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(18).copyWith(topLeft: const Radius.circular(4)),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary.withValues(alpha: 0.7))),
              const SizedBox(width: 10),
              Expanded(child: Text(status.isNotEmpty ? status : 'Processing ZIP...', style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary))),
            ]),
            const SizedBox(height: 8),
            // Progress bar animation
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: AppColors.darkBorder,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withValues(alpha: 0.7)),
              ),
            ),
          ]),
        )),
      ]));
  }
}
