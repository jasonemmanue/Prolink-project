import 'package:flutter/material.dart';
import '../../api/session.dart';
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
  bool _busy = false;

  /// Transition côté serveur ; renvoie true si elle a réussi.
  Future<bool> _act(String action, {Map<String, dynamic>? body, String? success}) async {
    setState(() => _busy = true);
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/orders/${widget.order.id}/$action', body);
      return true;
    }, demo: true, success: success);
    if (mounted) setState(() => _busy = false);
    if (ok == true) await Session.instance.afterMoneyAction();
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      appBar: AppBar(title: Text(o.code)),
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
              subtitle: Text(o.brief?.isNotEmpty == true
                  ? o.brief!
                  : 'Client ProLink · paiement en séquestre'),
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
            onPressed: _busy
                ? null
                : () async {
                    if (await _act('confirm', success: 'Le client est notifié.') && mounted) {
                      setState(() => _status = OrderStatus.inProgress);
                    }
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
            onPressed: () => _replyMediator(context),
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Répondre au médiateur'),
          ),
        ];
      case OrderStatus.completed:
        return [const _Info('Commande terminée. Les fonds sont disponibles.')];
      case OrderStatus.cancelled:
        return [const _Info('Commande annulée : le client a été remboursé.')];
    }
  }

  Future<void> _replyMediator(BuildContext context) async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Message au médiateur'),
        content: TextField(controller: c, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    await _act('dispute/messages', body: {'text': text}, success: 'Réponse envoyée au médiateur.');
  }

  Future<void> _deliver(BuildContext context) async {
    final msg = TextEditingController();
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
            TextField(
              controller: msg,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message au client'),
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
    if (ok != true || !context.mounted) return;
    if (await _act('deliver',
            body: {'message': msg.text.trim(), 'deliverables': <String>[]},
            success: 'Livraison envoyée au client.') &&
        mounted) {
      setState(() => _status = OrderStatus.delivered);
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
    if (ok != true || !context.mounted) return;
    if (await _act('decline', success: 'Commande refusée, client remboursé.') &&
        context.mounted) {
      Navigator.pop(context);
    }
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
  final String? quoteId;
  const QuoteReplyScreen({
    super.key,
    required this.clientName,
    required this.request,
    this.quoteId,
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
  final _delay = TextEditingController();
  final _message = TextEditingController();

  Future<void> _addLine() async {
    final label = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle ligne'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: label, decoration: const InputDecoration(labelText: 'Libellé')),
          const SizedBox(height: 8),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Montant', suffixText: 'XAF'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
        ],
      ),
    );
    final value = int.tryParse(amount.text.replaceAll(' ', ''));
    if (ok == true && label.text.trim().isNotEmpty && value != null) {
      setState(() => _lines.add((label.text.trim(), value)));
    }
  }

  Future<void> _send() async {
    if (_lines.isEmpty) {
      showInfo(context, 'Ajoutez au moins une ligne');
      return;
    }
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/quotes/${widget.quoteId}/reply', {
        'lines': [
          for (final l in _lines) {'label': l.$1, 'amount_xaf': l.$2},
        ],
        'delay': _delay.text.trim(),
        'message': _message.text.trim(),
      });
      return true;
    }, demo: true);
    if (ok != true || !mounted) return;
    if (Session.instance.online) Session.instance.refreshPro();
    Navigator.pop(context);
    showInfo(context, 'Devis envoyé à ${widget.clientName}.');
  }

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
            onPressed: _addLine,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une ligne'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _delay,
            decoration: const InputDecoration(
              labelText: 'Délai de réalisation',
              hintText: 'ex. 3 semaines',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Conditions / message'),
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
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
