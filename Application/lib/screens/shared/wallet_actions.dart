import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

const _methods = [
  ('mtn', 'MTN Mobile Money', Icons.phone_android),
  ('orange', 'Orange Money', Icons.phone_iphone),
  ('card', 'Carte bancaire (CinetPay)', Icons.credit_card),
];

/// Rechargement du portefeuille (UC-IN-21).
class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});
  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  int _amount = 10000;
  String _method = 'mtn';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharger')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(
              formatXaf(_amount),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final v in [2000, 5000, 10000, 25000, 50000])
                ChoiceChip(
                  label: Text(formatXaf(v)),
                  selected: _amount == v,
                  onSelected: (_) => setState(() => _amount = v),
                ),
            ],
          ),
          const SectionLabel('Moyen de paiement'),
          _MethodPicker(
            value: _method,
            onChanged: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: 12),
          if (_method != 'card')
            const TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numéro Mobile Money',
                prefixText: '+237 ',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Frais : 0 XAF. Vous recevrez une demande de confirmation USSD sur votre téléphone.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showInfo(
                context,
                'Confirmez le paiement de ${formatXaf(_amount)} sur votre téléphone.',
              );
            },
            child: Text('Recharger ${formatXaf(_amount)}'),
          ),
        ],
      ),
    );
  }
}

/// Retrait des gains vers Mobile Money (UC-PR-18, annexe C.3).
/// Réservé aux pros ; minimum 500 XAF laissé sur le portefeuille.
class WithdrawScreen extends StatefulWidget {
  final int availableXaf;
  const WithdrawScreen({super.key, required this.availableXaf});
  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  static const _minBalance = 500;
  late double _amount = (widget.availableXaf - _minBalance) / 2;
  String _method = 'mtn';
  int _step = 0; // 0 = saisie, 1 = code 2FA, 2 = succès

  int get _max => widget.availableXaf - _minBalance;
  int get _fees => (_amount * 0.01).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retirer mes gains')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (_step) {
          0 => _form(),
          1 => _otp(),
          _ => _done(),
        },
      ),
    );
  }

  Widget _form() => ListView(
    key: const ValueKey(0),
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Disponible : ${formatXaf(widget.availableXaf)}',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          formatXaf(_amount.round()),
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
      Slider(
        value: _amount,
        min: 1000,
        max: _max.toDouble(),
        divisions: (_max - 1000) ~/ 1000,
        onChanged: (v) => setState(() => _amount = v),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => setState(() => _amount = _max.toDouble()),
            child: const Text('Tout retirer'),
          ),
        ],
      ),
      const SectionLabel('Vers'),
      _MethodPicker(
        value: _method,
        onChanged: (m) => setState(() => _method = m),
        mobileOnly: true,
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _row('Montant', formatXaf(_amount.round())),
              _row('Frais opérateur (1 %)', '- ${formatXaf(_fees)}'),
              const Divider(),
              _row(
                'Vous recevez',
                formatXaf(_amount.round() - _fees),
                bold: true,
              ),
              _row('Délai', 'Instantané à 24 h'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => setState(() => _step = 1),
        child: const Text('Continuer'),
      ),
    ],
  );

  Widget _otp() => Padding(
    key: const ValueKey(1),
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 56,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        const Text(
          'Confirmez le retrait',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Code envoyé par SMS au +237 6•• •• •• 42',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const TextField(
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, letterSpacing: 10),
          decoration: InputDecoration(counterText: '', hintText: '••••••'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 2),
            child: const Text('Valider'),
          ),
        ),
      ],
    ),
  );

  Widget _done() => Center(
    key: const ValueKey(2),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.success,
            child: Icon(Icons.check, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 16),
          Text(
            '${formatXaf(_amount.round() - _fees)} en route',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Référence WD-58213 · statut : en traitement',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Terminé'),
          ),
        ],
      ),
    ),
  );

  Widget _row(String k, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(k, style: TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          v,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _MethodPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool mobileOnly;
  const _MethodPicker({
    required this.value,
    required this.onChanged,
    this.mobileOnly = false,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: _methods
            .where((m) => !mobileOnly || m.$1 != 'card')
            .map(
              (m) => ListTile(
                leading: Icon(m.$3, color: AppColors.primary),
                title: Text(m.$2),
                trailing: Icon(
                  value == m.$1
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.primary,
                ),
                onTap: () => onChanged(m.$1),
              ),
            )
            .toList(),
      ),
    );
  }
}
