import 'package:flutter/material.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Formulaire « + Nouvelle prestation » / modification (§8.2.3, UC-PR-07).
class ServiceEditorScreen extends StatefulWidget {
  final Service? service;
  const ServiceEditorScreen({super.key, this.service});
  @override
  State<ServiceEditorScreen> createState() => _ServiceEditorScreenState();
}

class _ServiceEditorScreenState extends State<ServiceEditorScreen> {
  late String _pricing = widget.service?.pricingType ?? 'fixed';
  late String _modality = widget.service?.modality ?? 'À distance';
  late String _cancel = widget.service?.cancellation ?? 'Standard';
  String _status = 'active';
  bool _variants = true;
  final _deliverables = ['Compte rendu écrit', 'Suivi 30 jours'];

  static const _pricingTypes = [
    ('fixed', 'Prix fixe'),
    ('from', 'À partir de'),
    ('hourly', 'À l\'heure'),
    ('monthly', 'Mensuel'),
    ('quote', 'Sur devis'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    return Scaffold(
      appBar: AppBar(
        title: Text(s == null ? 'Nouvelle prestation' : 'Modifier'),
        actions: [
          TextButton(
            onPressed: () => _save('Brouillon enregistré'),
            child: const Text('Brouillon'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [_photoSlot(add: true), _photoSlot(), _photoSlot()],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: s?.title,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: MockData.categories.first,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: MockData.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: s?.description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SectionLabel('Tarification'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in _pricingTypes)
                ChoiceChip(
                  label: Text(p.$2),
                  selected: _pricing == p.$1,
                  onSelected: (_) => setState(() => _pricing = p.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pricing != 'quote')
            TextFormField(
              initialValue: s == null ? null : '${s.priceXaf}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prix',
                suffixText: 'XAF',
                helperText: 'Commission ProLink : 10 %',
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Proposer 3 formules'),
            subtitle: const Text('Basic · Standard · Premium'),
            value: _variants,
            onChanged: (v) => setState(() => _variants = v),
          ),
          if (_variants)
            Row(
              children: [
                for (final v in ['Basic', 'Standard', 'Premium'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: v,
                          isDense: true,
                          suffixText: 'XAF',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SectionLabel('Livrables'),
          ..._deliverables.map(
            (d) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: Text(d),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _deliverables.remove(d)),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () =>
                setState(() => _deliverables.add('Livrable supplémentaire')),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un livrable'),
          ),
          const SectionLabel('Conditions'),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _modality,
                  decoration: const InputDecoration(labelText: 'Modalité'),
                  items: const ['À distance', 'Sur site', 'Mixte']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _modality = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _cancel,
                  decoration: const InputDecoration(labelText: 'Annulation'),
                  items: const ['Flexible', 'Standard', 'Stricte']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _cancel = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: s?.duration,
            decoration: const InputDecoration(
              labelText: 'Durée / délai',
              hintText: 'ex. 2 semaines',
            ),
          ),
          const SectionLabel('Statut'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'active', label: Text('Active')),
              ButtonSegment(value: 'draft', label: Text('Brouillon')),
              ButtonSegment(value: 'paused', label: Text('En pause')),
            ],
            selected: {_status},
            onSelectionChanged: (v) => setState(() => _status = v.first),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _save(
              s == null ? 'Prestation publiée' : 'Modifications enregistrées',
            ),
            child: Text(s == null ? 'Publier la prestation' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _save(String msg) {
    Navigator.pop(context);
    showInfo(context, msg);
  }

  Widget _photoSlot({bool add = false}) => Container(
    width: 96,
    margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider),
    ),
    child: Icon(
      add ? Icons.add_a_photo_outlined : Icons.image_outlined,
      color: add ? AppColors.primary : AppColors.textSecondary,
    ),
  );
}
