import 'package:flutter/material.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Paramétrage granulaire des notifications : par catégorie et par pro
/// (cahier des charges §8.1.8, UC-IN-05).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final Map<String, bool> _categories = {
    'Commandes & séquestre': true,
    'Messages privés': true,
    'Lives des pros suivis': true,
    'Nouvelles publications': false,
    'Promotions & sponsorisés': false,
  };
  late final Map<String, bool> _bells = {
    for (final p in MockData.pros) p.id: p.verifiedLevel >= 2,
  };
  bool _quietHours = true;
  bool _email = false;
  bool _sms = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SectionLabel('Par catégorie'),
          Card(
            child: Column(
              children: _categories.keys
                  .map(
                    (k) => SwitchListTile(
                      title: Text(k),
                      value: _categories[k]!,
                      onChanged: (v) => setState(() => _categories[k] = v),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SectionLabel('Cloche par professionnel'),
          Card(
            child: Column(
              children: MockData.pros
                  .map(
                    (p) => ListTile(
                      leading: Avatar(url: p.avatar, size: 36),
                      title: Text(p.name),
                      subtitle: Text(p.job),
                      trailing: IconButton(
                        icon: Icon(
                          _bells[p.id]!
                              ? Icons.notifications_active
                              : Icons.notifications_off_outlined,
                          color: _bells[p.id]!
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _bells[p.id] = !_bells[p.id]!),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SectionLabel('Canaux & horaires'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Ne pas déranger (22 h – 7 h)'),
                  subtitle: const Text('Les pushs sont regroupés au réveil'),
                  value: _quietHours,
                  onChanged: (v) => setState(() => _quietHours = v),
                ),
                SwitchListTile(
                  title: const Text('Récapitulatif par e-mail'),
                  value: _email,
                  onChanged: (v) => setState(() => _email = v),
                ),
                SwitchListTile(
                  title: const Text('SMS pour les paiements'),
                  subtitle: const Text('Recommandé en cas de réseau faible'),
                  value: _sms,
                  onChanged: (v) => setState(() => _sms = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Confidentialité & sécurité : 2FA, biométrie, sessions actives (§8.1.8).
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFa = Session.instance.twoFaEnabled;
  bool _biometric = true;
  bool _privateProfile = false;
  final _sessions = [
    ('Tecno Camon 20 · Android', 'Douala · cet appareil', true),
    ('Chrome · Windows', 'Yaoundé · il y a 2 j', false),
    ('Samsung A14 · Android', 'Bafoussam · il y a 9 j', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité & confidentialité')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (!_twoFa)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.accent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La double authentification devient obligatoire dès 100 000 XAF de transactions par mois.',
                    ),
                  ),
                ],
              ),
            ),
          const SectionLabel('Connexion'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.sms_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Authentification à 2 facteurs'),
                  subtitle: Text(
                    _twoFa
                        ? 'Code SMS envoyé au +237 6•• •• •• 42'
                        : 'Désactivée',
                  ),
                  value: _twoFa,
                  onChanged: (v) async {
                    final s = Session.instance;
                    String? devCode;
                    if (s.online) {
                      final r = await apiCall<Map>(
                        context,
                        (api) async => await api.post('/auth/otp/send',
                            {'target': '-', 'purpose': '2fa'}) as Map,
                      );
                      if (r == null) return;
                      devCode = r['dev_code'];
                    }
                    if (!context.mounted) return;
                    final code = await _confirmOtp(context, devCode);
                    if (code == null || !context.mounted) return;
                    final ok = await apiCall<bool>(context, (api) async {
                      await api.post(v ? '/auth/2fa/enable' : '/auth/2fa/disable',
                          {'target': '-', 'purpose': '2fa', 'code': code});
                      await s.refreshMe();
                      return true;
                    }, demo: true);
                    if (ok == true && mounted) setState(() => _twoFa = v);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.fingerprint,
                    color: AppColors.primary,
                  ),
                  title: const Text('Déverrouillage biométrique'),
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    color: AppColors.primary,
                  ),
                  title: const Text('Changer le mot de passe'),
                  subtitle: const Text('Dernière modification il y a 3 mois'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showInfo(
                    context,
                    'Un lien de réinitialisation a été envoyé par SMS.',
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Confidentialité'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.visibility_off_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Profil privé'),
                  subtitle: const Text(
                    'Seuls les pros contactés voient votre profil',
                  ),
                  value: _privateProfile,
                  onChanged: (v) => setState(() => _privateProfile = v),
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: AppColors.primary),
                  title: const Text('Utilisateurs bloqués'),
                  trailing: const Text('0'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.download_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Télécharger mes données'),
                  subtitle: const Text('Export sous 48 h par e-mail'),
                  onTap: () =>
                      showInfo(context, 'Demande d\'export enregistrée.'),
                ),
              ],
            ),
          ),
          SectionLabel(
            'Sessions actives',
            trailing: TextButton(
              onPressed: () =>
                  setState(() => _sessions.removeWhere((s) => !s.$3)),
              child: const Text('Déconnecter les autres'),
            ),
          ),
          Card(
            child: Column(
              children: _sessions
                  .map(
                    (s) => ListTile(
                      leading: Icon(
                        s.$1.contains('Chrome')
                            ? Icons.laptop
                            : Icons.smartphone,
                        color: AppColors.primary,
                      ),
                      title: Text(s.$1),
                      subtitle: Text(s.$2),
                      trailing: s.$3
                          ? const Pill(
                              label: 'Actuelle',
                              color: AppColors.success,
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: AppColors.danger,
                              ),
                              onPressed: () =>
                                  setState(() => _sessions.remove(s)),
                            ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<String?> _confirmOtp(BuildContext context, String? devCode) {
    final c = TextEditingController(text: devCode ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vérification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Saisissez le code à 6 chiffres reçu par SMS.'),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 8),
              decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

/// Édition des informations personnelles (§8.1.8).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _me = Session.instance.me ?? const {};
  late final _name = TextEditingController(
      text: Session.instance.online ? _me['name'] : 'Emmanuel Sakam');
  late final _city = TextEditingController(
      text: Session.instance.online ? (_me['city'] ?? '') : 'Douala');
  late final _address = TextEditingController(
      text: Session.instance.online ? (_me['address'] ?? '') : 'Akwa, rue Joss');
  late final Set<String> _langs = {
    for (final l in (Session.instance.online
        ? List<String>.from(_me['languages'] ?? const ['FR'])
        : const ['FR', 'EN']))
      l,
  };
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await apiCall<bool>(context, (api) async {
      await api.patch('/auth/me', {
        'name': _name.text.trim(),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'languages': _langs.toList(),
      });
      await Session.instance.refreshMe();
      return true;
    }, demo: true);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok != true) return;
    Navigator.pop(context);
    showInfo(context, 'Profil mis à jour');
  }

  @override
  Widget build(BuildContext context) {
    final online = Session.instance.online;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Enregistrer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                Avatar(url: Session.instance.avatar, size: 96),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _field('Nom complet', _name, Icons.person_outline),
          _readOnly('Téléphone',
              online ? (_me['phone'] ?? '—') : '+237 6 90 00 00 42', Icons.phone_outlined),
          _readOnly('E-mail',
              online ? (_me['email'] ?? '—') : 'emmanuel@exemple.cm', Icons.mail_outline),
          _field('Ville', _city, Icons.location_city_outlined),
          _field('Quartier / adresse', _address, Icons.home_outlined),
          const SectionLabel('Langues parlées'),
          Wrap(
            spacing: 8,
            children: [
              for (final l in const [('FR', 'Français'), ('EN', 'English')])
                FilterChip(
                  label: Text(l.$2),
                  selected: _langs.contains(l.$1),
                  onSelected: (v) =>
                      setState(() => v ? _langs.add(l.$1) : _langs.remove(l.$1)),
                ),
            ],
          ),
          const SectionLabel('Centres d\'intérêt'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in MockData.categories.take(8))
                FilterChip(
                  label: Text(c),
                  selected: c.startsWith('D') || c.startsWith('S'),
                  onSelected: (_) {},
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    ),
  );

  Widget _readOnly(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    ),
  );
}

/// Aide, FAQ, contact support, CGU (§8.1.8).
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faq = [
    (
      'Comment fonctionne le paiement séquestré ?',
      'Votre argent est bloqué par ProLink jusqu\'à ce que vous validiez la '
          'prestation. Sans réponse de votre part sous 72 h après livraison, '
          'le paiement est libéré automatiquement au professionnel.',
    ),
    (
      'Comment ouvrir un litige ?',
      'Depuis « Mes commandes », ouvrez la commande puis « Signaler un '
          'problème ». Un médiateur ProLink tranche sous 5 jours ouvrés.',
    ),
    (
      'Quels moyens de paiement sont acceptés ?',
      'MTN Mobile Money, Orange Money, carte bancaire (via CinetPay) et le '
          'portefeuille ProLink.',
    ),
    (
      'La traduction du chat est-elle obligatoire ?',
      'Non. L\'interrupteur en haut de chaque conversation permet de la '
          'désactiver ; « Voir l\'original » reste toujours disponible.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide & support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher dans l\'aide',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SectionLabel('Questions fréquentes'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _faq
                  .map(
                    (f) => ExpansionTile(
                      title: Text(
                        f.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [Text(f.$2)],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SectionLabel('Nous contacter'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.support_agent,
                    color: AppColors.primary,
                  ),
                  title: const Text('Chat avec le support'),
                  subtitle: const Text('Réponse moyenne : 12 min'),
                  onTap: () => showInfo(context, 'Un conseiller vous répond.'),
                ),
                const ListTile(
                  leading: Icon(
                    Icons.chat_outlined,
                    color: AppColors.secondary,
                  ),
                  title: Text('WhatsApp'),
                  subtitle: Text('+237 6 99 00 00 00'),
                ),
                const ListTile(
                  leading: Icon(Icons.mail_outline, color: AppColors.accent),
                  title: Text('support@prolink.cm'),
                ),
              ],
            ),
          ),
          const SectionLabel('Légal'),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Conditions générales d\'utilisation'),
                  trailing: Icon(Icons.open_in_new, size: 18),
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Politique de confidentialité'),
                  trailing: Icon(Icons.open_in_new, size: 18),
                ),
                ListTile(
                  leading: Icon(Icons.gavel_outlined),
                  title: Text('Politique de contenu'),
                  trailing: Icon(Icons.open_in_new, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
