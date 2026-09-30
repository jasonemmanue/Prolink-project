import 'package:flutter/material.dart';
import '../../api/session.dart';
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
  late String _status = widget.service?.status ?? 'active';
  late bool _variants = widget.service == null || widget.service!.variants.isNotEmpty;
  late final List<String> _deliverables = widget.service?.deliverables.isNotEmpty == true
      ? List.of(widget.service!.deliverables)
      : ['Compte rendu écrit', 'Suivi 30 jours'];
  late String _category = MockData.categories.first;
  bool _busy = false;

  late final _title = TextEditingController(text: widget.service?.title);
  late final _desc = TextEditingController(text: widget.service?.description);
  late final _price = TextEditingController(
      text: widget.service == null ? '' : '${widget.service!.priceXaf}');
  late final _duration = TextEditingController(text: widget.service?.duration);
  late final List<TextEditingController> _variantPrices = [
    for (final name in const ['Basic', 'Standard', 'Premium'])
      TextEditingController(
        text: widget.service?.variants
            .where((v) => v.name == name)
            .map((v) => '${v.priceXaf}')
            .firstOrNull,
      ),
  ];

  int _int(TextEditingController c) => int.tryParse(c.text.replaceAll(' ', '')) ?? 0;

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
            onPressed: _busy ? null : () => _save('Brouillon enregistré', status: 'draft'),
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
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: MockData.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => _category = v ?? _category,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
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
            TextField(
              controller: _price,
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
                for (final (i, v) in const ['Basic', 'Standard', 'Premium'].indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TextField(
                        controller: _variantPrices[i],
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
            onPressed: _addDeliverable,
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
          TextField(
            controller: _duration,
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
            onPressed: _busy
                ? null
                : () => _save(
                      s == null ? 'Prestation publiée' : 'Modifications enregistrées',
                    ),
            child: Text(s == null ? 'Publier la prestation' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addDeliverable() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau livrable'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Ajouter')),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) setState(() => _deliverables.add(text));
  }

  Future<void> _save(String msg, {String? status}) async {
    if (_title.text.trim().length < 3) {
      showInfo(context, 'Le titre doit faire au moins 3 caractères');
      return;
    }
    final base = _int(_price);
    final body = {
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'category': _category,
      'price_xaf': _pricing == 'quote' ? 0 : base,
      'pricing_type': _pricing,
      'variants': !_variants || _pricing == 'quote'
          ? <Map<String, dynamic>>[]
          : [
              for (final (i, name) in const ['Basic', 'Standard', 'Premium'].indexed)
                {'name': name, 'price_xaf': _int(_variantPrices[i]) == 0 ? base * (i + 1) : _int(_variantPrices[i])},
            ],
      'deliverables': _deliverables,
      'duration': _duration.text.trim(),
      'modality': _modality,
      'cancellation': _cancel,
      'status': status ?? _status,
    };
    setState(() => _busy = true);
    final ok = await apiCall<bool>(context, (api) async {
      widget.service == null || widget.service!.proId.isEmpty
          ? await api.post('/services', body)
          : await api.patch('/services/${widget.service!.id}', body);
      await Session.instance.refreshMyServices();
      return true;
    }, demo: true);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok != true) return;
    Navigator.pop(context, true);
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
