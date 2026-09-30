import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../l10n.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../auth.dart';
import '../pro/kyc.dart';
import 'my_orders.dart';
import 'settings.dart';
import 'tickets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocale>();
    final session = context.watch<Session>();
    final myOrders = MockData.orders()
        .where((o) => !session.online || o.pro.id != session.userId)
        .length;
    final tickets = session.online
        ? session.transactions.where((t) => t['kind'] == 'ticket').length
        : 3;
    return SafeArea(
      child: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Avatar(url: session.avatar, size: 84),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              session.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Center(
            child: Text(
              [
                session.isPro ? 'Professionnel' : 'Client',
                if (session.city.isNotEmpty) session.city,
                if (!session.online) 'mode démo',
              ].join(' · '),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: _Stat(value: '$myOrders', label: 'Commandes')),
              Expanded(
                child: _Stat(
                  value: session.balanceXaf >= 1000000
                      ? '${(session.balanceXaf / 1000000).toStringAsFixed(1).replaceAll('.', ',')} M'
                      : session.balanceXaf >= 1000
                      ? '${session.balanceXaf ~/ 1000} k'
                      : '${session.balanceXaf}',
                  label: 'Solde XAF',
                ),
              ),
              Expanded(
                child: _Stat(
                  value: '${MockData.notifications().where((n) => !n.read).length}',
                  label: 'Non lues',
                ),
              ),
              Expanded(child: _Stat(value: '$tickets', label: 'Billets')),
            ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => pushScreen(context, const EditProfileScreen()),
              icon: const Icon(Icons.edit),
              label: const Text('Modifier le profil'),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Compte',
            tiles: [
              _Tile(
                Icons.badge_outlined,
                'Devenir professionnel',
                subtitle: 'Ouvrir mon compte pro et publier mes services',
                screen: const KycScreen(),
              ),
              _Tile(
                Icons.shopping_bag_outlined,
                'Mes commandes',
                subtitle: '1 livraison à valider',
                screen: const MyOrdersScreen(),
              ),
              _Tile(
                Icons.confirmation_number_outlined,
                'Billets lives & replays',
                screen: const MyTicketsScreen(),
              ),
            ],
          ),
          _Section(
            title: 'Préférences',
            tiles: [
              _SwitchTile(
                Icons.dark_mode_outlined,
                'Thème sombre',
                value: false,
              ),
              _LangTile(loc: loc),
              _Tile(
                Icons.notifications_outlined,
                'Notifications',
                subtitle: 'Cloche par pro, plage horaire, catégories',
                screen: const NotificationSettingsScreen(),
              ),
            ],
          ),
          _Section(
            title: 'Sécurité',
            tiles: [
              _Tile(
                Icons.verified_user_outlined,
                'Sécurité & confidentialité',
                subtitle: '2FA, biométrie, sessions actives',
                screen: const SecurityScreen(),
              ),
            ],
          ),
          _Section(
            title: 'Aide & Légal',
            tiles: [
              _Tile(
                Icons.help_outline,
                'Aide & support',
                subtitle: 'FAQ, contact, CGU, confidentialité',
                screen: const HelpCenterScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              onPressed: () async {
                await Session.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'ProLink v1.0.0 · MVP',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  const _Section({required this.title, required this.tiles});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Card(child: Column(children: tiles)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? screen;
  const _Tile(this.icon, this.title, {this.subtitle, this.screen});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: screen == null ? null : () => pushScreen(context, screen!),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool value;
  const _SwitchTile(this.icon, this.title, {required this.value});
  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  late bool _v = widget.value;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _v,
      onChanged: (v) => setState(() => _v = v),
      title: Text(widget.title),
      secondary: Icon(widget.icon, color: AppColors.primary),
    );
  }
}

class _LangTile extends StatelessWidget {
  final AppLocale loc;
  const _LangTile({required this.loc});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.translate, color: AppColors.primary),
      title: const Text('Langue de l\'interface'),
      subtitle: Text(loc.isFr ? 'Français' : 'English'),
      trailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'fr', label: Text('FR')),
          ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {loc.locale.languageCode},
        onSelectionChanged: (s) {
          if (s.first != loc.locale.languageCode) loc.toggle();
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}
