import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'service_detail.dart';
import 'chat.dart';
import 'discover_tabs.dart';

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
                  onPressed: () => showReportSheet(context, 'ce profil'),
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
                        const Expanded(child: _FollowButtons()),
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
              ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: 3,
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: Text('Publication ${i + 1}'),
                    subtitle: const Text(
                      'Astuce ou actualité pro. Aperçu du fil de ce professionnel.',
                    ),
                  ),
                ),
              ),
              GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 6,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: pro.cover,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, i) => _ServiceRow(pro: pro, s: services[i]),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: services.length,
              ),
              const DiscoverLivesTab(),
              ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: 4,
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.star, color: AppColors.accent),
                    title: const Text('5 · Excellente prestation'),
                    subtitle: const Text(
                      'Réactif, professionnel, pédagogue. Je recommande.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
  const _FollowButtons();
  @override
  State<_FollowButtons> createState() => _FollowButtonsState();
}

class _FollowButtonsState extends State<_FollowButtons> {
  bool _following = false;
  bool _bell = false;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _following
              ? OutlinedButton(
                  onPressed: () => setState(() {
                    _following = false;
                    _bell = false;
                  }),
                  child: const Text('Abonné'),
                )
              : ElevatedButton(
                  onPressed: () => setState(() => _following = true),
                  child: const Text('Suivre'),
                ),
        ),
        if (_following) ...[
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: 'Cloche de notification',
            onPressed: () {
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
