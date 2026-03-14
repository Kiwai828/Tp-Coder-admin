import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/project_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../config/constants.dart';
import '../../widgets/common_widgets.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().openProject(widget.projectId);
      context.read<ProjectProvider>().fetchMembers(widget.projectId);
    });
  }

  @override
  void dispose() { SocketService().leaveProject(widget.projectId); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () { context.read<ProjectProvider>().clearCurrentProject(); Navigator.pop(context); }),
        title: Consumer<ProjectProvider>(builder: (ctx, p, _) => Text(p.currentProject?.name ?? 'Project', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        actions: [
          PopupMenuButton<String>(icon: const Icon(Icons.more_vert, size: 22),
            onSelected: (v) { if (v == 'delete') _deleteProject(); },
            itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('Delete Project', style: TextStyle(color: AppColors.accentRed)))]),
        ],
      ),
      body: Consumer<ProjectProvider>(builder: (ctx, prov, _) {
        if (prov.isLoading && prov.currentProject == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        final project = prov.currentProject;
        if (project == null) return const Center(child: Text('Project not found'));
        final isApp = project.type == 'android' || project.type == 'ios';
        final githubConnected = user?.githubConnected ?? false;

        return RefreshIndicator(onRefresh: () => prov.openProject(widget.projectId),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            // Project info
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(project.framework, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent))),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(project.type.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryLight))),
              const SizedBox(width: 8),
              StatusBadge(status: project.status),
            ]),
            const SizedBox(height: 16),

            // Quick Actions
            Row(children: [
              _actionBtn(Icons.code, 'GitHub', AppColors.darkText, () {
                if (githubConnected) _githubActions();
                else _promptConnectGithub();
              }),
              const SizedBox(width: 8),
              // Build only for apps
              if (isApp) ...[
                _actionBtn(Icons.build_outlined, project.type == 'android' ? 'Build APK' : 'Build IPA', AppColors.accentGreen, () {
                  if (!githubConnected) { _promptConnectGithub(); return; }
                  if (project.githubRepoName == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a GitHub repo first'))); return; }
                  _triggerBuild();
                }),
                const SizedBox(width: 8),
              ],
              _actionBtn(Icons.download_outlined, 'Export', AppColors.accent, () => _exportZip()),
              const SizedBox(width: 8),
              _actionBtn(Icons.people_outline, 'Team', AppColors.accentYellow, () => _showTeam()),
            ]),

            // GitHub repo info
            if (project.githubRepoName != null) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.darkBorder)),
                child: Row(children: [
                  const Icon(Icons.code, size: 16, color: AppColors.accentGreen),
                  const SizedBox(width: 8),
                  Expanded(child: Text(project.githubRepoName!, style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary, fontFamily: 'monospace'))),
                ])),
            ],
            const SizedBox(height: 24),

            // Chats Section
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('CHATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted, letterSpacing: 0.5)),
              GestureDetector(onTap: () async {
                final chat = await context.read<ProjectProvider>().createProjectChat(widget.projectId);
                if (chat != null && mounted) Navigator.pushNamed(context, '/chat', arguments: chat.id);
              }, child: const Text('+ New Chat', style: TextStyle(fontSize: 12, color: AppColors.primaryLight))),
            ]),
            const SizedBox(height: 10),
            if (prov.projectChats.isEmpty)
              Container(padding: const EdgeInsets.all(24), width: double.infinity,
                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
                child: const Column(children: [Icon(Icons.chat_bubble_outline, size: 28, color: AppColors.darkTextMuted), SizedBox(height: 8), Text('No chats yet', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted))]))
            else
              ...prov.projectChats.map((c) => GestureDetector(
                onLongPress: () => _chatActions(c),
                child: Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
                  child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primaryLight)),
                    title: Text(c.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: c.lastMessage != null ? Text(c.lastMessage!, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                    trailing: Text(timeAgo(c.updatedAt), style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                    onTap: () => Navigator.pushNamed(context, '/chat', arguments: c.id))))),
            const SizedBox(height: 24),

            // Files Section
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('FILES (${prov.projectFiles.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted, letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 10),
            if (prov.projectFiles.isEmpty)
              Container(padding: const EdgeInsets.all(24), width: double.infinity,
                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
                child: const Column(children: [Icon(Icons.folder_open_outlined, size: 28, color: AppColors.darkTextMuted), SizedBox(height: 8), Text('No files yet', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted))]))
            else
              ...prov.projectFiles.map((f) => Container(margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Icon(Icons.description_outlined, size: 18, color: AppColors.accent),
                  title: Text('${f.filePath.isNotEmpty ? "${f.filePath}/" : ""}${f.fileName}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  trailing: Text('${(f.fileSize / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted))))),
            const SizedBox(height: 24),

            // Activity
            const Text('ACTIVITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            if (prov.activities.isEmpty)
              const Center(child: Text('No activity yet', style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted)))
            else
              ...prov.activities.take(10).map((a) => Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: a.type == 'error' ? AppColors.accentRed : a.type == 'ai' ? AppColors.accent : AppColors.accentGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a.text, style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary))),
                  Text(timeAgo(a.time), style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                ]))),
            const SizedBox(height: 80),
          ]));
      }),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
      child: Column(children: [Icon(icon, size: 20, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color))]))));
  }

  // === Chat Actions ===
  void _chatActions(ChatModel chat) {
    final ctrl = TextEditingController(text: chat.title);
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.edit, size: 20), title: const Text('Rename'),
          onTap: () { Navigator.pop(context); _renameChat(chat); }),
        ListTile(leading: const Icon(Icons.delete_outline, size: 20, color: AppColors.accentRed), title: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
          onTap: () { Navigator.pop(context); context.read<ChatProvider>().deleteChat(chat.id).then((_) => context.read<ProjectProvider>().openProject(widget.projectId)); }),
      ])));
  }

  void _renameChat(ChatModel chat) {
    final ctrl = TextEditingController(text: chat.title);
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Rename Chat'),
      content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Chat name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () {
          context.read<ChatProvider>().renameChat(chat.id, ctrl.text.trim());
          Navigator.pop(context);
          context.read<ProjectProvider>().openProject(widget.projectId);
        }, child: const Text('Save')),
      ]));
  }

  // === GitHub ===
  void _promptConnectGithub() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Connect GitHub'),
      content: const Text('Connect your GitHub account in Settings to use this feature.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, '/settings'); }, child: const Text('Go to Settings')),
      ]));
  }

  void _githubActions() {
    final prov = context.read<ProjectProvider>();
    final project = prov.currentProject;
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorderLight, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20), const Text('GitHub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        if (project?.githubRepoName == null) ...[
          ListTile(leading: const Icon(Icons.add_circle_outline, size: 20), title: const Text('Create New Repository'), onTap: () { Navigator.pop(context); _createRepo(); }),
          ListTile(leading: const Icon(Icons.link, size: 20), title: const Text('Link Existing Repository'), onTap: () { Navigator.pop(context); _pickRepo(); }),
        ] else ...[
          ListTile(leading: const Icon(Icons.upload_rounded, size: 20), title: const Text('Push Files'), onTap: () { Navigator.pop(context); _pushToGithub(); }),
          ListTile(leading: const Icon(Icons.open_in_new, size: 20), title: const Text('View on GitHub'), onTap: () { Navigator.pop(context); }),
        ],
      ])));
  }

  void _createRepo() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Create Repository'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Repository name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () async {
          final ok = await context.read<ProjectProvider>().createGithubRepo(widget.projectId, ctrl.text.trim());
          if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Repository created!' : 'Failed'))); }
        }, child: const Text('Create')),
      ]));
  }

  void _pickRepo() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loading repositories...')));
    final r = await ApiService().get('/github/repos');
    if (!r.success || !mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load repos'))); return; }
    final repos = (r.data?['repos'] as List?) ?? [];
    if (!mounted) return;
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.5, maxChildSize: 0.8, expand: false,
        builder: (ctx, sc) => Column(children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Select Repository', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          Expanded(child: repos.isEmpty
            ? const Center(child: Text('No repositories found', style: TextStyle(color: AppColors.darkTextMuted)))
            : ListView.builder(controller: sc, itemCount: repos.length, itemBuilder: (ctx, i) {
                final repo = repos[i];
                return ListTile(
                  leading: Icon(repo['private'] == true ? Icons.lock : Icons.public, size: 18, color: AppColors.darkTextSecondary),
                  title: Text(repo['name'] ?? '', style: const TextStyle(fontSize: 13)),
                  subtitle: Text(repo['full_name'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                  onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Linked to ${repo["full_name"]}'))); },
                );
              })),
        ])));
  }

  void _pushToGithub() async {
    final ok = await context.read<ProjectProvider>().pushToGithub(widget.projectId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Pushing to GitHub...' : 'Push failed')));
  }

  void _triggerBuild() {
    final prov = context.read<ProjectProvider>();
    if (prov.currentProject?.githubRepoName == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Push to GitHub first'))); return; }
    _pushToGithub();
  }

  void _exportZip() async {
    final url = await context.read<ProjectProvider>().exportZip(widget.projectId);
    if (url != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download: $url')));
  }

  void _showTeam() => Navigator.pushNamed(context, '/team', arguments: widget.projectId);

  void _deleteProject() {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Delete Project?'), content: const Text('This cannot be undone.'), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(onPressed: () { context.read<ProjectProvider>().deleteProject(widget.projectId); Navigator.pop(context); Navigator.pop(context); },
        child: const Text('Delete', style: TextStyle(color: AppColors.accentRed))),
    ]));
  }
}
