import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

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
    Future.delayed(const Duration(milliseconds: 100), () { if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); });
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
          : prov.messages.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.darkTextMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                const Text('Start a conversation', style: TextStyle(fontSize: 14, color: AppColors.darkTextMuted)),
              ]))
            : ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(16),
                itemCount: prov.messages.length + (prov.aiTyping ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == prov.messages.length && prov.aiTyping) return _TypingBubble(code: prov.currentCode, fileName: prov.currentFileName);
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

  // ========== FILE TREE ==========
  void _showFileTree(BuildContext context, ChatProvider prov) {
    prov.refreshFiles();
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.85, expand: false,
        builder: (ctx, scrollCtrl) => Consumer<ChatProvider>(builder: (ctx, p, _) {
          final tree = _buildTree(p.chatFiles);
          return Column(children: [
            // Handle
            Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorderLight, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('File Tree (${p.chatFiles.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.refresh, size: 20, color: AppColors.darkTextMuted), onPressed: () => p.refreshFiles()),
              ]),
            ])),
            // Files
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
      if (path.isEmpty) {
        roots.add(_TreeNode(name: f.fileName, file: f));
        continue;
      }
      final parts = path.split('/');
      String current = '';
      _TreeNode? parent;
      for (final part in parts) {
        current = current.isEmpty ? part : '$current/$part';
        if (!folders.containsKey(current)) {
          final node = _TreeNode(name: part, isFolder: true);
          folders[current] = node;
          if (parent != null) parent.children.add(node);
          else roots.add(node);
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
        onTap: () {
          if (!node.isFolder && node.file != null) {
            Navigator.pop(context);
            _openFileViewer(context, prov, node.file!);
          }
        },
        onLongPress: () {
          if (node.file != null) _fileActions(context, prov, node.file!);
        },
        child: Padding(padding: EdgeInsets.only(left: depth * 16.0, top: 4, bottom: 4),
          child: Row(children: [
            Icon(node.isFolder ? Icons.folder : _fileIcon(node.name), size: 18, color: node.isFolder ? AppColors.accentYellow : AppColors.accent),
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

  IconData _fileIcon(String name) {
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

  // ========== CODE VIEWER/EDITOR ==========
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

// ========== CODE VIEWER/EDITOR SCREEN ==========
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.file.fileName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () {
          if (_changed) { _confirmExit(context); } else Navigator.pop(context);
        }),
        actions: [
          if (!_editing) IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showEditWarning()),
          if (_editing) ...[
            if (_saving) const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))
            else IconButton(icon: const Icon(Icons.save, size: 20, color: AppColors.accentGreen), onPressed: _save),
          ],
        ]),
      body: _editing
        ? TextField(controller: _editCtrl, maxLines: null, expands: true, style: const TextStyle(fontSize: 13, fontFamily: 'monospace', height: 1.6, color: AppColors.darkText),
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
            onChanged: (_) { if (!_changed) setState(() => _changed = true); })
        : SingleChildScrollView(padding: const EdgeInsets.all(16),
            child: SelectableText(_editCtrl.text, style: const TextStyle(fontSize: 13, fontFamily: 'monospace', height: 1.6, color: AppColors.darkTextSecondary))),
    );
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
            child: SelectableText(msg.content, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.darkText))),
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
        Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(18).copyWith(topLeft: const Radius.circular(4)), border: Border.all(color: AppColors.darkBorder)),
          child: code != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (fileName != null) Text(fileName!, style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(code!, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.darkTextSecondary)),
              ])
            : Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent.withValues(alpha: 0.5))),
                const SizedBox(width: 8),
                const Text('AI is thinking...', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted)),
              ]),
        )),
      ]));
  }
}
