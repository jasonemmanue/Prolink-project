import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'pro_profile.dart';

/// Détail d'un post avec commentaires (UC-IN-06).
class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _c = TextEditingController();
  final _comments = <(String, String, bool)>[
    ('Grace Fotso', 'Très utile, merci pour le partage !', false),
    ('Paul Ndongo', 'Est-ce valable aussi pour une SA ?', false),
    (
      '',
      'Oui, avec quelques différences de capital minimum. On en parle en DM 🙂',
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication'),
        actions: [
          IconButton(
            onPressed: () => showReportSheet(context, 'cette publication'),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InkWell(
                  onTap: () =>
                      pushScreen(context, ProProfileScreen(pro: p.author)),
                  child: Row(
                    children: [
                      Avatar(url: p.author.avatar, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.author.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              timeAgo(p.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VerifiedBadge(level: p.author.verifiedLevel),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(p.text, style: const TextStyle(fontSize: 15, height: 1.4)),
                for (final img in p.images) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  '❤ ${p.likes} · ${p.comments + _comments.length - 3} commentaires',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const Divider(height: 24),
                ..._comments.map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        c.$3
                            ? Avatar(url: p.author.avatar, size: 32)
                            : CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.secondary
                                    .withOpacity(0.15),
                                child: Text(
                                  c.$1.isEmpty ? 'M' : c.$1[0],
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      c.$3 ? p.author.name : c.$1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (c.$3) ...[
                                      const SizedBox(width: 4),
                                      const Pill(
                                        label: 'Auteur',
                                        color: AppColors.secondary,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(c.$2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire…',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () {
                      if (_c.text.trim().isEmpty) return;
                      setState(() {
                        _comments.add((
                          'Emmanuel Sakam',
                          _c.text.trim(),
                          false,
                        ));
                        _c.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
