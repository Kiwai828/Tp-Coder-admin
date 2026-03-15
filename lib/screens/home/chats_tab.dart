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
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ChatProvider>().fetchGeneralChats());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Consumer<ChatProvider>(builder: (ctx, prov, _) {
      final chats = prov.filteredChats;
      return Column(children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Chats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Row(children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) { _searchCtrl.clear(); prov.setSearchQuery(''); }
                });
              },
              child: Container(width: 38, height: 38, margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _showSearch ? AppColors.primary.withValues(alpha: 0.15) : AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _showSearch ? AppColors.primary.withValues(alpha: 0.3) : AppColors.darkBorder),
                ),
                child: Icon(_showSearch ? Icons.close : Icons.search, color: _showSearch ? AppColors.primary : AppColors.darkTextMuted, size: 18)),
            ),
            GestureDetector(onTap: () async { final c = await prov.createChat(); if (c != null && mounted) Navigator.pushNamed(context, '/chat', arguments: c.id); },
              child: Container(width: 38, height: 38, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add, color: Colors.white, size: 18))),
          ]),
        ])),

        // Search bar
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showSearch ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.darkTextMuted),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(onTap: () { _searchCtrl.clear(); prov.setSearchQuery(''); },
                        child: const Icon(Icons.clear, size: 18, color: AppColors.darkTextMuted))
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (v) { prov.setSearchQuery(v); setState(() {}); },
              ),
            ),
          ) : const SizedBox.shrink(),
        ),

        // Results count
        if (_showSearch && prov.searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              Text('${chats.length} result${chats.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
              const SizedBox(width: 4),
              Text('for "${prov.searchQuery}"', style: const TextStyle(fontSize: 12, color: AppColors.accent)),
            ]),
          ),

        const SizedBox(height: 8),

        // Chat list
        Expanded(child: chats.isEmpty
          ? _showSearch && prov.searchQuery.isNotEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.search_off, size: 48, color: AppColors.darkTextMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                const Text('No matching chats', style: TextStyle(fontSize: 14, color: AppColors.darkTextMuted)),
                const SizedBox(height: 4),
                Text('Try different keywords', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted.withValues(alpha: 0.7))),
              ]))
            : const EmptyState(icon: Icons.chat_bubble_outline, title: 'No chats yet', subtitle: 'Start a new conversation with AI')
          : RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.darkSurface,
              onRefresh: () => prov.fetchGeneralChats(),
              child: ListView.builder(itemCount: chats.length, itemBuilder: (ctx, i) {
                final c = chats[i];
                return Dismissible(key: Key(c.id), direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                      title: const Text('Delete Chat'), content: Text('Delete "${c.title}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.accentRed))),
                      ],
                    )) ?? false;
                  },
                  background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: AppColors.accentRed.withValues(alpha: 0.2), child: const Icon(Icons.delete, color: AppColors.accentRed)),
                  onDismissed: (_) => prov.deleteChat(c.id),
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/chat', arguments: c.id),
                    onLongPress: () => _showChatActions(context, prov, c),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.darkBorder))),
                      child: Row(children: [
                        Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.darkSurfaceLight, borderRadius: BorderRadius.circular(12)),
                          child: Icon(c.isProjectChat ? Icons.folder_outlined : Icons.chat_bubble_outline, size: 18, color: c.isProjectChat ? AppColors.accentGreen : AppColors.primaryLight)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _showSearch && prov.searchQuery.isNotEmpty
                            ? _HighlightedText(text: c.title, query: prov.searchQuery, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))
                            : Text(c.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (c.lastMessage != null) Padding(padding: const EdgeInsets.only(top: 3),
                            child: _showSearch && prov.searchQuery.isNotEmpty
                              ? _HighlightedText(text: c.lastMessage!, query: prov.searchQuery, style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted), maxLines: 1)
                              : Text(c.lastMessage!, style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(timeAgo(c.updatedAt), style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                          if (c.messageCount > 0) Padding(padding: const EdgeInsets.only(top: 4),
                            child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.darkSurfaceLight, borderRadius: BorderRadius.circular(8)),
                              child: Text('${c.messageCount}', style: const TextStyle(fontSize: 9, color: AppColors.darkTextMuted)))),
                        ]),
                      ])),
                  ));
              }),
            )),
      ]);
    }));
  }

  void _showChatActions(BuildContext context, ChatProvider prov, ChatModel chat) {
    final renameCtrl = TextEditingController(text: chat.title);
    showModalBottomSheet(context: context, backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorderLight, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(chat.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        ListTile(leading: const Icon(Icons.edit_outlined, size: 20), title: const Text('Rename'),
          onTap: () {
            Navigator.pop(context);
            showDialog(context: context, builder: (_) => AlertDialog(
              title: const Text('Rename Chat'),
              content: TextField(controller: renameCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'Chat title'),
                onSubmitted: (v) async { if (v.trim().isNotEmpty) await prov.renameChat(chat.id, v.trim()); if (context.mounted) Navigator.pop(context); }),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(onPressed: () async { if (renameCtrl.text.trim().isNotEmpty) await prov.renameChat(chat.id, renameCtrl.text.trim()); if (context.mounted) Navigator.pop(context); },
                  child: const Text('Save', style: TextStyle(color: AppColors.accent))),
              ],
            ));
          }),
        ListTile(leading: const Icon(Icons.delete_outline, size: 20, color: AppColors.accentRed), title: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
          onTap: () async {
            Navigator.pop(context);
            final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              title: const Text('Delete Chat'), content: Text('Delete "${chat.title}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.accentRed))),
              ],
            ));
            if (ok == true) prov.deleteChat(chat.id);
          }),
      ])));
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final int? maxLines;
  const _HighlightedText({required this.text, required this.query, required this.style, this.maxLines});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) { spans.add(TextSpan(text: text.substring(start))); break; }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(text: text.substring(idx, idx + query.length),
        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, backgroundColor: AppColors.accent.withValues(alpha: 0.1))));
      start = idx + query.length;
    }
    return RichText(text: TextSpan(style: style, children: spans), maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
}
