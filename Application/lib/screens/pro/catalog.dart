import 'package:flutter/material.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'service_editor.dart';

class ProCatalogScreen extends StatefulWidget {
  const ProCatalogScreen({super.key});
  @override
  State<ProCatalogScreen> createState() => _ProCatalogScreenState();
}

class _ProCatalogScreenState extends State<ProCatalogScreen> {
  final List<Service> _services = [...MockData.servicesOf(MockData.pros[0])];
  // Statut : active / draft / paused (§8.2.3).
  final Map<String, String> _status = {'s3': 'draft'};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Catalogue de services')),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'new-service',
          onPressed: () => pushScreen(context, const ServiceEditorScreen()),
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle prestation'),
        ),
        body: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          itemCount: _services.length,
          onReorder: (o, n) => setState(() {
            if (n > o) n--;
            _services.insert(n, _services.removeAt(o));
          }),
          itemBuilder: (_, i) {
            final s = _services[i];
            final st = _status[s.id] ?? 'active';
            final (stLabel, stColor, stIcon) = switch (st) {
              'draft' => (
                'Brouillon',
                AppColors.textSecondary,
                Icons.edit_note,
              ),
              'paused' => ('En pause', AppColors.accent, Icons.pause),
              _ => ('Active', AppColors.success, Icons.check),
            };
            return Card(
              key: ValueKey(s.id),
              child: ListTile(
                leading: const Icon(Icons.drag_indicator),
                title: Text(
                  s.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Pill(
                          label: s.pricingType == 'quote'
                              ? 'Sur devis'
                              : s.pricingType == 'from'
                              ? 'À partir de ${formatXaf(s.priceXaf)}'
                              : formatXaf(s.priceXaf),
                          color: AppColors.primary,
                          icon: Icons.sell_outlined,
                        ),
                        Pill(label: stLabel, color: stColor, icon: stIcon),
                      ],
                    ),
                  ],
                ),
                onTap: () =>
                    pushScreen(context, ServiceEditorScreen(service: s)),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => _onMenu(v, s),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                      ),
                    ),
                    PopupMenuItem(
                      value: st == 'paused' ? 'active' : 'paused',
                      child: ListTile(
                        leading: Icon(
                          st == 'paused' ? Icons.play_arrow : Icons.pause,
                        ),
                        title: Text(
                          st == 'paused' ? 'Réactiver' : 'Mettre en pause',
                        ),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: AppColors.danger),
                        title: Text('Supprimer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onMenu(String v, Service s) async {
    switch (v) {
      case 'edit':
        pushScreen(context, ServiceEditorScreen(service: s));
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer la prestation ?'),
            content: Text(
              '« ${s.title} » ne sera plus visible. '
              'Les commandes en cours ne sont pas affectées.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        );
        if (ok == true) setState(() => _services.remove(s));
      default:
        setState(() => _status[s.id] = v);
    }
  }
}
