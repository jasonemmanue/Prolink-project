import 'package:flutter/material.dart';
import '../../api/mappers.dart';
import '../../api/session.dart';
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
  final String? myStatus; // member | requested | null
  const ProGroup({
    required this.id,
    required this.name,
    required this.host,
    required this.kind,
    required this.members,
    required this.description,
    this.priceXaf = 0,
    this.myStatus,
  });

  factory ProGroup.fromJson(Map<String, dynamic> j) => ProGroup(
    id: j['id'],
    name: j['title'] ?? '',
    host: Mappers.user(j['host']),
    kind: j['access'] ?? 'public',
    members: j['members_count'] ?? 0,
    priceXaf: j['price_xaf'] ?? 0,
    description: j['description'] ?? '',
    myStatus: j['my_status'],
  );
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
class GroupList extends StatefulWidget {
  const GroupList({super.key});
  @override
  State<GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  List<ProGroup> _groups = demoGroups();

  @override
  void initState() {
    super.initState();
    if (Session.instance.online) _load();
  }

  Future<void> _load() async {
    try {
      final list = await Session.instance.api.get('/chat/groups') as List;
      if (!mounted) return;
      setState(() => _groups = [for (final j in list) ProGroup.fromJson(j)]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups.isEmpty) {
      return Center(
        child: Text('Aucun groupe pour le moment',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        if (Session.instance.online) await _load();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
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
              label: g.myStatus == 'member' ? 'Membre' : groupKindLabel(g.kind),
              color: g.myStatus == 'member'
                  ? AppColors.success
                  : g.kind == 'paid'
                  ? AppColors.accent
                  : AppColors.primary,
            ),
            onTap: () async {
              await pushScreen(context, GroupScreen(group: g));
              if (Session.instance.online) _load();
            },
          );
        },
      ),
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
  late bool _joined = Session.instance.online
      ? widget.group.myStatus == 'member'
      : widget.group.kind == 'public';
  late bool _requested = widget.group.myStatus == 'requested';
  final _c = TextEditingController();
  List<(String, String, bool)>? _remote;

  @override
  void initState() {
    super.initState();
    if (Session.instance.online && _joined) _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final list = await Session.instance.api.get(
          '/chat/conversations/${widget.group.id}/messages',
          query: {'limit': 100}) as List;
      if (!mounted) return;
      final host = widget.group.host;
      final me = Session.instance.userId;
      setState(() => _remote = [
            for (final m in list)
              (
                m['author_id'] == host.id
                    ? host.name
                    : m['author_id'] == me
                    ? 'Vous'
                    : 'Membre',
                m['text'] as String,
                m['author_id'] == host.id,
              ),
          ]);
    } catch (_) {}
  }

  Future<void> _join() async {
    final g = widget.group;
    final r = await apiCall<Map>(
      context,
      (api) async => await api.post('/chat/groups/${g.id}/join') as Map,
      demo: const {'my_status': 'member'},
    );
    if (r == null || !mounted) return;
    final status = r['my_status'];
    setState(() {
      _joined = status == 'member';
      _requested = status == 'requested';
    });
    showInfo(
      context,
      _requested
          ? 'Demande envoyée à l\'animateur'
          : g.kind == 'paid'
          ? 'Abonnement activé : ${formatXaf(g.priceXaf)}/mois'
          : 'Bienvenue dans le groupe !',
    );
    if (_joined && Session.instance.online) {
      _loadMessages();
      Session.instance.afterMoneyAction();
    }
  }

  Future<void> _send() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/chat/conversations/${widget.group.id}/messages', {'text': text});
      return true;
    }, demo: true);
    if (ok != true || !mounted) return;
    _c.clear();
    if (Session.instance.online) {
      _loadMessages();
    } else {
      setState(() => (_remote ??= []).add(('Vous', text, false)));
    }
  }

  Future<void> _leave() async {
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/chat/groups/${widget.group.id}/leave');
      return true;
    }, demo: true);
    if (ok == true && mounted) setState(() => _joined = false);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final msgs = _remote ??
        [
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
              if (v == 'report') {
                showReportSheet(context, 'ce groupe', type: 'group', id: g.id);
              }
              if (v == 'leave') _leave();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'mute', child: Text('Mettre en sourdine')),
              if (_joined) const PopupMenuItem(value: 'leave', child: Text('Quitter')),
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
                    children: [
                      for (final m in msgs)
                        Padding(
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
                    ],
                  )
                : _JoinPanel(group: g, requested: _requested, onJoin: _join),
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
                    Expanded(
                      child: TextField(
                        controller: _c,
                        decoration: const InputDecoration(
                          hintText: 'Écrire au groupe…',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _send,
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
  final bool requested;
  final VoidCallback onJoin;
  const _JoinPanel({required this.group, required this.onJoin, this.requested = false});
  @override
  Widget build(BuildContext context) {
    final paid = group.kind == 'paid';
    final private = group.kind == 'private';
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
              requested
                  ? 'Demande envoyée : en attente de validation par l\'animateur'
                  : paid
                  ? 'Groupe réservé aux membres abonnés'
                  : private
                  ? 'Ce groupe est privé : envoyez une demande à l\'animateur'
                  : 'Rejoignez le groupe pour lire et écrire',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (!requested)
              ElevatedButton(
                onPressed: onJoin,
                child: Text(
                  paid
                      ? 'Rejoindre · ${formatXaf(group.priceXaf)}/mois'
                      : private
                      ? 'Demander à rejoindre'
                      : 'Rejoindre',
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
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();

  Future<void> _create() async {
    if (_title.text.trim().length < 3) {
      showInfo(context, 'Donnez un nom au groupe (3 caractères minimum)');
      return;
    }
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/chat/groups', {
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'access': _kind,
        'price_xaf': int.tryParse(_price.text.replaceAll(' ', '')) ?? 0,
        'only_host_posts': _onlyHostPosts,
      });
      return true;
    }, demo: true);
    if (ok != true || !mounted) return;
    Navigator.pop(context);
    showInfo(context, 'Groupe créé. Invitez vos abonnés !');
  }

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
              child: const Icon(Icons.add_a_photo_outlined, color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Nom du groupe'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SectionLabel('Type d\'accès'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'public', label: Text('Public'), icon: Icon(Icons.public)),
              ButtonSegment(value: 'private', label: Text('Privé'), icon: Icon(Icons.lock_outline)),
              ButtonSegment(value: 'paid', label: Text('Payant'), icon: Icon(Icons.payments_outlined)),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          if (_kind == 'paid') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
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
          ElevatedButton(onPressed: _create, child: const Text('Créer le groupe')),
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
