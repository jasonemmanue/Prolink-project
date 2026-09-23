import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ProOrdersScreen extends StatelessWidget {
  const ProOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Column(children: [
          AppBar(
            title: const Text('Commandes & devis'),
            bottom: const TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'En attente (2)'),
                Tab(text: 'En cours (4)'),
                Tab(text: 'Livrées'),
                Tab(text: 'Litiges'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              _list(context, 'En attente', AppColors.accent),
              _list(context, 'En cours', AppColors.secondary),
              _list(context, 'Livrées', AppColors.success),
              _list(context, 'Litiges', AppColors.danger),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _list(BuildContext context, String status, Color color) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, i) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(Icons.receipt_long, color: color)),
          title: Text('Consultation juridique · 30 min',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Client : Emmanuel Sakam · Douala'),
              const SizedBox(height: 4),
              Row(children: [
                Pill(label: status, color: color, icon: Icons.circle),
                const SizedBox(width: 6),
                const Pill(
                    icon: Icons.calendar_today,
                    label: 'Deadline : 24 sept.'),
              ]),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatXaf(15000 + i * 5000),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}
