import 'package:flutter/material.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../client/settings.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotification> _items = MockData.notifications();
  String _filter = 'all';

  static const _filters = [
    ('all', 'Toutes'),
    ('order', 'Commandes'),
    ('live', 'Lives'),
    ('message', 'Messages'),
    ('payment', 'Paiements'),
  ];

  @override
  Widget build(BuildContext context) {
    final list = _filter == 'all'
        ? _items
        : _items.where((n) => n.kind == _filter).toList();
    final unread = _items.where((n) => !n.read).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => setState(
                () => _items = [
                  for (final n in _items)
                    AppNotification(
                      id: n.id,
                      kind: n.kind,
                      title: n.title,
                      body: n.body,
                      at: n.at,
                      read: true,
                    ),
                ],
              ),
              child: const Text('Tout lire'),
            ),
          IconButton(
            tooltip: 'Paramètres de notification',
            onPressed: () =>
                pushScreen(context, const NotificationSettingsScreen()),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _filters
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.$2),
                        selected: _filter == f.$1,
                        onSelected: (_) => setState(() => _filter = f.$1),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const _Empty()
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) => _NotifTile(n: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification n;
  const _NotifTile({required this.n});

  (IconData, Color) get _style => switch (n.kind) {
    'live' => (Icons.podcasts, AppColors.danger),
    'order' => (Icons.receipt_long, AppColors.secondary),
    'message' => (Icons.chat_bubble, AppColors.primary),
    'payment' => (Icons.account_balance_wallet, AppColors.success),
    'review' => (Icons.star, AppColors.accent),
    'follow' => (Icons.person_add_alt_1, AppColors.primary),
    _ => (Icons.shield_outlined, AppColors.textSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;
    return Container(
      color: n.read ? null : AppColors.primary.withOpacity(0.04),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          n.title,
          style: TextStyle(
            fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${n.body}\n${timeAgo(n.at)}',
          style: const TextStyle(fontSize: 12, height: 1.35),
        ),
        isThreeLine: true,
        trailing: n.read
            ? null
            : const CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 56,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune notification dans cette catégorie',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
