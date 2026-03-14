import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common_widgets.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});
  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ChatProvider>().fetchGeneralChats()); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Consumer<ChatProvider>(builder: (ctx, prov, _) {
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Chats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          GestureDetector(onTap: () async { final c = await prov.createChat(); if (c != null && mounted) Navigator.pushNamed(context, '/chat', arguments: c.id); },
            child: Container(width: 38, height: 38, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add, color: Colors.white, size: 18))),
        ])),
        Expanded(child: prov.generalChats.isEmpty
          ? const EmptyState(icon: Icons.chat_bubble_outline, title: 'No chats yet', subtitle: 'Start a new conversation with AI')
          : ListView.builder(itemCount: prov.generalChats.length, itemBuilder: (ctx, i) {
              final c = prov.generalChats[i];
              return Dismissible(key: Key(c.id), direction: DismissDirection.endToStart,
                background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: AppColors.accentRed.withOpacity(0.2), child: const Icon(Icons.delete, color: AppColors.accentRed)),
                onDismissed: (_) => prov.deleteChat(c.id),
                child: InkWell(onTap: () => Navigator.pushNamed(context, '/chat', arguments: c.id),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.darkBorder))),
                    child: Row(children: [
                      Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.darkSurfaceLight, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.primaryLight)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (c.lastMessage != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(c.lastMessage!, style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ])),
                      Text(timeAgo(c.updatedAt), style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                    ]))));
            })),
      ]);
    }));
  }
}
