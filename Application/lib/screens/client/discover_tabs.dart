import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../live_view.dart';
import 'pro_profile.dart';
import 'tickets.dart';

/// Filtres de recherche (§8.1.2) : ville/rayon, note, tarif, disponibilité.
class DiscoverFilters {
  String city;
  double radiusKm;
  double minRating;
  RangeValues priceRange;
  bool availableNow;
  bool verifiedOnly;
  DiscoverFilters({
    this.city = 'Toutes',
    this.radiusKm = 20,
    this.minRating = 0,
    this.priceRange = const RangeValues(0, 1000000),
    this.availableNow = false,
    this.verifiedOnly = false,
  });

  int get activeCount => [
    city != 'Toutes',
    minRating > 0,
    priceRange.start > 0 || priceRange.end < 1000000,
    availableNow,
    verifiedOnly,
  ].where((b) => b).length;

  bool matches(Pro p) =>
      (city == 'Toutes' || p.city == city) &&
      p.rating >= minRating &&
      (!verifiedOnly || p.verifiedLevel > 0);
}

Future<DiscoverFilters?> showDiscoverFilters(
  BuildContext context,
  DiscoverFilters current,
) {
  final f = DiscoverFilters(
    city: current.city,
    radiusKm: current.radiusKm,
    minRating: current.minRating,
    priceRange: current.priceRange,
    availableNow: current.availableNow,
    verifiedOnly: current.verifiedOnly,
  );
  return showModalBottomSheet<DiscoverFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, DiscoverFilters()),
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
              const SectionLabel('Ville'),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in ['Toutes', 'Douala', 'Yaoundé', 'Bafoussam'])
                    ChoiceChip(
                      label: Text(c),
                      selected: f.city == c,
                      onSelected: (_) => setState(() => f.city = c),
                    ),
                ],
              ),
              SectionLabel('Rayon : ${f.radiusKm.round()} km'),
              Slider(
                value: f.radiusKm,
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (v) => setState(() => f.radiusKm = v),
              ),
              const SectionLabel('Note minimale'),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in [0.0, 4.0, 4.5, 4.8])
                    ChoiceChip(
                      avatar: r == 0
                          ? null
                          : const Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.accent,
                            ),
                      label: Text(r == 0 ? 'Toutes' : '$r+'),
                      selected: f.minRating == r,
                      onSelected: (_) => setState(() => f.minRating = r),
                    ),
                ],
              ),
              SectionLabel(
                'Tarif : ${formatXaf(f.priceRange.start.round())} – ${formatXaf(f.priceRange.end.round())}',
              ),
              RangeSlider(
                values: f.priceRange,
                min: 0,
                max: 1000000,
                divisions: 40,
                onChanged: (v) => setState(() => f.priceRange = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible cette semaine'),
                value: f.availableNow,
                onChanged: (v) => setState(() => f.availableNow = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pros vérifiés uniquement'),
                value: f.verifiedOnly,
                onChanged: (v) => setState(() => f.verifiedOnly = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, f),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DiscoverPostsTab extends StatelessWidget {
  final String query;
  const DiscoverPostsTab({super.key, this.query = ''});
  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final posts = MockData.feed()
        .where((p) => q.isEmpty || p.text.toLowerCase().contains(q))
        .toList();
    if (posts.isEmpty) return const _NoResult();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final p = posts[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => pushScreen(context, ProProfileScreen(pro: p.author)),
            child: Row(
              children: [
                if (p.images.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: p.images.first,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    width: 96,
                    height: 96,
                    color: AppColors.primary.withOpacity(0.06),
                    child: const Icon(
                      Icons.article_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${p.author.name} · ${timeAgo(p.date)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '❤ ${p.likes}   💬 ${p.comments}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
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

class DiscoverLivesTab extends StatelessWidget {
  const DiscoverLivesTab({super.key});
  @override
  Widget build(BuildContext context) {
    final lives = MockData.lives();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: lives.length,
      itemBuilder: (_, i) {
        final l = lives[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 7,
                    child: CachedNetworkImage(
                      imageUrl: l.cover,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: l.isLive
                        ? const Pill(
                            label: 'EN DIRECT',
                            color: AppColors.danger,
                            icon: Icons.circle,
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${formatDate(l.startAt)} · ${l.startAt.hour}h',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              ListTile(
                title: Text(
                  l.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(l.pro),
                trailing: l.isLive
                    ? FilledButton(
                        onPressed: () =>
                            pushScreen(context, LiveViewScreen(live: l)),
                        child: const Text('Regarder'),
                      )
                    : l.paying
                    ? OutlinedButton(
                        onPressed: () => showTicketSheet(context, l),
                        child: Text(formatXaf(l.priceXaf)),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => showInfo(
                          context,
                          'Rappel activé : notification 15 min avant.',
                        ),
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 18,
                        ),
                        label: const Text('Rappel'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DiscoverEventsTab extends StatelessWidget {
  const DiscoverEventsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final events = [
      (
        'Salon de l\'entrepreneuriat',
        'Douala · Palais des congrès',
        now.add(const Duration(days: 6)),
        'Gratuit',
        MockData.pros[0],
      ),
      (
        'Dégustation cuisine fusion',
        'Yaoundé · Bastos',
        now.add(const Duration(days: 12)),
        formatXaf(15000),
        MockData.pros[1],
      ),
      (
        'Hackathon Flutter Cameroun',
        'Douala · Akwa',
        now.add(const Duration(days: 20)),
        'Gratuit',
        MockData.pros[2],
      ),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final e = events[i];
        return Card(
          child: ListTile(
            leading: Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${e.$3.day}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    formatDate(e.$3).split(' ').last,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            title: Text(
              e.$1,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${e.$2}\npar ${e.$5.name}'),
            isThreeLine: true,
            trailing: Pill(
              label: e.$4,
              color: e.$4 == 'Gratuit' ? AppColors.success : AppColors.accent,
            ),
            onTap: () => showInfo(context, 'Inscription enregistrée : ${e.$1}'),
          ),
        );
      },
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult();
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Aucun résultat',
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
}
