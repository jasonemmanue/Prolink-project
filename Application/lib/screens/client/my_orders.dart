import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'chat.dart';
import 'groups.dart';

/// « Mes commandes » côté internaute (UC-IN-12).
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    // En ligne : uniquement les commandes passées par l'utilisateur.
    final orders = MockData.orders()
        .where((o) => !session.online || o.pro.id != session.userId)
        .toList();
    final active = orders
        .where(
          (o) =>
              o.status != OrderStatus.completed &&
              o.status != OrderStatus.disputed &&
              o.status != OrderStatus.cancelled,
        )
        .toList();
    final past = orders.where((o) => !active.contains(o)).toList();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes commandes'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'En cours'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_list(context, active), _list(context, past)],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'Aucune commande',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Avatar(url: o.pro.avatar, size: 44),
            title: Text(
              o.service.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${o.pro.name} · ${o.code}'),
                  const SizedBox(height: 6),
                  OrderStatusPill(o.status),
                ],
              ),
            ),
            trailing: Text(
              formatXaf(o.amountXaf),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            onTap: () => pushScreen(context, OrderTrackingScreen(order: o)),
          ),
        );
      },
    );
  }
}

/// Suivi d'une commande escrow (UC-IN-12 à UC-IN-14, annexe C.1).
class OrderTrackingScreen extends StatefulWidget {
  final Order order;
  const OrderTrackingScreen({super.key, required this.order});
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderStatus _status = widget.order.status;

  int get _step => switch (_status) {
    OrderStatus.pending => 1,
    OrderStatus.inProgress => 2,
    OrderStatus.delivered => 3,
    OrderStatus.completed => 4,
    OrderStatus.disputed => 3,
    OrderStatus.cancelled => 0,
  };

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final steps = [
      ('Paiement bloqué en séquestre', formatDate(o.createdAt)),
      ('Commande confirmée par le pro', 'sous 24 h'),
      ('Prestation en cours', 'deadline ${formatDate(o.deadline)}'),
      ('Livraison', 'validation sous 72 h'),
      ('Paiement libéré au pro', ''),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('Commande ${o.code}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Avatar(url: o.pro.avatar, size: 48),
              title: Text(
                o.service.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${o.pro.name}\nFormule ${o.variant}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.chat_outlined, color: AppColors.primary),
                onPressed: () => pushScreen(context, ChatScreen(peer: o.pro)),
              ),
            ),
          ),
          if (_status == OrderStatus.disputed)
            _Banner(
              color: AppColors.danger,
              icon: Icons.gavel,
              text:
                  'Litige ouvert. Le séquestre est gelé ; un médiateur ProLink vous répond sous 5 jours ouvrés.',
            ),
          if (_status == OrderStatus.delivered)
            _Banner(
              color: AppColors.primary,
              icon: Icons.timer_outlined,
              text:
                  'Le pro a marqué la prestation comme livrée. Sans action de votre part, le paiement sera libéré dans 72 h.',
            ),
          const SectionLabel('Suivi'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: List.generate(steps.length, (i) {
                  final done = i <= _step;
                  final current = i == _step;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      done ? Icons.check_circle : Icons.radio_button_off,
                      color: done
                          ? (current && _status == OrderStatus.disputed
                                ? AppColors.danger
                                : AppColors.success)
                          : AppColors.divider,
                    ),
                    title: Text(
                      steps[i].$1,
                      style: TextStyle(
                        fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    trailing: Text(
                      steps[i].$2,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SectionLabel('Paiement'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Montant', formatXaf(o.amountXaf)),
                  _row('Moyen', switch (o.paymentMethod) {
                  'wallet' => 'Portefeuille ProLink',
                  'orange' => 'Orange Money',
                  'card' => 'Carte bancaire',
                  _ => 'MTN Mobile Money',
                }),
                  _row(
                    'Statut',
                    _status == OrderStatus.completed
                        ? 'Libéré'
                        : 'En séquestre',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._actions(context, o),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, Order o) {
    switch (_status) {
      case OrderStatus.delivered:
        return [
          ElevatedButton.icon(
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Valider la prestation'),
            onPressed: () async {
              final ok = await _act(context, o, 'validate',
                  success: 'Paiement libéré au professionnel.');
              if (!ok || !context.mounted) return;
              setState(() => _status = OrderStatus.completed);
              await pushScreen(context, ReviewScreen(order: o));
            },
          ),
          const SizedBox(height: 8),
          _disputeButton(context, o),
        ];
      case OrderStatus.completed:
        return [
          OutlinedButton.icon(
            icon: const Icon(Icons.star_outline),
            label: const Text('Noter le professionnel'),
            onPressed: () => pushScreen(context, ReviewScreen(order: o)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.receipt_outlined),
            label: const Text('Télécharger la facture'),
            onPressed: () =>
                showInfo(context, 'Facture ${o.code}.pdf enregistrée'),
          ),
        ];
      case OrderStatus.disputed:
        return [
          OutlinedButton.icon(
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Voir le dossier de litige'),
            onPressed: () => pushScreen(context, DisputeScreen(order: o)),
          ),
        ];
      default:
        return [
          _disputeButton(context, o),
          const SizedBox(height: 8),
          if (_status == OrderStatus.pending)
            TextButton(
              onPressed: () async {
                final ok = await _act(context, o, 'cancel',
                    success: 'Commande annulée : ${formatXaf(o.amountXaf)} recrédités.');
                if (ok && context.mounted) {
                  setState(() => _status = OrderStatus.cancelled);
                }
              },
              child: const Text('Annuler la commande'),
            ),
        ];
    }
  }

  /// Transition d'état côté serveur (validate, cancel…).
  Future<bool> _act(BuildContext context, Order o, String action,
      {String? success}) async {
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/orders/${o.id}/$action');
      return true;
    }, demo: true, success: success);
    if (ok == true) await Session.instance.afterMoneyAction();
    return ok == true;
  }

  Widget _disputeButton(BuildContext context, Order o) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.danger,
      side: const BorderSide(color: AppColors.danger),
    ),
    icon: const Icon(Icons.report_problem_outlined),
    label: const Text('Signaler un problème'),
    onPressed: () async {
      final opened = await pushScreen<bool>(context, DisputeScreen(order: o));
      if (opened == true) setState(() => _status = OrderStatus.disputed);
    },
  );

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

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _Banner({required this.color, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Ouverture / suivi d'un litige (UC-IN-13).
class DisputeScreen extends StatefulWidget {
  final Order order;
  const DisputeScreen({super.key, required this.order});
  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  String? _reason;
  String _remedy = 'refund';
  bool _busy = false;
  final _desc = TextEditingController();
  final _msg = TextEditingController();
  List<(String, String, String)>? _events;

  @override
  void initState() {
    super.initState();
    if (widget.order.status == OrderStatus.disputed && Session.instance.online) {
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    final d = await apiCall<Map>(context,
        (api) async => await api.get('/orders/${widget.order.id}/dispute') as Map);
    if (d == null || !mounted) return;
    final me = Session.instance.userId;
    setState(() => _events = [
          for (final e in (d['events'] as List))
            (
              e['by'] == me ? 'Vous' : 'ProLink / autre partie',
              e['text'] as String,
              timeAgo(DateTime.parse(e['at']).toLocal()),
            ),
        ]);
  }

  Future<void> _open() async {
    setState(() => _busy = true);
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/orders/${widget.order.id}/dispute', {
        'reason': _reason,
        'remedy': _remedy,
        'description': _desc.text.trim(),
      });
      return true;
    }, demo: true);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok != true) return;
    await Session.instance.afterMoneyAction();
    if (!mounted) return;
    Navigator.pop(context, true);
    showInfo(context, 'Litige ouvert. Un médiateur vous contactera sous 48 h.');
  }

  Future<void> _sendMessage() async {
    final text = _msg.text.trim();
    if (text.isEmpty) return;
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/orders/${widget.order.id}/dispute/messages', {'text': text});
      return true;
    }, demo: true, success: 'Message ajouté au dossier');
    if (ok == true) {
      _msg.clear();
      if (Session.instance.online) _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    if (o.status == OrderStatus.disputed) return _followUp(o);
    const reasons = [
      'Prestation non livrée',
      'Livrable non conforme à la description',
      'Retard important',
      'Comportement inapproprié du pro',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler un problème')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Commande ${o.code} · ${formatXaf(o.amountXaf)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Le paiement reste bloqué en séquestre pendant la médiation.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SectionLabel('Motif'),
          ...reasons.map(
            (r) => Card(
              child: ListTile(
                leading: Icon(
                  _reason == r
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.primary,
                ),
                title: Text(r),
                onTap: () => setState(() => _reason = r),
              ),
            ),
          ),
          const SectionLabel('Solution souhaitée'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'refund', label: Text('Remboursement')),
              ButtonSegment(value: 'partial', label: Text('Partiel')),
              ButtonSegment(value: 'redo', label: Text('Reprise')),
            ],
            selected: {_remedy},
            onSelectionChanged: (s) => setState(() => _remedy = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _desc,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Décrivez le problème',
              hintText: 'Dates, échanges, ce qui était prévu…',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showInfo(context, 'Sélection des preuves…'),
            icon: const Icon(Icons.attach_file),
            label: const Text('Joindre des preuves (photos, PDF)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: _reason == null || _busy ? null : _open,
            child: const Text('Ouvrir le litige'),
          ),
        ],
      ),
    );
  }

  Widget _followUp(Order o) {
    final events = _events ??
        const [
          ('Litige ouvert par le client', 'Livrable non conforme', 'J-5'),
          ('Réponse du professionnel', 'Propose une reprise sous 7 jours', 'J-4'),
          ('Médiateur assigné', 'Sandrine — équipe ProLink', 'J-3'),
          ('Pièces demandées', 'Captures du livrable attendues', 'J-1'),
        ];
    return Scaffold(
      appBar: AppBar(title: Text('Litige ${o.code}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Banner(
            color: AppColors.danger,
            icon: Icons.gavel,
            text: 'Séquestre gelé. Décision attendue sous 5 jours ouvrés.',
          ),
          const SectionLabel('Historique du dossier'),
          ...events.map(
            (e) => Card(
              child: ListTile(
                leading: const Icon(Icons.history, color: AppColors.primary),
                title: Text(
                  e.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(e.$2),
                trailing: Text(
                  e.$3,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _msg,
            decoration: InputDecoration(
              hintText: 'Ajouter un message au dossier…',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Notation et avis après prestation (UC-IN-14).
class ReviewScreen extends StatefulWidget {
  final Order order;
  const ReviewScreen({super.key, required this.order});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _stars = 5;
  final Set<String> _tags = {'Ponctuel'};
  final _text = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      appBar: AppBar(title: const Text('Votre avis')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: Avatar(url: o.pro.avatar, size: 72)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              o.pro.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Center(child: Text(o.service.title)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                iconSize: 40,
                onPressed: () => setState(() => _stars = i + 1),
                icon: Icon(
                  i < _stars ? Icons.star : Icons.star_border,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (final t in [
                'Ponctuel',
                'Professionnel',
                'Pédagogue',
                'Bon rapport qualité/prix',
                'Réactif',
              ])
                FilterChip(
                  label: Text(t),
                  selected: _tags.contains(t),
                  onSelected: (v) =>
                      setState(() => v ? _tags.add(t) : _tags.remove(t)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Votre commentaire (public)',
              hintText: 'Partagez votre expérience…',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final ok = await apiCall<bool>(context, (api) async {
                await api.post('/orders/${o.id}/review', {
                  'stars': _stars,
                  'text': _text.text.trim(),
                  'tags': _tags.toList(),
                });
                return true;
              }, demo: true);
              if (ok != true || !context.mounted) return;
              Navigator.pop(context);
              showInfo(context, 'Merci ! Votre avis est publié.');
            },
            child: const Text('Publier l\'avis'),
          ),
        ],
      ),
    );
  }
}

/// Demande de devis pour une prestation « sur devis » (UC-IN-10).
class QuoteRequestScreen extends StatefulWidget {
  final Pro pro;
  final Service service;
  const QuoteRequestScreen({
    super.key,
    required this.pro,
    required this.service,
  });
  @override
  State<QuoteRequestScreen> createState() => _QuoteRequestScreenState();
}

class _QuoteRequestScreenState extends State<QuoteRequestScreen> {
  String _budget = '100k-500k';
  String _urgency = 'month';
  final _need = TextEditingController();
  final _place = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demander un devis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Avatar(url: widget.pro.avatar, size: 42),
              title: Text(
                widget.service.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(widget.pro.name),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _need,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Décrivez votre besoin',
              hintText: 'Contexte, objectifs, contraintes…',
            ),
          ),
          const SectionLabel('Budget indicatif'),
          Wrap(
            spacing: 8,
            children: [
              for (final b in const [
                ('<100k', '< 100 000 XAF'),
                ('100k-500k', '100 000 – 500 000'),
                ('>500k', '> 500 000 XAF'),
              ])
                ChoiceChip(
                  label: Text(b.$2),
                  selected: _budget == b.$1,
                  onSelected: (_) => setState(() => _budget = b.$1),
                ),
            ],
          ),
          const SectionLabel('Délai souhaité'),
          Wrap(
            spacing: 8,
            children: [
              for (final u in const [
                ('week', 'Cette semaine'),
                ('month', 'Ce mois-ci'),
                ('flex', 'Flexible'),
              ])
                ChoiceChip(
                  label: Text(u.$2),
                  selected: _urgency == u.$1,
                  onSelected: (_) => setState(() => _urgency = u.$1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _place,
            decoration: const InputDecoration(
              labelText: 'Lieu d\'intervention',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showAttachmentSheet(context),
            icon: const Icon(Icons.attach_file),
            label: const Text('Joindre un cahier des charges'),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            onPressed: () async {
              if (_need.text.trim().length < 10) {
                showInfo(context, 'Décrivez votre besoin (10 caractères minimum)');
                return;
              }
              final ok = await apiCall<bool>(context, (api) async {
                await api.post('/quotes', {
                  'pro_id': widget.pro.id,
                  if (widget.service.proId.isNotEmpty) 'service_id': widget.service.id,
                  'description': _need.text.trim(),
                  'budget': _budget,
                  'urgency': _urgency,
                  'location': _place.text.trim(),
                });
                return true;
              }, demo: true);
              if (ok != true || !context.mounted) return;
              Navigator.pop(context);
              showInfo(
                context,
                'Demande envoyée. ${widget.pro.name} répond en moyenne sous 6 h.',
              );
            },
            label: const Text('Envoyer la demande'),
          ),
        ],
      ),
    );
  }
}
