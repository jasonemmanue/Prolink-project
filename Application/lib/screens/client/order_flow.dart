import 'package:flutter/material.dart';
import '../../api/session.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'my_orders.dart';

/// Commande en 4 étapes ; le paiement place les fonds en séquestre (API).
class OrderFlowScreen extends StatefulWidget {
  final Pro pro;
  final Service service;
  final ServiceVariant? variant;
  const OrderFlowScreen({
    super.key,
    required this.pro,
    required this.service,
    this.variant,
  });

  @override
  State<OrderFlowScreen> createState() => _OrderFlowScreenState();
}

class _OrderFlowScreenState extends State<OrderFlowScreen> {
  int _step = 0;
  String _payMethod = 'wallet';
  bool _busy = false;
  final _zone = TextEditingController();
  final _brief = TextEditingController();
  final _phone = TextEditingController();

  int get _amount => widget.variant?.priceXaf ?? widget.service.priceXaf;

  @override
  void dispose() {
    _zone.dispose();
    _brief.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    final brief = [
      if (_zone.text.trim().isNotEmpty) 'Zone : ${_zone.text.trim()}',
      _brief.text.trim(),
    ].where((e) => e.isNotEmpty).join('\n');
    final order = await apiCall<Map>(
      context,
      (api) async => await api.post('/orders', {
        'service_id': widget.service.id,
        if (widget.variant != null) 'variant': widget.variant!.name,
        'brief': brief,
        'payment_method': _payMethod,
        if (_payMethod != 'wallet') 'phone': _phone.text.trim(),
      }) as Map,
      demo: const {'code': 'PL-10422'},
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (order == null) return;
    await Session.instance.afterMoneyAction();
    if (mounted) _showSuccess(order['code'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Commande')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _busy
            ? null
            : () {
                if (_step < 3) {
                  setState(() => _step += 1);
                } else {
                  _pay();
                }
              },
        onStepCancel: () => setState(() => _step = (_step - 1).clamp(0, 3)),
        controlsBuilder: (_, ctrl) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: ctrl.onStepContinue,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_step == 3 ? 'Payer & bloquer' : 'Continuer'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: ctrl.onStepCancel,
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('Récapitulatif'),
            isActive: _step >= 0,
            content: Card(
              child: ListTile(
                title: Text(widget.service.title),
                subtitle: Text(
                  widget.variant == null
                      ? widget.pro.name
                      : '${widget.pro.name} · Formule ${widget.variant!.name}',
                ),
                trailing: Text(
                  formatXaf(_amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          Step(
            title: const Text('Informations utiles'),
            isActive: _step >= 1,
            content: Column(
              children: [
                TextField(
                  controller: _zone,
                  decoration: const InputDecoration(labelText: 'Ville / Zone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _brief,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Détail de votre besoin',
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Méthode de paiement'),
            isActive: _step >= 2,
            content: Column(
              children: [
                for (final m in [
                  ('wallet', 'Portefeuille ProLink',
                      'Solde : ${formatXaf(session.balanceXaf)}'),
                  ('mtn', 'MTN Mobile Money', 'Confirmation USSD sur votre téléphone'),
                  ('orange', 'Orange Money', 'Confirmation USSD sur votre téléphone'),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _payMethod == m.$1
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: AppColors.primary,
                    ),
                    title: Text(m.$2),
                    subtitle: Text(m.$3),
                    onTap: () => setState(() => _payMethod = m.$1),
                  ),
                if (_payMethod != 'wallet')
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro Mobile Money',
                      prefixText: '+237 ',
                    ),
                  ),
                if (_payMethod == 'wallet' && session.balanceXaf < _amount)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Solde insuffisant : rechargez votre portefeuille ou payez par Mobile Money.',
                      style: TextStyle(color: AppColors.danger, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Confirmation'),
            isActive: _step >= 3,
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${formatXaf(_amount)} seront bloqués en séquestre jusqu\'à '
                      'la validation de la prestation.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String code) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.success,
                child: Icon(Icons.check, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Commande confirmée',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Commande $code — fonds bloqués en séquestre. '
                'Vous serez notifié dès la prise en charge par le pro.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pop(); // feuille
                  nav.pop(); // tunnel de commande
                  nav.pushReplacement(
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  );
                },
                child: const Text('Voir mes commandes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
