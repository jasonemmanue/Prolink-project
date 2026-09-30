import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'order_detail.dart';

class ProOrdersScreen extends StatelessWidget {
  const ProOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final meId = session.online ? session.userId : MockData.pros[0].id;
    final orders = MockData.orders().where((o) => o.pro.id == meId).toList();
    // Devis à chiffrer : (client, titre, besoin, id)
    final quotes = session.online
        ? [
            for (final q in session.quotes)
              if (q['status'] == 'pending' && q['pro']['id'] == meId)
                (
                  q['client']['name'] as String,
                  'Demande de devis',
                  q['description'] as String,
                  q['id'] as String?,
                ),
          ]
        : const [
            (
              'Brice Ewane',
              'Contentieux commercial',
              'Mise en demeure + audience au TGI de Douala.',
              null,
            ),
            (
              'Grace Fotso',
              'Contentieux commercial',
              'Recouvrement d\'une créance de 2,4 M XAF.',
              null,
            ),
          ];
    List<Order> by(bool Function(Order) f) => orders.where(f).toList();
    final pending = by((o) => o.status == OrderStatus.pending);
    final running = by((o) => o.status == OrderStatus.inProgress);
    final delivered = by(
      (o) =>
          o.status == OrderStatus.delivered ||
          o.status == OrderStatus.completed,
    );
    final disputes = by((o) => o.status == OrderStatus.disputed);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Commandes & devis'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'En attente (${pending.length + quotes.length})'),
              Tab(text: 'En cours (${running.length})'),
              Tab(text: 'Livrées (${delivered.length})'),
              Tab(text: 'Litiges (${disputes.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(context, pending, quotes: quotes),
            _list(context, running),
            _list(context, delivered),
            _list(context, disputes),
          ],
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<Order> orders, {
    List<(String, String, String, String?)> quotes = const [],
  }) {
    final session = Session.instance;
    Future<void> refresh() async {
      if (session.online) {
        await Future.wait([session.refreshOrders(), session.refreshPro()]);
      }
    }

    if (orders.isEmpty && quotes.isEmpty) {
      return Center(
        child: Text(
          'Rien ici pour le moment',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        for (final q in quotes)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accent.withOpacity(0.1),
                child: const Icon(
                  Icons.request_quote_outlined,
                  color: AppColors.accent,
                ),
              ),
              title: Text(
                'Devis · ${q.$2}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${q.$1}\n${q.$3}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              trailing: const Pill(
                label: 'À chiffrer',
                color: AppColors.accent,
              ),
              onTap: () => pushScreen(
                context,
                QuoteReplyScreen(clientName: q.$1, request: q.$3, quoteId: q.$4),
              ),
            ),
          ),
        for (final o in orders)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: orderStatusColor(o.status).withOpacity(0.1),
                child: Icon(
                  Icons.receipt_long,
                  color: orderStatusColor(o.status),
                ),
              ),
              title: Text(
                o.service.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${o.clientName} · ${o.code}'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      OrderStatusPill(o.status),
                      Pill(
                        icon: Icons.calendar_today,
                        label: 'Deadline : ${formatDate(o.deadline)}',
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Text(
                formatXaf(o.amountXaf),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              isThreeLine: true,
              onTap: () async {
                await pushScreen(context, ProOrderDetailScreen(order: o));
                await refresh();
              },
            ),
          ),
      ],
      ),
    );
  }
}
