import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'sponsor.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});
  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  String _type = 'text';
  String _audience = 'public';
  int _media = 0;
  DateTime? _scheduledAt;
  bool _sponsor = false;
  final _types = const [
    ('text', 'Texte', Icons.article),
    ('photo', 'Photo', Icons.photo_camera),
    ('video', 'Vidéo', Icons.videocam),
    ('article', 'Article', Icons.notes),
    ('portfolio', 'Réalisation', Icons.workspaces),
    ('poll', 'Sondage', Icons.poll),
    ('event', 'Événement', Icons.event),
    ('live', 'Annoncer live', Icons.podcasts),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle publication'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Brouillon'),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Publier'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Type de publication',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types
                .map(
                  (t) => ChoiceChip(
                    avatar: Icon(
                      t.$3,
                      size: 16,
                      color: _type == t.$1 ? Colors.white : AppColors.primary,
                    ),
                    label: Text(t.$2),
                    selected: _type == t.$1,
                    onSelected: (_) => setState(() => _type = t.$1),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _type == t.$1 ? Colors.white : null,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: 'Titre (facultatif)'),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Contenu de la publication',
              hintText:
                  'Astuce, actualité, opinion pro… (jusqu\'à 3 000 caractères)',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _media >= 10
                      ? null
                      : () => setState(() => _media++),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _media == 0
                        ? 'Ajouter des médias (10 max)'
                        : '$_media/10 médias',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Mentionner / hashtag',
                onPressed: () => showInfo(
                  context,
                  'Tapez @ pour mentionner, # pour un hashtag',
                ),
                icon: const Icon(Icons.tag),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const Text('Audience', style: TextStyle(fontWeight: FontWeight.w700)),
          RadioListTile(
            value: 'public',
            groupValue: _audience,
            onChanged: (v) => setState(() => _audience = v!),
            title: const Text('Public — visible par tous'),
          ),
          RadioListTile(
            value: 'followers',
            groupValue: _audience,
            onChanged: (v) => setState(() => _audience = v!),
            title: const Text('Abonnés uniquement'),
          ),
          const Divider(),
          SwitchListTile(
            value: _scheduledAt != null,
            onChanged: (v) async {
              if (!v) return setState(() => _scheduledAt = null);
              final now = DateTime.now();
              final d = await showDatePicker(
                context: context,
                firstDate: now,
                lastDate: now.add(const Duration(days: 60)),
                initialDate: now.add(const Duration(days: 1)),
              );
              if (d != null) setState(() => _scheduledAt = d);
            },
            title: const Text('Programmer la publication'),
            subtitle: Text(
              _scheduledAt == null
                  ? 'Choisir une date et heure futures'
                  : 'Publication le ${formatDate(_scheduledAt!)} à 9 h',
            ),
          ),
          SwitchListTile(
            value: _sponsor,
            onChanged: (v) {
              setState(() => _sponsor = v);
              if (v) pushScreen(context, const SponsorScreen());
            },
            title: const Text('Sponsoriser cette publication'),
            subtitle: const Text('À partir de 2 000 XAF/jour'),
          ),
        ],
      ),
    );
  }
}
