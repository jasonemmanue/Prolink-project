import 'package:flutter/material.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'order_detail.dart';

class ProOrdersScreen extends StatelessWidget {
  const ProOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pro connecté (démo) : Me. Aïcha Nkomo.
    final orders =
        MockData.orders().where((o) => o.pro.id == MockData.pros[0].id).toList();
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
              Tab(text: 'En attente (${pending.length + 2})'),
              Tab(text: 'En cours (${running.length})'),
              Tab(text: 'Livrées (${delivered.length})'),
              Tab(text: 'Litiges (${disputes.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(context, pending, withQuotes: true),
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
    bool withQuotes = false,
  }) {
    final quotes = withQuotes
        ? const [
            (
              'Brice Ewane',
              'Contentieux commercial',
              'Mise en demeure + audience au TGI de Douala.',
            ),
            (
              'Grace Fotso',
              'Contentieux commercial',
              'Recouvrement d\'une créance de 2,4 M XAF.',
            ),
          ]
        : const <(String, String, String)>[];
    if (orders.isEmpty && quotes.isEmpty) {
      return Center(
        child: Text(
          'Rien ici pour le moment',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView(
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
                QuoteReplyScreen(clientName: q.$1, request: q.$3),
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
                  Text('${o.clientName} · ${o.id}'),
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
              onTap: () => pushScreen(context, ProOrderDetailScreen(order: o)),
            ),
          ),
      ],
    );
  }
}
