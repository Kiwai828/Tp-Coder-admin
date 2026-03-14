import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/project_provider.dart';
import '../../widgets/common_widgets.dart';

class TeamScreen extends StatefulWidget {
  final String projectId;
  const TeamScreen({super.key, required this.projectId});
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProjectProvider>().fetchMembers(widget.projectId)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.person_add_outlined, size: 22), onPressed: _inviteDialog)]),
      body: Consumer<ProjectProvider>(builder: (ctx, prov, _) {
        if (prov.members.isEmpty) return const EmptyState(icon: Icons.people_outline, title: 'No team members', subtitle: 'Invite someone to collaborate');
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: prov.members.length, itemBuilder: (ctx, i) {
          final m = prov.members[i];
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder)),
            child: Row(children: [
              Stack(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryLight)))),
                Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: m.isOnline ? AppColors.accentGreen : AppColors.darkTextMuted, shape: BoxShape.circle, border: Border.all(color: AppColors.darkSurface, width: 2)))),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(
                  color: m.isOwner ? AppColors.accentYellow.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(m.role.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: m.isOwner ? AppColors.accentYellow : AppColors.primaryLight))),
              ])),
              if (!m.isOwner) PopupMenuButton(icon: const Icon(Icons.more_vert, size: 18, color: AppColors.darkTextMuted), itemBuilder: (_) => [
                const PopupMenuItem(value: 'role', child: Text('Change Role')),
                const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: AppColors.accentRed))),
              ], onSelected: (v) { if (v == 'remove' && m.userId != null) _confirmRemove(m.userId!, m.displayName); }),
            ]));
        });
      }),
    );
  }

  void _inviteDialog() {
    final email = TextEditingController();
    String role = 'editor';
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setState2) => AlertDialog(
      title: const Text('Invite Member'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: email, decoration: const InputDecoration(hintText: 'Email address')),
        const SizedBox(height: 12),
        Row(children: [
          for (final r in ['editor', 'viewer']) ...[
            Expanded(child: GestureDetector(onTap: () => setState2(() => role = r),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: role == r ? AppColors.primary.withValues(alpha: 0.12) : AppColors.darkBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: role == r ? AppColors.primary : AppColors.darkBorder)),
                child: Center(child: Text(r.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: role == r ? AppColors.primaryLight : AppColors.darkTextMuted)))))),
            if (r == 'editor') const SizedBox(width: 8),
          ],
        ]),
      ]), actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { context.read<ProjectProvider>().inviteMember(widget.projectId, email.text.trim(), role); Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite sent!'))); }, child: const Text('Invite')),
      ])));
  }

  void _confirmRemove(String userId, String name) {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Remove Member?'), content: Text('Remove $name from this project?'), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(onPressed: () { context.read<ProjectProvider>().removeMember(widget.projectId, userId); Navigator.pop(context); }, child: const Text('Remove', style: TextStyle(color: AppColors.accentRed))),
    ]));
  }
}
