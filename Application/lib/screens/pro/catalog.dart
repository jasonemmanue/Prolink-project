import 'package:flutter/material.dart';
import '../../data.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ProCatalogScreen extends StatelessWidget {
  const ProCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = MockData.servicesOf(MockData.pros[0]);
    return SafeArea(
      child: Column(children: [
        AppBar(
          title: const Text('Catalogue de services'),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          ],
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: services.length,
            onReorder: (o, n) {},
            itemBuilder: (_, i) {
              final s = services[i];
              return Card(
                key: ValueKey(s.id),
                child: ListTile(
                  leading: const Icon(Icons.drag_indicator),
                  title: Text(s.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.description,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        Pill(
                            label: s.pricingType == 'quote'
                                ? 'Sur devis'
                                : s.pricingType == 'from'
                                    ? 'À partir de ${formatXaf(s.priceXaf)}'
                                    : formatXaf(s.priceXaf),
                            color: AppColors.primary,
                            icon: Icons.attach_money),
                        const SizedBox(width: 6),
                        Pill(
                            label: 'Actif',
                            color: AppColors.success,
                            icon: Icons.check),
                      ]),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Modifier'))),
                      PopupMenuItem(
                          value: 'pause',
                          child: ListTile(
                              leading: Icon(Icons.pause),
                              title: Text('Mettre en pause'))),
                      PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                              leading:
                                  Icon(Icons.delete, color: AppColors.danger),
                              title: Text('Supprimer'))),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ]),
    );
  }
}
