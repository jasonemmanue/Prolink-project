import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocale>();
    return SafeArea(
      child: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
              child: Avatar(
                  url:
                      'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=400',
                  size: 84)),
          const SizedBox(height: 8),
          const Center(
              child: Text('Emmanuel Sakam',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800))),
          Center(
              child: Text('Client · Douala',
                  style: TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                label: const Text('Modifier le profil')),
          ),
          const SizedBox(height: 16),
          _Section(title: 'Compte', tiles: [
            _Tile(Icons.badge_outlined, 'Devenir professionnel',
                subtitle: 'Ouvrir mon compte pro et publier mes services'),
            _Tile(Icons.shopping_bag_outlined, 'Mes commandes'),
            _Tile(Icons.confirmation_number_outlined, 'Mes billets lives'),
          ]),
          _Section(title: 'Préférences', tiles: [
            _SwitchTile(Icons.dark_mode_outlined, 'Thème sombre',
                value: false),
            _LangTile(loc: loc),
            _Tile(Icons.notifications_outlined, 'Notifications',
                subtitle: 'Cloche par pro, plage horaire, catégories'),
          ]),
          _Section(title: 'Sécurité', tiles: [
            _Tile(Icons.lock_outline, 'Mot de passe'),
            _Tile(Icons.verified_user_outlined, 'Authentification à 2 facteurs',
                subtitle: 'Recommandée pour les paiements'),
            _Tile(Icons.fingerprint, 'Verrouillage biométrique'),
          ]),
          _Section(title: 'Aide & Légal', tiles: [
            _Tile(Icons.help_outline, 'Centre d\'aide'),
            _Tile(Icons.description_outlined, 'Conditions générales'),
            _Tile(Icons.privacy_tip_outlined, 'Politique de confidentialité'),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger)),
              onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen())),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
              child: Text('ProLink v1.0.0 · MVP',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12))),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6)),
        ),
        Card(child: Column(children: tiles)),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _Tile(this.icon, this.title, {this.subtitle});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
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
