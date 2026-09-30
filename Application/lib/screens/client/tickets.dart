import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../live_view.dart';

/// Achat d'un billet pour un live payant (UC-IN-16, annexe C.2).
Future<void> showTicketSheet(BuildContext context, LiveEvent live) {
  String method = 'wallet';
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 7,
                  child: CachedNetworkImage(
                    imageUrl: live.cover,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                live.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${live.pro} · ${formatDate(live.startAt)} à '
                '${live.startAt.hour.toString().padLeft(2, '0')}h'
                '${live.startAt.minute.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Billet unique'),
                  const Spacer(),
                  Text(
                    formatXaf(live.priceXaf),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Text(
                'Inclut l\'accès au replay pendant 30 jours.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SectionLabel('Payer avec'),
              for (final m in [
                (
                  'wallet',
                  'Portefeuille ProLink · ${formatXaf(Session.instance.balanceXaf)}',
                  Icons.account_balance_wallet,
                ),
                ('mtn', 'MTN Mobile Money', Icons.phone_android),
                ('orange', 'Orange Money', Icons.phone_iphone),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(m.$3, color: AppColors.primary),
                  title: Text(m.$2),
                  trailing: Icon(
                    method == m.$1
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: AppColors.primary,
                  ),
                  onTap: () => setState(() => method = m.$1),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: Text('Acheter · ${formatXaf(live.priceXaf)}'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final s = Session.instance;
                    if (s.online && method != 'wallet') {
                      // Mobile Money : on crédite d'abord le portefeuille.
                      final top = await apiCall<bool>(context, (api) async {
                        await api.post('/wallet/topup',
                            {'amount_xaf': live.priceXaf, 'method': method});
                        return true;
                      });
                      if (top != true) return;
                    }
                    if (!context.mounted) return;
                    final ok = await apiCall<bool>(context, (api) async {
                      await api.post('/lives/${live.id}/ticket');
                      return true;
                    }, demo: true);
                    if (ok != true || !context.mounted) return;
                    showInfo(
                      context,
                      'Billet confirmé ! Vous serez notifié 15 min avant le live.',
                    );
                    await s.afterMoneyAction();
                    if (s.online) await s.refreshLives();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Mes billets lives & replays (UC-IN-16 / UC-IN-19).
class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final lives = MockData.lives();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Billets & replays'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'À venir'),
              Tab(text: 'Replays'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(12),
              children: lives
                  .where((l) => l.paying)
                  .map((l) => _TicketCard(live: l))
                  .toList(),
            ),
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _ReplayTile(live: lives[0], owned: true, duration: '58 min'),
                _ReplayTile(
                  live: lives[2],
                  owned: false,
                  duration: '24 min',
                  price: 1000,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final LiveEvent live;
  const _TicketCard({required this.live});
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: live.cover,
            width: 96,
            height: 110,
            fit: BoxFit.cover,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    live.title,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    live.pro,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      live.isLive
                          ? const Pill(
                              label: 'EN DIRECT',
                              color: AppColors.danger,
                              icon: Icons.circle,
                            )
                          : Pill(
                              label: formatDate(live.startAt),
                              icon: Icons.event,
                            ),
                      const Spacer(),
                      if (live.isLive)
                        FilledButton(
                          onPressed: () =>
                              pushScreen(context, LiveViewScreen(live: live)),
                          child: const Text('Rejoindre'),
                        )
                      else
                        const Icon(Icons.qr_code_2, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayTile extends StatelessWidget {
  final LiveEvent live;
  final bool owned;
  final String duration;
  final int price;
  const _ReplayTile({
    required this.live,
    required this.owned,
    required this.duration,
    this.price = 0,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: live.cover,
                width: 64,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white),
          ],
        ),
        title: Text(
          live.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${live.pro} · $duration'),
        trailing: owned
            ? const Pill(label: 'Acquis', color: AppColors.success)
            : OutlinedButton(
                onPressed: () => showInfo(
                  context,
                  'Replay acheté : ${formatXaf(price)} débités.',
                ),
                child: Text(formatXaf(price)),
              ),
      ),
    );
  }
}
