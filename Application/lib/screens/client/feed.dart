import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../live_view.dart';
import 'pro_profile.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = MockData.feed();
    final lives = MockData.lives().where((l) => l.isLive).toList();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const AppLogo(size: 34),
            actions: [
              IconButton(
                icon: const Badge(
                    label: Text('12'),
                    child: Icon(Icons.notifications_outlined)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              const SizedBox(width: 6),
            ],
          ),
          SliverToBoxAdapter(child: _Stories()),
          if (lives.isNotEmpty)
            SliverToBoxAdapter(child: _LivesBanner(lives: lives)),
          SliverList.builder(
            itemCount: posts.length,
            itemBuilder: (_, i) => _PostCard(post: posts[i]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _Stories extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: MockData.pros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = MockData.pros[i];
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    AppColors.accent,
                    AppColors.primary,
                  ]),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Avatar(url: p.avatar, size: 60),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  p.name.split(' ').last,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _LivesBanner extends StatelessWidget {
  final List<LiveEvent> lives;
  const _LivesBanner({required this.lives});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: lives.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final l = lives[i];
          return InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => LiveViewScreen(live: l))),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(l.cover),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.35), BlendMode.darken),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('LIVE',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.remove_red_eye,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 3),
                    Text('${l.viewers}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12))
                  ]),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.title,
                          maxLines: 2,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      Text(l.pro,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  const _PostCard({required this.post});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProProfileScreen(pro: post.author))),
                  child: Avatar(url: post.author.avatar, size: 40),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(post.author.name,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        VerifiedBadge(level: post.author.verifiedLevel),
                      ]),
                      Text('${post.author.job} · ${post.author.city}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (post.sponsored)
                  const Pill(
                      label: 'Sponsorisé',
                      color: AppColors.accent,
                      icon: Icons.campaign),
                IconButton(
                    icon: const Icon(Icons.more_horiz), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.text, style: const TextStyle(fontSize: 14, height: 1.35)),
            if (post.images.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: post.images.length == 1
                      ? CachedNetworkImage(
                          imageUrl: post.images.first, fit: BoxFit.cover)
                      : Row(children: [
                          Expanded(
                              child: CachedNetworkImage(
                                  imageUrl: post.images[0], fit: BoxFit.cover)),
                          const SizedBox(width: 2),
                          Expanded(
                              child: CachedNetworkImage(
                                  imageUrl: post.images[1], fit: BoxFit.cover)),
                        ]),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(children: [
              _Action(Icons.favorite_border, '${post.likes}'),
              _Action(Icons.mode_comment_outlined, '${post.comments}'),
              _Action(Icons.share_outlined, 'Partager'),
              const Spacer(),
              _Action(Icons.bookmark_border, ''),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Action(this.icon, this.label);
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: AppColors.textSecondary),
      label: Text(label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8)),
    );
  }
}
