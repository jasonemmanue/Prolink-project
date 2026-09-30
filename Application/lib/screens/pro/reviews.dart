import 'package:flutter/material.dart';
import '../../api/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Avis reçus + réponse publique (UC-PR-19), blocage/signalement (UC-PR-22).
class ProReviewsScreen extends StatefulWidget {
  const ProReviewsScreen({super.key});
  @override
  State<ProReviewsScreen> createState() => _ProReviewsScreenState();
}

class _ProReviewsScreenState extends State<ProReviewsScreen> {
  final _reviews = <_Review>[
    _Review(
      'Grace Fotso',
      5,
      'Très professionnelle, statuts livrés en avance.',
      2,
    ),
    _Review(
      'Paul Ndongo',
      4,
      'Bon accompagnement, un peu de délai au début.',
      6,
      reply:
          'Merci Paul ! Nous avons depuis réduit nos délais de prise en charge.',
    ),
    _Review('Brice Ewane', 2, 'Pas assez disponible pendant la procédure.', 11),
  ];

  @override
  void initState() {
    super.initState();
    if (Session.instance.online) _load();
  }

  Future<void> _load() async {
    final list = await apiCall<List>(
      context,
      (api) async => await api.get('/pros/${Session.instance.userId}/reviews',
          query: {'limit': 100}) as List,
    );
    if (list == null || !mounted) return;
    setState(() {
      _reviews
        ..clear()
        ..addAll([
          for (final r in list)
            _Review(
              r['author']['name'],
              r['stars'],
              r['text'] ?? '',
              DateTime.now().difference(DateTime.parse(r['created_at'])).inDays,
              reply: r['reply'],
              id: r['id'],
            ),
        ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_reviews.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Avis clients')),
        body: const Center(child: Text('Pas encore d\'avis : ils arrivent après vos premières commandes.')),
      );
    }
    final avg =
        _reviews.map((r) => r.stars).reduce((a, b) => a + b) / _reviews.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Avis clients')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [5, 4, 3, 2, 1].map((s) {
                        final n = _reviews.where((r) => r.stars == s).length;
                        return Row(
                          children: [
                            Text('$s', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: n / _reviews.length,
                                color: AppColors.accent,
                                backgroundColor: AppColors.surface,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._reviews.map(
            (r) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r.author,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '★' * r.stars,
                          style: const TextStyle(color: AppColors.accent),
                        ),
                        const Spacer(),
                        Text(
                          'il y a ${r.days} j',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'report') {
                              showReportSheet(context, 'cet avis');
                            } else {
                              showInfo(context, '${r.author} est bloqué.');
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'report',
                              child: Text('Signaler l\'avis'),
                            ),
                            PopupMenuItem(
                              value: 'block',
                              child: Text('Bloquer l\'utilisateur'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(r.text),
                    if (r.reply != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Votre réponse : ${r.reply}'),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _reply(r),
                          icon: const Icon(Icons.reply, size: 18),
                          label: const Text('Répondre publiquement'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reply(_Review r) async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Répondre à ${r.author}'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Restez courtois : votre réponse est publique.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Publier'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/reviews/${r.id}/reply', {'reply': text});
      return true;
    }, demo: true);
    if (ok == true && mounted) setState(() => r.reply = text);
  }
}

class _Review {
  final String author;
  final int stars;
  final String text;
  final int days;
  String? reply;
  final String id;
  _Review(this.author, this.stars, this.text, this.days, {this.reply, this.id = ''});
}
