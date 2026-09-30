import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../shared/wallet_actions.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Portefeuille'),
            actions: [
              IconButton(
                tooltip: 'Exporter le relevé',
                onPressed: () => showInfo(
                  context,
                  'Relevé PDF des 90 derniers jours enregistré.',
                ),
                icon: const Icon(Icons.file_download_outlined),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Solde disponible',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '45 000 XAF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                pushScreen(context, const TopUpScreen()),
                            icon: const Icon(Icons.add),
                            label: const Text('Recharger'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                            ),
                            // Retrait limité aux comptes pro (§8.1.7).
                            onPressed: () => showInfo(
                              context,
                              'Le retrait est réservé aux comptes professionnels.',
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('Retirer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.lock,
                      title: 'En séquestre',
                      value: '250 000',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.confirmation_number,
                      title: 'Billets',
                      value: '3',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DefaultTabController(
                length: 4,
                child: TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Toutes'),
                    Tab(text: 'Prestations'),
                    Tab(text: 'Lives'),
                    Tab(text: 'Retraits'),
                  ],
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: _transactions.length,
            itemBuilder: (_, i) {
              final (t, detail, amount, date) = _transactions[i];
              final positive = amount > 0;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      (positive ? AppColors.success : AppColors.danger)
                          .withOpacity(0.10),
                  child: Icon(
                    positive ? Icons.south_west : Icons.north_east,
                    color: positive ? AppColors.success : AppColors.danger,
                  ),
                ),
                title: Text(t),
                subtitle: Text(
                  '$detail\n$date · Réf #P${100231 - i * 7}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                trailing: Text(
                  '${positive ? '+' : '-'} ${formatXaf(amount.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: positive ? AppColors.success : AppColors.danger,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Historique de démo : (type, détail, montant signé, date).
const _transactions = [
  ('Achat prestation', 'Consultation juridique · Me. Aïcha Nkomo', -15000, 'Aujourd\'hui'),
  ('Rechargement', 'MTN Mobile Money · +237 6•• •• 42', 20000, 'Hier'),
  ('Billet live', 'Masterclass cuisine fusion · Chef Landry', -5000, 'Hier'),
  ('Pourboire', 'Live « Tresses knotless » · Sandrine Mbida', -1000, 'il y a 2 j'),
  ('Remboursement', 'Commande PL-10362 annulée', 25000, 'il y a 4 j'),
  ('Achat prestation', 'Coaching HIIT 4 semaines · Dr. Muna', -30000, 'il y a 6 j'),
  ('Rechargement', 'Orange Money · +237 6•• •• 18', 50000, 'il y a 9 j'),
  ('Billet live', 'Créer sa SARL en 3 étapes · Me. Aïcha', -2000, 'il y a 12 j'),
  ('Achat prestation', 'Tresses knotless · Sandrine Mbida', -15000, 'il y a 15 j'),
];

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color color;
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
