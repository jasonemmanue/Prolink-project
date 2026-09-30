import 'package:flutter/material.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'stats.dart';
import 'publish.dart';
import 'live_broadcast.dart';
import 'service_editor.dart';
import 'order_detail.dart';
import 'reviews.dart';
import 'sponsor.dart';
import 'kyc.dart';
import '../shared/notifications.dart';
import '../client/messaging.dart';
import '../client/groups.dart';

class ProDashboardScreen extends StatelessWidget {
  const ProDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              const AppLogo(size: 34),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    pushScreen(context, const NotificationsScreen()),
                icon: const Badge(
                  label: Text('4'),
                  child: Icon(Icons.notifications_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bonjour, Me. Aïcha',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            'Voici vos indicateurs du jour',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: const [
              _Kpi(
                icon: Icons.remove_red_eye,
                title: 'Vues profil',
                value: '1 284',
                trend: '+18%',
                color: AppColors.primary,
              ),
              _Kpi(
                icon: Icons.person_add,
                title: 'Nouveaux abonnés',
                value: '46',
                trend: '+9%',
                color: AppColors.secondary,
              ),
              _Kpi(
                icon: Icons.payments,
                title: 'Revenus (7j)',
                value: '325 000 XAF',
                trend: '+22%',
                color: AppColors.success,
              ),
              _Kpi(
                icon: Icons.receipt_long,
                title: 'Commandes',
                value: '12 · 4 en cours',
                trend: '',
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'Engagement 7 jours',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProStatsScreen(),
                          ),
                        ),
                        child: const Text('Détails'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 120, child: _MiniChart()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Raccourcis',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  icon: Icons.edit_note,
                  label: 'Nouvelle publication',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PublishScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Shortcut(
                  icon: Icons.podcasts,
                  label: 'Nouveau live',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProLiveBroadcastScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  icon: Icons.add_business_outlined,
                  label: 'Nouveau service',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServiceEditorScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Shortcut(
                  icon: Icons.chat_bubble_outline,
                  label: 'Répondre aux clients',
                  onTap: () => pushScreen(
                    context,
                    const Scaffold(body: MessagingScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  icon: Icons.star_outline,
                  label: 'Avis clients',
                  onTap: () => pushScreen(context, const ProReviewsScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Shortcut(
                  icon: Icons.campaign_outlined,
                  label: 'Sponsoriser',
                  onTap: () => pushScreen(context, const SponsorScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Shortcut(
                  icon: Icons.groups_outlined,
                  label: 'Créer un groupe',
                  onTap: () => pushScreen(context, const CreateGroupScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Alertes', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _Alert(
            icon: Icons.request_quote_outlined,
            color: AppColors.accent,
            text: '2 demandes de devis en attente depuis plus de 24 h.',
            onTap: () => pushScreen(
              context,
              const QuoteReplyScreen(
                clientName: 'Brice Ewane',
                request:
                    'Contentieux avec un fournisseur : mise en demeure + audience.',
              ),
            ),
          ),
          _Alert(
            icon: Icons.gavel,
            color: AppColors.danger,
            text: '1 litige ouvert — réponse attendue sous 48 h.',
            onTap: () => pushScreen(
              context,
              ProOrderDetailScreen(
                order: MockData.orders().firstWhere(
                  (o) => o.status == OrderStatus.disputed,
                ),
              ),
            ),
          ),
          _Alert(
            icon: Icons.verified_outlined,
            color: AppColors.primary,
            text: 'Niveau Premium : 1 document en revue, 2 à fournir.',
            onTap: () => pushScreen(context, const KycScreen()),
          ),
          _Alert(
            icon: Icons.workspace_premium_outlined,
            color: AppColors.secondary,
            text: 'Compte pro gratuit : encore 4 mois. Découvrir les packs.',
            onTap: () => pushScreen(context, const PlansScreen()),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final IconData icon;
  final String title, value, trend;
  final Color color;
  const _Kpi({
    required this.icon,
    required this.title,
    required this.value,
    required this.trend,
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
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            if (trend.isNotEmpty)
              Text(
                trend,
                style: const TextStyle(fontSize: 12, color: AppColors.success),
              ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart();
  @override
  Widget build(BuildContext context) {
    final values = [40.0, 55.0, 38.0, 72.0, 65.0, 92.0, 80.0];
    return LayoutBuilder(
      builder: (context, box) {
        final maxV = values.reduce((a, b) => a > b ? a : b);
        final barW = (box.maxWidth - 12) / values.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (i) {
            final h = (values[i] / maxV) * box.maxHeight * 0.85;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: barW - 8,
                    height: h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ['L', 'M', 'M', 'J', 'V', 'S', 'D'][i],
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _Alert extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;
  const _Alert({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
