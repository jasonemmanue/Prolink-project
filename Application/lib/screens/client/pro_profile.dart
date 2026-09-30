import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'service_detail.dart';
import 'chat.dart';
import 'discover_tabs.dart';
import 'post_detail.dart';

class ProProfileScreen extends StatelessWidget {
  final Pro pro;
  const ProProfileScreen({super.key, required this.pro});

  @override
  Widget build(BuildContext context) {
    final services = MockData.servicesOf(pro);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              actions: [
                IconButton(
                  onPressed: () => showInfo(context, 'Lien du profil copié'),
                  icon: const Icon(Icons.share_outlined),
                ),
                IconButton(
                  onPressed: () => showReportSheet(
                    context,
                    'ce profil',
                    type: 'pro',
                    id: pro.id,
                  ),
                  icon: const Icon(Icons.flag_outlined),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: pro.cover, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(url: pro.avatar, size: 66),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      pro.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  VerifiedBadge(level: pro.verifiedLevel),
                                ],
                              ),
                              Text(
                                '${pro.job} · ${pro.city}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Pill(
                                    icon: Icons.star,
                                    label: '${pro.rating}',
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Pill(
                                    icon: Icons.people,
                                    label: '${pro.followers} abonnés',
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pro.bio,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _FollowButtons(proId: pro.id)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(peer: pro),
                              ),
                            ),
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text('Contacter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverPersistentHeader(
              pinned: true,
              delegate: _TabsDelegate(),
            ),
          ],
          body: TabBarView(
            children: [
              _PostsTab(pro: pro),
              GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _portfolio.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(fit: StackFit.expand, children: [
                    CachedNetworkImage(
                      imageUrl: _portfolio[i].$1,
                      fit: BoxFit.cover,
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.black45,
                        child: Text(_portfolio[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ]),
                ),
              ),
              ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, i) => _ServiceRow(pro: pro, s: services[i]),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: services.length,
              ),
              const DiscoverLivesTab(),
              _ReviewsTab(proId: pro.id),
            ],
          ),
        ),
      ),
    );
  }
}

const _portfolio = [
  ('https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=600',
      'Dossier de création SARL'),
  ('https://images.unsplash.com/photo-1521791136064-7986c2920216?w=600',
      'Signature partenariat'),
  ('https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=600',
      'Atelier entrepreneurs'),
  ('https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600',
      'Événement client'),
  ('https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600',
      'Séminaire d\'entreprise'),
  ('https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600',
      'Programme bien-être'),
];

const _reviews = [
  ('Grace Fotso', 5, 'Très professionnelle, livrables rendus en avance. Je recommande sans hésiter.', 'il y a 2 jours · Pack complet'),
  ('Paul Ndongo', 4, 'Bon accompagnement, un peu de délai au démarrage mais résultat impeccable.', 'il y a 6 jours · Formule Standard'),
  ('Estelle Kamga', 5, 'Explications claires, réponses rapides dans le chat. Top !', 'il y a 2 semaines · Consultation'),
  ('Yannick Onana', 5, 'Deuxième commande, toujours aussi sérieux. Paiement séquestre rassurant.', 'il y a 3 semaines · Formule Premium'),
  ('Serge Abena', 4, 'Prestation conforme à la description. Je repasserai.', 'il y a 1 mois · Formule Basic'),
];

/// Publications de ce pro, tirées du fil.
class _PostsTab extends StatelessWidget {
  final Pro pro;
  const _PostsTab({required this.pro});
  @override
  Widget build(BuildContext context) {
    final posts = MockData.feed().where((p) => p.author.id == pro.id).toList();
    if (posts.isEmpty) {
      return Center(
        child: Text('Aucune publication pour le moment',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final p = posts[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => pushScreen(context, PostDetailScreen(post: p)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.images.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                        imageUrl: p.images.first, fit: BoxFit.cover),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.text, maxLines: 4, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text('❤ ${p.likes}   💬 ${p.comments}   · ${timeAgo(p.date)}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final Pro pro;
  final Service s;
  const _ServiceRow({required this.pro, required this.s});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          s.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  Pill(icon: Icons.timer, label: s.duration),
                  const SizedBox(width: 6),
                  Pill(icon: Icons.place, label: s.modality),
                ],
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              s.pricingType == 'quote'
                  ? 'Sur devis'
                  : s.pricingType == 'from'
                  ? 'à partir de'
                  : '',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (s.priceXaf > 0)
              Text(
                formatXaf(s.priceXaf),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(pro: pro, service: s),
          ),
        ),
      ),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  const _TabsDelegate();
  @override
  Widget build(BuildContext context, double _, bool __) => Container(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: const TabBar(
      isScrollable: true,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      tabs: [
        Tab(text: 'Publications'),
        Tab(text: 'Réalisations'),
        Tab(text: 'Services & Tarifs'),
        Tab(text: 'Lives'),
        Tab(text: 'Avis'),
      ],
    ),
  );
  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => false;
}

/// Suivre (gratuit) + cloche de notification (UC-IN-04 / UC-IN-05).
class _FollowButtons extends StatefulWidget {
  final String proId;
  const _FollowButtons({required this.proId});
  @override
  State<_FollowButtons> createState() => _FollowButtonsState();
}

class _FollowButtonsState extends State<_FollowButtons> {
  bool _following = false;
  bool _bell = false;

  @override
  void initState() {
    super.initState();
    if (Session.instance.online) _load();
  }

  Future<void> _load() async {
    try {
      final r = await Session.instance.api.get('/pros/${widget.proId}');
      if (mounted) {
        setState(() {
          _following = r['is_following'] ?? false;
          _bell = r['notify'] ?? false;
        });
      }
    } catch (_) {}
  }

  /// follow=null : désabonnement ; sinon (dés)active la cloche.
  Future<bool> _sync({required bool follow, bool bell = false}) async {
    final ok = await apiCall<bool>(context, (api) async {
      final path = '/pros/${widget.proId}/follow';
      follow ? await api.post(path, null, {'notify': bell}) : await api.delete(path);
      return true;
    }, demo: true);
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _following
              ? OutlinedButton(
                  onPressed: () async {
                    if (await _sync(follow: false) && mounted) {
                      setState(() {
                        _following = false;
                        _bell = false;
                      });
                    }
                  },
                  child: const Text('Abonné'),
                )
              : ElevatedButton(
                  onPressed: () async {
                    if (await _sync(follow: true) && mounted) {
                      setState(() => _following = true);
                    }
                  },
                  child: const Text('Suivre'),
                ),
        ),
        if (_following) ...[
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: 'Cloche de notification',
            onPressed: () async {
              if (!await _sync(follow: true, bell: !_bell) || !mounted) return;
              setState(() => _bell = !_bell);
              showInfo(
                context,
                _bell
                    ? 'Vous serez notifié de chaque publication et live.'
                    : 'Notifications désactivées pour ce pro.',
              );
            },
            icon: Icon(
              _bell ? Icons.notifications_active : Icons.notifications_none,
              color: _bell ? AppColors.accent : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// Avis clients : API en ligne, exemples en démo.
class _ReviewsTab extends StatefulWidget {
  final String proId;
  const _ReviewsTab({required this.proId});
  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  List<(String, int, String, String)> _items = List.of(_reviews);

  @override
  void initState() {
    super.initState();
    if (Session.instance.online) _load();
  }

  Future<void> _load() async {
    try {
      final list = await Session.instance.api
          .get('/pros/${widget.proId}/reviews', query: {'limit': 50}) as List;
      if (!mounted) return;
      setState(() => _items = [
            for (final r in list)
              (
                r['author']['name'] as String,
                r['stars'] as int,
                [r['text'] ?? '', if (r['reply'] != null) '\n↳ Réponse du pro : ${r['reply']}']
                    .join(),
                timeAgo(DateTime.parse(r['created_at']).toLocal()),
              ),
          ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Center(
        child: Text('Pas encore d\'avis',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final r = _items[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.secondary.withOpacity(0.15),
                    child: Text(r.$1.isEmpty ? '?' : r.$1[0],
                        style: const TextStyle(color: AppColors.secondary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text('★' * r.$2,
                      style: const TextStyle(color: AppColors.accent)),
                ]),
                const SizedBox(height: 6),
                Text(r.$3),
                const SizedBox(height: 4),
                Text(r.$4,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}
