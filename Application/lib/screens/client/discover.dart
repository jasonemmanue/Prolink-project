import 'package:flutter/material.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'pro_profile.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String _query = '';
  String? _cat;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final pros = MockData.pros.where((p) {
      final catOk = _cat == null || p.category == _cat;
      final qOk = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.job.toLowerCase().contains(_query.toLowerCase()) ||
          p.city.toLowerCase().contains(_query.toLowerCase());
      return catOk && qOk;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un pro, un service, une ville…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: MockData.categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return FilterChip(
                    label: const Text('Toutes'),
                    selected: _cat == null,
                    onSelected: (_) => setState(() => _cat = null),
                  );
                }
                final c = MockData.categories[i - 1];
                return FilterChip(
                  label: Text(c),
                  selected: _cat == c,
                  onSelected: (_) => setState(() => _cat = _cat == c ? null : c),
                );
              },
            ),
          ),
          TabBar(
            controller: _tab,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Pros'),
              Tab(text: 'Publications'),
              Tab(text: 'Lives'),
              Tab(text: 'Événements'),
              Tab(text: 'Groupes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ProGrid(pros: pros),
                const _Placeholder(icon: Icons.article, label: 'Articles & posts'),
                const _Placeholder(icon: Icons.podcasts, label: 'Lives à venir'),
                const _Placeholder(icon: Icons.event, label: 'Événements pros'),
                const _Placeholder(icon: Icons.groups, label: 'Groupes publics'),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ProGrid extends StatelessWidget {
  final List<Pro> pros;
  const _ProGrid({required this.pros});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: pros.length,
      itemBuilder: (_, i) {
        final p = pros[i];
        return InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ProProfileScreen(pro: p))),
          borderRadius: BorderRadius.circular(14),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Avatar(url: p.avatar, size: 72)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700))),
                    VerifiedBadge(level: p.verifiedLevel),
                  ]),
                  Text(p.job,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star,
                        color: AppColors.accent, size: 14),
                    const SizedBox(width: 2),
                    Text('${p.rating}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Icon(Icons.people,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Text('${p.followers}',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ]),
                  const Spacer(),
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6)),
                          child: const Text('Voir'))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Placeholder({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
