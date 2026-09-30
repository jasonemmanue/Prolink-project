import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../shared/wallet_actions.dart';

class ProFinancesScreen extends StatelessWidget {
  const ProFinancesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Finances',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Card(
                  title: 'Solde disponible',
                  value: formatXaf(325000),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Card(
                  title: 'En séquestre',
                  value: formatXaf(180000),
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
                  title: 'Retiré (30j)',
                  value: formatXaf(950000),
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Card(
                  title: 'Commission plateforme',
                  value: '-${formatXaf(78000)}',
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
                const WithdrawScreen(availableXaf: 325000),
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
          Card(
            child: Column(
              children: List.generate(8, (i) {
                final ok = i % 3 != 0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (ok ? AppColors.success : AppColors.accent)
                        .withOpacity(0.10),
                    child: Icon(
                      ok ? Icons.check : Icons.access_time,
                      color: ok ? AppColors.success : AppColors.accent,
                    ),
                  ),
                  title: Text(
                    ok
                        ? 'Prestation payée par client${i + 1}'
                        : 'En séquestre — livraison en cours',
                  ),
                  subtitle: Text('#PL${20450 + i} · il y a ${i + 1}j'),
                  trailing: Text(
                    '${ok ? '+' : ''}${formatXaf(15000 + i * 4000)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ok ? AppColors.success : AppColors.accent,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
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
