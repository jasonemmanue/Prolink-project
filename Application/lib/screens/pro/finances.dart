import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../client/wallet.dart' show txLabel;
import '../shared/wallet_actions.dart';

class ProFinancesScreen extends StatelessWidget {
  const ProFinancesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final online = session.online;
    int sumOf(String kind) => session.transactions
        .where((t) => t['kind'] == kind)
        .fold(0, (a, t) => a + (t['amount_xaf'] as int));
    final balance = online ? session.balanceXaf : 325000;
    final escrow = online ? session.escrowXaf : 180000;
    final withdrawn = online ? -sumOf('withdraw') : 950000;
    final commissions = online ? -sumOf('commission') : 78000;
    // (titre, sous-titre, montant signé, en attente)
    final history = online
        ? [
            for (final t in session.transactions)
              (
                txLabel(t['kind'] as String),
                '${t['label']}\n${t['reference']} · ${timeAgo(DateTime.parse(t['created_at']).toLocal())}',
                t['amount_xaf'] as int,
                t['status'] == 'pending',
              ),
          ]
        : [
            for (var i = 0; i < 8; i++)
              (
                i % 3 != 0
                    ? 'Payé par ${MockData.clients[i % MockData.clients.length]}'
                    : 'En séquestre — livraison en cours',
                '${MockData.servicesOf(MockData.pros[0])[i % 5].title}\n'
                    '#PL-${10420 - i * 3} · il y a ${i + 1} j',
                15000 + i * 4000,
                i % 3 == 0,
              ),
          ];
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (online) await session.refreshWallet();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Finances',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Relevé CSV',
                  onPressed: () => showInfo(
                    context,
                    online
                        ? 'Relevé disponible : ${session.api.baseUrl}/api/v1/wallet/statement.csv'
                        : 'Relevé CSV enregistré',
                  ),
                  icon: const Icon(Icons.file_download_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Card(
                    title: 'Solde disponible',
                    value: formatXaf(balance),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Card(
                    title: 'En séquestre (à recevoir)',
                    value: formatXaf(escrow),
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Card(
                    title: online ? 'Retiré' : 'Retiré (30j)',
                    value: formatXaf(withdrawn),
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Card(
                    title: 'Commission plateforme',
                    value: '-${formatXaf(commissions)}',
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => pushScreen(
                  context,
                  WithdrawScreen(availableXaf: balance),
                ),
                icon: const Icon(Icons.download),
                label: const Text('Retirer vers Mobile Money'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Historique',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucun mouvement pour le moment')),
              ),
            if (history.isNotEmpty)
              Card(
                child: Column(
                  children: [
                    for (final h in history)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (h.$4
                                  ? AppColors.accent
                                  : h.$3 >= 0
                                  ? AppColors.success
                                  : AppColors.danger)
                              .withOpacity(0.10),
                          child: Icon(
                            h.$4
                                ? Icons.access_time
                                : h.$3 >= 0
                                ? Icons.south_west
                                : Icons.north_east,
                            color: h.$4
                                ? AppColors.accent
                                : h.$3 >= 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                        title: Text(h.$1),
                        subtitle: Text(h.$2),
                        isThreeLine: true,
                        trailing: Text(
                          '${h.$3 >= 0 ? '+' : '-'}${formatXaf(h.$3.abs())}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: h.$4
                                ? AppColors.accent
                                : h.$3 >= 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title, value;
  final Color color;
  const _Card({required this.title, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
