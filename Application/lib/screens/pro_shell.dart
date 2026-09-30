import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/session.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import 'pro/dashboard.dart';
import 'pro/publish.dart';
import 'pro/catalog.dart';
import 'pro/orders.dart';
import 'pro/live_broadcast.dart';
import 'pro/finances.dart';

class ProShell extends StatefulWidget {
  const ProShell({super.key});
  @override
  State<ProShell> createState() => _ProShellState();
}

class _ProShellState extends State<ProShell> {
  int _idx = 0;
  final _pages = const [
    ProDashboardScreen(),
    ProOrdersScreen(),
    ProCatalogScreen(),
    ProLiveBroadcastScreen(),
    ProFinancesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final meId = session.online ? session.userId : MockData.pros[0].id;
    final todo = MockData.orders()
        .where((o) => o.pro.id == meId && o.status == OrderStatus.pending)
        .length;
    return Scaffold(
      body: _pages[_idx],
      floatingActionButton: _idx == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PublishScreen())),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Publier'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        indicatorColor: AppColors.primary.withOpacity(0.10),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Tableau'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: todo > 0,
                  label: Text('$todo'),
                  child: const Icon(Icons.receipt_long_outlined)),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'Commandes'),
          const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Catalogue'),
          const NavigationDestination(
              icon: Icon(Icons.podcasts_outlined),
              selectedIcon: Icon(Icons.podcasts),
              label: 'Live'),
          const NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Finances'),
        ],
      ),
    );
  }
}
