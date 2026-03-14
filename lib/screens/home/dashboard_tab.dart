import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProjectProvider>().fetchProjects());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _doSearch() {
    context.read<ProjectProvider>().fetchProjects(search: _searchCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Consumer<ProjectProvider>(builder: (ctx, prov, _) {
      return Column(children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(children: [
          const Expanded(child: Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          Container(decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.darkBorder)),
            child: IconButton(icon: Icon(_showSearch ? Icons.close : Icons.search, size: 18, color: AppColors.darkTextSecondary),
              onPressed: () { setState(() { _showSearch = !_showSearch; if (!_showSearch) { _searchCtrl.clear(); _doSearch(); } }); }, padding: EdgeInsets.zero)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showNewProject(context),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16, color: Colors.white), SizedBox(width: 4), Text('New', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))])),
          ),
        ])),

        // Search bar
        if (_showSearch) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(controller: _searchCtrl, autofocus: true,
            decoration: InputDecoration(hintText: 'Search projects...', prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.darkTextMuted),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, size: 18), onPressed: _doSearch),
              isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
            onSubmitted: (_) => _doSearch())),

        // Points & Usage Card
        Consumer<AuthProvider>(builder: (ctx, auth, _) {
          final u = auth.user;
          if (u == null) return const SizedBox.shrink();
          final tokenPct = u.dailyTokenLimit > 0 ? (u.dailyTokenUsed / u.dailyTokenLimit).clamp(0.0, 1.0) : 0.0;
          return Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/pricing'),
              child: Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  // Points
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('${u.pointsBalance.toStringAsFixed(0)} pts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text(u.plan.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(value: tokenPct, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 4))),
                      const SizedBox(width: 8),
                      Text('${u.dailyTokenUsed}/${u.dailyTokenLimit}', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                    ]),
                  ])),
                  const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                ])),
            ),
          );
        }),

        // Content
        Expanded(child: prov.isLoading && prov.projects.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(onRefresh: () => prov.fetchProjects(search: _searchCtrl.text.trim()),
              child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                // Projects
                if (prov.projects.isEmpty) ...[
                  const SizedBox(height: 60),
                  Center(child: Column(children: [
                    const Icon(Icons.folder_open_outlined, size: 56, color: AppColors.darkTextMuted),
                    const SizedBox(height: 12),
                    const Text('No projects yet', style: TextStyle(fontSize: 15, color: AppColors.darkTextSecondary)),
                    const SizedBox(height: 8),
                    GestureDetector(onTap: () => _showNewProject(context),
                      child: const Text('Create your first project', style: TextStyle(fontSize: 13, color: AppColors.primaryLight))),
                  ])),
                ] else ...[
                  // Pinned
                  if (prov.projects.any((p) => p.isPinned)) ...[
                    const Padding(padding: EdgeInsets.only(top: 8, bottom: 8), child: Text('PINNED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted, letterSpacing: 1))),
                    for (final p in prov.projects.where((p) => p.isPinned)) _projectCard(context, p, prov),
                  ],
                  const Padding(padding: EdgeInsets.only(top: 12, bottom: 8), child: Text('ALL PROJECTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted, letterSpacing: 1))),
                  for (final p in prov.projects.where((p) => !p.isPinned)) _projectCard(context, p, prov),
                ],
                const SizedBox(height: 80),
              ]))),
      ]);
    }));
  }

  Widget _projectCard(BuildContext context, dynamic p, ProjectProvider prov) {
    final typeIcon = p.type == 'android' ? Icons.android : p.type == 'ios' ? Icons.apple : Icons.language;
    final statusColor = p.status == 'active' ? AppColors.accentGreen : p.status == 'building' ? AppColors.accentYellow : p.status == 'failed' ? AppColors.accentRed : AppColors.darkTextMuted;
    return GestureDetector(
      onTap: () { prov.openProject(p.id); Navigator.pushNamed(context, '/project', arguments: p.id); },
      onLongPress: () => _projectMenu(context, p, prov),
      child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(typeIcon, size: 22, color: AppColors.primaryLight)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              Text(p.framework, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              const SizedBox(width: 8),
              Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(p.status, style: TextStyle(fontSize: 11, color: statusColor)),
              if (p.chatCount > 0) ...[const SizedBox(width: 8), Text('${p.chatCount} chats', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted))],
              if (p.fileCount > 0) ...[const SizedBox(width: 8), Text('${p.fileCount} files', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted))],
            ]),
          ])),
          if (p.isPinned) const Icon(Icons.push_pin, size: 14, color: AppColors.accentYellow),
        ])),
    );
  }

  void _projectMenu(BuildContext context, dynamic p, ProjectProvider prov) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: Icon(p.isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 20), title: Text(p.isPinned ? 'Unpin' : 'Pin'), onTap: () { prov.togglePin(p.id); Navigator.pop(context); }),
        ListTile(leading: const Icon(Icons.delete_outline, size: 20, color: AppColors.accentRed), title: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
          onTap: () { Navigator.pop(context); _confirmDelete(context, p.id, prov); }),
      ])));
  }

  void _confirmDelete(BuildContext context, String id, ProjectProvider prov) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Project?'), content: const Text('This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { prov.deleteProject(id); Navigator.pop(context); }, child: const Text('Delete', style: TextStyle(color: AppColors.accentRed))),
      ],
    ));
  }

  void _showNewProject(BuildContext context) {
    final nameCtrl = TextEditingController();
    String type = 'website';
    String framework = 'HTML/CSS/JS';
    bool isTeam = false;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('New Project', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Project name')),
          const SizedBox(height: 12),
          const Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted)),
          const SizedBox(height: 8),
          Row(children: [
            for (final t in [('website', Icons.language, 'Website'), ('android', Icons.android, 'Android'), ('ios', Icons.apple, 'iOS')])
              Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                onTap: () => setS(() { type = t.$1; framework = t.$1 == 'website' ? 'HTML/CSS/JS' : t.$1 == 'android' ? 'Kotlin' : 'Swift'; }),
                child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: type == t.$1 ? AppColors.primary.withValues(alpha: 0.12) : AppColors.darkSurface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: type == t.$1 ? AppColors.primary : AppColors.darkBorder)),
                  child: Column(children: [Icon(t.$2, size: 20, color: type == t.$1 ? AppColors.primaryLight : AppColors.darkTextMuted), const SizedBox(height: 4),
                    Text(t.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: type == t.$1 ? AppColors.primaryLight : AppColors.darkTextMuted))]))))),
          ]),
          const SizedBox(height: 16),
          GradientButton(text: 'Create Project', onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final p = await context.read<ProjectProvider>().createProject(name: nameCtrl.text.trim(), type: type, framework: framework, isTeam: isTeam);
            if (p != null && context.mounted) { Navigator.pop(context); Navigator.pushNamed(context, '/project', arguments: p.id); }
          }),
        ]),
      )));
  }
}
