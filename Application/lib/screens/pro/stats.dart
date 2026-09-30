import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ProStatsScreen extends StatelessWidget {
  const ProStatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            tooltip: 'Exporter en CSV (Premium)',
            onPressed: () => showInfo(context, 'Export CSV envoyé par e-mail.'),
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Metric('Audience 30j', '18 420', '+14%', Icons.people),
          _Metric('Engagement', '4.8%', '+0.6%', Icons.thumb_up),
          _Metric('Revenus 30j', '1 250 000 XAF', '+22%', Icons.payments),
          _Metric('Taux de réponse', '96%', '=', Icons.reply),
          SizedBox(height: 24),
          Text(
            'Sources de trafic',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _Bar(label: 'Fil d\'actualité', pct: 62),
          _Bar(label: 'Recherche', pct: 21),
          _Bar(label: 'Profil direct', pct: 10),
          _Bar(label: 'Lives', pct: 7),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title, value, trend;
  final IconData icon;
  const _Metric(this.title, this.value, this.trend, this.icon);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        trailing: Pill(
          label: trend,
          color: AppColors.success,
          icon: Icons.trending_up,
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double pct;
  const _Bar({required this.label, required this.pct});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                '${pct.toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
