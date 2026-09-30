import 'package:flutter/material.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Sponsorisation d'un post ou du profil « en 3 taps » (UC-PR-16).
class SponsorScreen extends StatefulWidget {
  const SponsorScreen({super.key});
  @override
  State<SponsorScreen> createState() => _SponsorScreenState();
}

class _SponsorScreenState extends State<SponsorScreen> {
  int _step = 0;
  String _target = 'post';
  String _goal = 'visits';
  double _budget = 2000;
  double _days = 5;
  final Set<String> _cities = {'Douala'};

  int get _total => (_budget * _days).round();

  Future<void> _launch() async {
    final s = Session.instance;
    String? targetId;
    if (s.online && _target != 'profile') {
      targetId = _target == 'post'
          ? MockData.feed().where((p) => p.author.id == s.userId).map((p) => p.id).firstOrNull
          : MockData.servicesOf(s.mePro).map((x) => x.id).firstOrNull;
      if (targetId == null) {
        showInfo(context,
            _target == 'post' ? 'Publiez d\'abord un post à sponsoriser' : 'Créez d\'abord une prestation');
        return;
      }
    }
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/campaigns', {
        'target_type': _target,
        if (targetId != null) 'target_id': targetId,
        'goal': _goal,
        'cities': _cities.toList(),
        'daily_budget_xaf': _budget.round(),
        'days': _days.round(),
      });
      return true;
    }, demo: true);
    if (ok != true || !mounted) return;
    await s.afterMoneyAction();
    if (!mounted) return;
    Navigator.pop(context);
    showInfo(
      context,
      'Campagne soumise à validation (≈ 2 h). ${formatXaf(_total)} réservés.',
    );
  }
  int get _reach => (_total / 1000 * 420).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sponsoriser · étape ${_step + 1}/3')),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / 3),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: switch (_step) {
                0 => _what(),
                1 => _who(),
                _ => _review(),
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Retour'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _launch();
                      }
                    },
                    child: Text(
                      _step < 2 ? 'Suivant' : 'Lancer · ${formatXaf(_total)}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _what() => [
    const Text(
      'Que voulez-vous mettre en avant ?',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 12),
    for (final t in const [
      (
        'post',
        'Une publication',
        'Création de SARL — 3 formules',
        Icons.article_outlined,
      ),
      ('profile', 'Mon profil', 'Gagner des abonnés', Icons.person_outline),
      (
        'service',
        'Une prestation',
        'Consultation juridique 30 min',
        Icons.storefront_outlined,
      ),
    ])
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _target == t.$1 ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTile(
          leading: Icon(t.$4, color: AppColors.primary),
          title: Text(
            t.$2,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(t.$3),
          onTap: () => setState(() => _target = t.$1),
        ),
      ),
    const SectionLabel('Objectif'),
    Wrap(
      spacing: 8,
      children: [
        for (final g in const [
          ('visits', 'Visites du profil'),
          ('messages', 'Messages'),
          ('orders', 'Commandes'),
        ])
          ChoiceChip(
            label: Text(g.$2),
            selected: _goal == g.$1,
            onSelected: (_) => setState(() => _goal = g.$1),
          ),
      ],
    ),
  ];

  List<Widget> _who() => [
    const Text(
      'Audience & budget',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
    const SectionLabel('Villes'),
    Wrap(
      spacing: 8,
      children: [
        for (final c in ['Douala', 'Yaoundé', 'Bafoussam', 'Garoua', 'Kribi'])
          FilterChip(
            label: Text(c),
            selected: _cities.contains(c),
            onSelected: (v) =>
                setState(() => v ? _cities.add(c) : _cities.remove(c)),
          ),
      ],
    ),
    const SectionLabel('Centres d\'intérêt'),
    Wrap(
      spacing: 8,
      children: [
        for (final c in MockData.categories.take(5))
          FilterChip(
            label: Text(c),
            selected: c.startsWith('D'),
            onSelected: (_) {},
          ),
      ],
    ),
    SectionLabel('Budget quotidien : ${formatXaf(_budget.round())}'),
    Slider(
      value: _budget,
      min: 1000,
      max: 20000,
      divisions: 19,
      onChanged: (v) => setState(() => _budget = v),
    ),
    SectionLabel('Durée : ${_days.round()} jours'),
    Slider(
      value: _days,
      min: 1,
      max: 30,
      divisions: 29,
      onChanged: (v) => setState(() => _days = v),
    ),
  ];

  List<Widget> _review() => [
    const Text(
      'Récapitulatif',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 12),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Contenu', switch (_target) {
              'profile' => 'Mon profil',
              'service' => 'Prestation',
              _ => 'Publication',
            }),
            _row(
              'Villes',
              _cities.isEmpty ? 'Tout le Cameroun' : _cities.join(', '),
            ),
            _row(
              'Budget',
              '${formatXaf(_budget.round())} × ${_days.round()} j',
            ),
            const Divider(),
            _row('Total', formatXaf(_total), bold: true),
            _row(
              'Portée estimée',
              '$_reach – ${(_reach * 1.6).round()} personnes',
            ),
          ],
        ),
      ),
    ),
    const SectionLabel('Aperçu dans le fil'),
    Card(
      child: ListTile(
        leading: Avatar(url: Session.instance.mePro.avatar),
        title: Text(
          Session.instance.mePro.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Création de SARL — 3 formules, prix affichés.'),
        trailing: const Pill(
          label: 'Sponsorisé',
          color: AppColors.accent,
          icon: Icons.campaign,
        ),
      ),
    ),
    const SizedBox(height: 8),
    Text(
      'Débité du solde disponible. Arrêt possible à tout moment ; le budget non dépensé est restitué.',
      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
  ];

  Widget _row(String k, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(k, style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Packs Premium / Business (UC-PR-20).
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const plans = [
      (
        'Gratuit',
        0,
        'Offert 6 mois au lancement',
        [
          'Profil vitrine + portfolio',
          'Catalogue jusqu\'à 5 prestations',
          'Lives gratuits',
        ],
        false,
      ),
      (
        'Premium',
        9900,
        'Pour les indépendants actifs',
        [
          'Prestations illimitées',
          'Lives payants & replays',
          'Statistiques détaillées + export CSV',
          'Badge Premium',
        ],
        true,
      ),
      (
        'Business',
        29900,
        'Cabinets & équipes',
        [
          'Tout Premium',
          '5 comptes collaborateurs',
          'Groupes payants illimités',
          'Crédit sponsorisation 10 000 XAF/mois',
        ],
        false,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Packs pro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: plans.map((p) {
          final plan = Session.instance.online ? (Session.instance.me?['pro']?['plan'] ?? 'free') : 'free';
          final current = {'free': 'Gratuit', 'premium': 'Premium', 'business': 'Business'}[plan] == p.$1;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: p.$5 ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.$1,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (p.$5)
                        const Pill(label: 'Populaire', color: AppColors.accent),
                      const Spacer(),
                      Text(
                        p.$2 == 0 ? 'Gratuit' : '${formatXaf(p.$2)}/mois',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(p.$3, style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...p.$4.map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(f)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: current
                        ? const OutlinedButton(
                            onPressed: null,
                            child: Text('Pack actuel'),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              final ok = await apiCall<bool>(context, (api) async {
                                await api.post('/plans/subscribe',
                                    {'plan': p.$1.toLowerCase(), 'months': 1});
                                await Session.instance.refreshMe();
                                return true;
                              }, demo: true, success: 'Pack ${p.$1} activé ✔');
                              if (ok == true) Session.instance.afterMoneyAction();
                            },
                            child: Text('Passer ${p.$1}'),
                          ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
