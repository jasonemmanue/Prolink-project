import 'package:flutter/material.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ProGroup {
  final String id;
  final String name;
  final Pro host;
  final String kind; // public, private, paid
  final int members;
  final int priceXaf;
  final String description;
  const ProGroup({
    required this.id,
    required this.name,
    required this.host,
    required this.kind,
    required this.members,
    required this.description,
    this.priceXaf = 0,
  });
}

List<ProGroup> demoGroups() => [
  ProGroup(
    id: 'g1',
    name: 'Entrepreneurs Douala — Droit des affaires',
    host: MockData.pros[0],
    kind: 'public',
    members: 412,
    description:
        'Questions juridiques du quotidien pour TPE/PME. Animé chaque mardi.',
  ),
  ProGroup(
    id: 'g2',
    name: 'Club HIIT 30 jours',
    host: MockData.pros[3],
    kind: 'paid',
    members: 86,
    priceXaf: 5000,
    description:
        'Programme collectif, séances live réservées et suivi personnalisé.',
  ),
  ProGroup(
    id: 'g3',
    name: 'Flutter Cameroun',
    host: MockData.pros[2],
    kind: 'private',
    members: 153,
    description: 'Entraide entre développeurs mobiles. Sur invitation.',
  ),
];

String groupKindLabel(String k) => switch (k) {
  'paid' => 'Payant',
  'private' => 'Privé',
  _ => 'Public',
};

/// Liste des groupes (onglet Messagerie > Groupes et Découvrir > Groupes).
class GroupList extends StatelessWidget {
  const GroupList({super.key});
  @override
  Widget build(BuildContext context) {
    final groups = demoGroups();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
      itemBuilder: (_, i) {
        final g = groups[i];
        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.secondary.withOpacity(0.12),
                child: const Icon(Icons.groups, color: AppColors.secondary),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Avatar(url: g.host.avatar, size: 22),
              ),
            ],
          ),
          title: Text(
            g.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('${g.members} membres · ${g.host.name}'),
          trailing: Pill(
            label: groupKindLabel(g.kind),
            color: g.kind == 'paid' ? AppColors.accent : AppColors.primary,
          ),
          onTap: () => pushScreen(context, GroupScreen(group: g)),
        );
      },
    );
  }
}

/// Fil d'un groupe de discussion animé par un pro (UC-IN-07).
class GroupScreen extends StatefulWidget {
  final ProGroup group;
  const GroupScreen({super.key, required this.group});
  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late bool _joined = widget.group.kind == 'public';

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final msgs = [
      (
        g.host.name,
        'Bienvenue à tous ! Épinglé : règles du groupe et planning.',
        true,
      ),
      ('Grace F.', 'Merci pour la session de mardi, très claire 🙏', false),
      ('Paul N.', 'Est-ce que le replay sera disponible ?', false),
      (g.host.name, 'Oui, dans l\'onglet Lives de mon profil.', true),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              g.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${g.members} membres · ${groupKindLabel(g.kind)}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'report') showReportSheet(context, 'ce groupe');
              if (v == 'leave') setState(() => _joined = false);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'mute',
                child: Text('Mettre en sourdine'),
              ),
              if (_joined)
                const PopupMenuItem(value: 'leave', child: Text('Quitter')),
              const PopupMenuItem(value: 'report', child: Text('Signaler')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: Row(
              children: [
                Avatar(url: g.host.avatar, size: 36),
                const SizedBox(width: 10),
                Expanded(child: Text(g.description)),
              ],
            ),
          ),
          Expanded(
            child: _joined
                ? ListView(
                    padding: const EdgeInsets.all(12),
                    children: msgs
                        .map(
                          (m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      m.$1,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: m.$3
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    if (m.$3) ...[
                                      const SizedBox(width: 4),
                                      const Pill(
                                        label: 'Animateur',
                                        color: AppColors.secondary,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: m.$3
                                        ? AppColors.primary.withOpacity(0.06)
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(m.$2),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  )
                : _JoinPanel(
                    group: g,
                    onJoin: () => setState(() => _joined = true),
                  ),
          ),
          if (_joined)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => showAttachmentSheet(context),
                      icon: const Icon(Icons.attach_file),
                    ),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Écrire au groupe…',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send, color: AppColors.primary),
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

class _JoinPanel extends StatelessWidget {
  final ProGroup group;
  final VoidCallback onJoin;
  const _JoinPanel({required this.group, required this.onJoin});
  @override
  Widget build(BuildContext context) {
    final paid = group.kind == 'paid';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              paid ? Icons.lock_outline : Icons.group_add_outlined,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              paid
                  ? 'Groupe réservé aux membres abonnés'
                  : 'Ce groupe est privé : envoyez une demande à l\'animateur',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                onJoin();
                showInfo(
                  context,
                  paid
                      ? 'Abonnement activé : ${formatXaf(group.priceXaf)}/mois'
                      : 'Demande envoyée',
                );
              },
              child: Text(
                paid
                    ? 'Rejoindre · ${formatXaf(group.priceXaf)}/mois'
                    : 'Demander à rejoindre',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Création d'un groupe par un pro (UC-PR-10) : public, privé ou payant.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  String _kind = 'public';
  bool _onlyHostPosts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau groupe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.secondary.withOpacity(0.12),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: 'Nom du groupe'),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Description'),
          ),
          const SectionLabel('Type d\'accès'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'public',
                label: Text('Public'),
                icon: Icon(Icons.public),
              ),
              ButtonSegment(
                value: 'private',
                label: Text('Privé'),
                icon: Icon(Icons.lock_outline),
              ),
              ButtonSegment(
                value: 'paid',
                label: Text('Payant'),
                icon: Icon(Icons.payments_outlined),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          if (_kind == 'paid') ...[
            const SizedBox(height: 12),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Abonnement mensuel (XAF)',
                helperText: 'Commission plateforme : 10 %',
              ),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Seul l\'animateur peut publier'),
            subtitle: const Text('Mode « canal d\'annonces »'),
            value: _onlyHostPosts,
            onChanged: (v) => setState(() => _onlyHostPosts = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showInfo(context, 'Groupe créé. Invitez vos abonnés !');
            },
            child: const Text('Créer le groupe'),
          ),
        ],
      ),
    );
  }
}

/// Pièces jointes du chat : PDF, image, vidéo, voice note (UC-IN-08).
Future<void> showAttachmentSheet(BuildContext context) {
  const items = [
    (Icons.picture_as_pdf, 'Document PDF', AppColors.danger),
    (Icons.image_outlined, 'Photo', AppColors.secondary),
    (Icons.videocam_outlined, 'Vidéo', AppColors.primary),
    (Icons.mic_none, 'Note vocale', AppColors.accent),
    (Icons.request_quote_outlined, 'Devis / facture', AppColors.success),
    (Icons.location_on_outlined, 'Position', AppColors.textSecondary),
  ];
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: items
            .map(
              (it) => InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(ctx);
                  showInfo(context, '${it.$2} : sélection du fichier…');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: it.$3.withOpacity(0.12),
                      child: Icon(it.$1, color: it.$3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      it.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}
