import 'package:flutter/material.dart';
import '../../theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification du compte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                          onPressed: () => setState(() => _docs[e.key] = 1),
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
