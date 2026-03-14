import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../config/constants.dart';
import '../../widgets/common_widgets.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});
  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<NotificationModel> _notifications = [];
  int _unread = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await ApiService().get(ApiEndpoints.notifications);
    if (r.success && r.data != null && mounted) {
      setState(() {
        _notifications = ((r.data['notifications'] ?? []) as List).map((n) => NotificationModel.fromJson(n)).toList();
        _unread = r.data['unread'] ?? 0;
        _loading = false;
      });
    } else if (mounted) setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    await ApiService().put('${ApiEndpoints.notifications}/read-all');
    setState(() { _unread = 0; for (var i = 0; i < _notifications.length; i++) { _notifications[i] = NotificationModel(id: _notifications[i].id, type: _notifications[i].type, title: _notifications[i].title, message: _notifications[i].message, isRead: true, createdAt: _notifications[i].createdAt); } });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          const Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if (_unread > 0) ...[
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.accentRed, borderRadius: BorderRadius.circular(10)),
              child: Text('$_unread', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
          ],
        ]),
        GestureDetector(onTap: _markAllRead, child: const Text('Mark all read', style: TextStyle(fontSize: 12, color: AppColors.primaryLight))),
      ])),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _notifications.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.darkTextMuted),
              const SizedBox(height: 12),
              const Text('No notifications yet', style: TextStyle(fontSize: 14, color: AppColors.darkTextMuted)),
            ]))
          : RefreshIndicator(onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _notifications.length,
              itemBuilder: (ctx, i) => _notifItem(_notifications[i]),
            )),
      ),
    ]));
  }

  Widget _notifItem(NotificationModel n) {
    final icon = n.type == 'build' ? Icons.build_circle : n.type == 'team' ? Icons.people_rounded : n.type == 'points' ? Icons.star_rounded : n.type == 'admin' ? Icons.campaign_rounded : Icons.notifications_rounded;
    final color = n.type == 'build' ? AppColors.accentGreen : n.type == 'team' ? AppColors.accent : n.type == 'points' ? AppColors.accentYellow : n.type == 'admin' ? AppColors.primaryLight : AppColors.darkTextSecondary;
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppColors.accentRed.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed)),
      onDismissed: (_) {
        final removedNotif = n;
        setState(() {
          _notifications.removeWhere((x) => x.id == n.id);
          if (!removedNotif.isRead) _unread = (_unread - 1).clamp(0, 999);
        });
        // Delete from server
        ApiService().delete(ApiEndpoints.notificationDelete(removedNotif.id)).then((r) {
          if (!r.success && mounted) {
            // If server delete failed, show error (notification already removed from UI)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete notification from server')),
            );
          }
        });
      },
      child: GestureDetector(
        onTap: () async {
          if (!n.isRead) {
            await ApiService().put('${ApiEndpoints.notifications}/${n.id}/read');
            setState(() {
              final idx = _notifications.indexWhere((x) => x.id == n.id);
              if (idx >= 0) {
                _notifications[idx] = NotificationModel(id: n.id, type: n.type, title: n.title, message: n.message, isRead: true, createdAt: n.createdAt);
                _unread = (_unread - 1).clamp(0, 999);
              }
            });
          }
        },
        child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: n.isRead ? AppColors.darkSurface : AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: n.isRead ? AppColors.darkBorder : AppColors.primary.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(n.title, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700))),
            Text(timeAgo(n.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
          ]),
          const SizedBox(height: 4),
          Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    )));
  }
}
