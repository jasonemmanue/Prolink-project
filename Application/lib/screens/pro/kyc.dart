import 'package:flutter/material.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../theme.dart';
import '../pro_shell.dart';
import '../../widgets/common.dart';

/// Vérification KYC en 3 niveaux (UC-PR-01) :
/// bleu Vérifié · or Premium · violet Expert.
class KycScreen extends StatefulWidget {
  const KycScreen({super.key});
  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  // 0 = à fournir, 1 = envoyé (en revue), 2 = validé
  final Map<String, int> _docs = {
    'Pièce d\'identité (CNI / passeport)': 2,
    'Selfie de vérification': 2,
    'Justificatif de domicile': 1,
    'Registre de commerce / ordre professionnel': 0,
    'Diplômes & certifications': 0,
  };

  static const _kinds = {
    'Pièce d\'identité (CNI / passeport)': 'id_card',
    'Selfie de vérification': 'selfie',
    'Justificatif de domicile': 'address',
    'Registre de commerce / ordre professionnel': 'registry',
    'Diplômes & certifications': 'diploma',
  };

  final _job = TextEditingController();
  String _category = MockData.categories.first;

  bool get _online => Session.instance.online;
  bool get _needsProfile => _online && !Session.instance.isPro;

  @override
  void initState() {
    super.initState();
    if (_online && !_needsProfile) _load();
  }

  Future<void> _load() async {
    final list = await apiCall<List>(
        context, (api) async => await api.get('/pros/me/kyc') as List);
    if (list == null || !mounted) return;
    setState(() {
      for (final k in _docs.keys) {
        _docs[k] = 0;
      }
      for (final d in list) {
        final label = _kinds.entries.firstWhere((e) => e.value == d['kind']).key;
        final st = d['status'] == 'approved' ? 2 : d['status'] == 'pending' ? 1 : 0;
        if (st > _docs[label]!) _docs[label] = st;
      }
    });
  }

  Future<void> _send(String label) async {
    // Stockage de fichiers à brancher (S3/GCS) : on référence le document.
    final kind = _kinds[label]!;
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/pros/me/kyc', {
        'kind': kind,
        'file_url': 'https://storage.prolink.cm/kyc/${Session.instance.userId}/$kind.jpg',
      });
      return true;
    }, demo: true, success: 'Document envoyé pour vérification');
    if (ok == true && mounted) setState(() => _docs[label] = 1);
  }

  /// Internaute → compte pro (« Devenir professionnel »).
  Future<void> _becomePro() async {
    if (_job.text.trim().length < 2) {
      showInfo(context, 'Indiquez votre métier');
      return;
    }
    final ok = await apiCall<bool>(context, (api) async {
      await api.post('/pros/me', {'job': _job.text.trim(), 'category': _category});
      await Session.instance.refreshMe();
      await Session.instance.bootstrap();
      return true;
    });
    if (ok != true || !mounted) return;
    showInfo(context, 'Compte professionnel créé 🎉');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ProShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification du compte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_needsProfile) ...[
            Card(
              color: AppColors.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Créer mon profil professionnel',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text('Publiez vos services, recevez des commandes payées en séquestre.'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _job,
                      decoration: const InputDecoration(labelText: 'Métier (ex. Photographe)'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Catégorie principale'),
                      items: [
                        for (final c in MockData.categories)
                          DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: (v) => _category = v ?? _category,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _becomePro,
                        child: const Text('Devenir professionnel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const _Level(
            level: 1,
            title: 'Vérifié',
            desc: 'Identité + selfie. Débloque la vente de prestations.',
            state: 'Obtenu',
          ),
          const _Level(
            level: 2,
            title: 'Premium',
            desc: 'Justificatif pro + 10 prestations notées ≥ 4,5.',
            state: 'En revue',
          ),
          const _Level(
            level: 3,
            title: 'Expert',
            desc: 'Diplômes vérifiés + entretien avec l\'équipe ProLink.',
            state: 'À débloquer',
          ),
          const SectionLabel('Documents'),
          Card(
            child: Column(
              children: _docs.entries.map((e) {
                final (label, color, icon) = switch (e.value) {
                  2 => ('Validé', AppColors.success, Icons.check_circle),
                  1 => ('En revue', AppColors.accent, Icons.hourglass_top),
                  _ => (
                    'À fournir',
                    AppColors.textSecondary,
                    Icons.upload_file,
                  ),
                };
                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(e.key),
                  subtitle: Text(label, style: TextStyle(color: color)),
                  trailing: e.value == 0
                      ? OutlinedButton(
                          onPressed: _needsProfile ? null : () => _send(e.key),
                          child: const Text('Envoyer'),
                        )
                      : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vos documents sont chiffrés et consultés uniquement par l\'équipe conformité. Délai moyen de revue : 48 h.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Level extends StatelessWidget {
  final int level;
  final String title, desc, state;
  const _Level({
    required this.level,
    required this.title,
    required this.desc,
    required this.state,
  });
  @override
  Widget build(BuildContext context) {
    final done = state == 'Obtenu';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: VerifiedBadge(level: level),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(desc),
        trailing: Pill(
          label: state,
          color: done
              ? AppColors.success
              : state == 'En revue'
              ? AppColors.accent
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}
