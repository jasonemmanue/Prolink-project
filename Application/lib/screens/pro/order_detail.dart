import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../client/chat.dart';

/// Détail d'une commande côté pro (§8.2.4) :
/// Confirmer prise en charge / Livrer / Signaler un problème.
class ProOrderDetailScreen extends StatefulWidget {
  final Order order;
  const ProOrderDetailScreen({super.key, required this.order});
  @override
  State<ProOrderDetailScreen> createState() => _ProOrderDetailScreenState();
}

class _ProOrderDetailScreenState extends State<ProOrderDetailScreen> {
  late OrderStatus _status = widget.order.status;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      appBar: AppBar(title: Text(o.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              OrderStatusPill(_status),
              const Spacer(),
              Pill(
                icon: Icons.event,
                label: 'Deadline ${formatDate(o.deadline)}',
                color: o.deadline.isBefore(DateTime.now())
                    ? AppColors.danger
                    : AppColors.primary,
              ),
            ],
          ),
          const SectionLabel('Client'),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withOpacity(0.15),
                child: Text(
                  o.clientName[0],
                  style: const TextStyle(color: AppColors.secondary),
                ),
              ),
              title: Text(
                o.clientName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Membre depuis 2025 · 4 commandes'),
              trailing: IconButton(
                icon: const Icon(Icons.chat_outlined, color: AppColors.primary),
                // Démo : le chat associé réutilise l'écran de conversation.
                onPressed: () => pushScreen(context, ChatScreen(peer: o.pro)),
              ),
            ),
          ),
          const SectionLabel('Prestation'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.service.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text('Formule ${o.variant} · ${o.service.modality}'),
                  const SizedBox(height: 8),
                  Text(
                    'Brief du client : « Je souhaite être accompagné pour '
                    'la rédaction des statuts et le dépôt au CFCE. »',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SectionLabel('Montants'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Prix payé par le client', formatXaf(o.amountXaf)),
                  _row(
                    'Commission ProLink (10 %)',
                    '- ${formatXaf(o.commissionXaf)}',
                  ),
                  const Divider(),
                  _row('Net pour vous', formatXaf(o.netXaf), bold: true),
                  _row(
                    'Statut des fonds',
                    _status == OrderStatus.completed
                        ? 'Libérés'
                        : _status == OrderStatus.disputed
                        ? 'Gelés (litige)'
                        : 'En séquestre',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._actions(context),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final report = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
      ),
      onPressed: () => showReportSheet(context, 'un problème sur la commande'),
      icon: const Icon(Icons.report_problem_outlined),
      label: const Text('Signaler un problème'),
    );
    switch (_status) {
      case OrderStatus.pending:
        return [
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Confirmer la prise en charge'),
            onPressed: () {
              setState(() => _status = OrderStatus.inProgress);
              showInfo(context, 'Le client est notifié.');
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _decline(context),
            child: const Text('Refuser (remboursement intégral)'),
          ),
        ];
      case OrderStatus.inProgress:
        return [
          ElevatedButton.icon(
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Marquer comme livrée'),
            onPressed: () => _deliver(context),
          ),
          const SizedBox(height: 8),
          report,
        ];
      case OrderStatus.delivered:
        return [
          const _Info(
            'En attente de validation du client. Libération automatique sous 72 h.',
          ),
          const SizedBox(height: 8),
          report,
        ];
      case OrderStatus.disputed:
        return [
          const _Info(
            'Litige en cours de médiation. Répondez au médiateur dans le chat du dossier.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showInfo(context, 'Réponse envoyée au médiateur.'),
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Répondre au médiateur'),
          ),
        ];
      case OrderStatus.completed:
        return [const _Info('Commande terminée. Les fonds sont disponibles.')];
    }
  }

  Future<void> _deliver(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Livrer la prestation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file),
              label: const Text('Joindre les livrables'),
            ),
            const SizedBox(height: 12),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Message au client'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Envoyer la livraison'),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() => _status = OrderStatus.delivered);
      if (context.mounted) showInfo(context, 'Livraison envoyée au client.');
    }
  }

  Future<void> _decline(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la commande ?'),
        content: const Text(
          'Le client sera remboursé intégralement. Des refus répétés font baisser votre taux de réponse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Refuser',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) Navigator.pop(context);
  }

  Widget _row(String k, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(k, style: TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          v,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  final String text;
  const _Info(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Réponse à une demande de devis (UC-PR-08).
class QuoteReplyScreen extends StatefulWidget {
  final String clientName;
  final String request;
  const QuoteReplyScreen({
    super.key,
    required this.clientName,
    required this.request,
  });
  @override
  State<QuoteReplyScreen> createState() => _QuoteReplyScreenState();
}

class _QuoteReplyScreenState extends State<QuoteReplyScreen> {
  final _lines = <(String, int)>[
    ('Analyse du dossier', 50000),
    ('Rédaction des conclusions', 150000),
  ];
  int get _total => _lines.fold(0, (a, l) => a + l.$2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Répondre au devis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.request_quote_outlined,
                color: AppColors.accent,
              ),
              title: Text(
                widget.clientName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(widget.request),
            ),
          ),
          const SectionLabel('Lignes du devis'),
          ..._lines.map(
            (l) => Card(
              child: ListTile(
                title: Text(l.$1),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatXaf(l.$2),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _lines.remove(l)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(
              () => _lines.add(('Audience / représentation', 75000)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une ligne'),
          ),
          const SizedBox(height: 8),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Délai de réalisation',
              hintText: 'ex. 3 semaines',
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Conditions / message'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Total TTC',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                formatXaf(_total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Text(
            'Validité 15 jours · paiement via séquestre ProLink',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Envoyer le devis'),
            onPressed: () {
              Navigator.pop(context);
              showInfo(context, 'Devis envoyé à ${widget.clientName}.');
            },
          ),
        ],
      ),
    );
  }
}
