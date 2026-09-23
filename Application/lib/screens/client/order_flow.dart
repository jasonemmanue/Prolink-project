import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class OrderFlowScreen extends StatefulWidget {
  final Pro pro;
  final Service service;
  const OrderFlowScreen(
      {super.key, required this.pro, required this.service});

  @override
  State<OrderFlowScreen> createState() => _OrderFlowScreenState();
}

class _OrderFlowScreenState extends State<OrderFlowScreen> {
  int _step = 0;
  String _payMethod = 'wallet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commande')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step < 3) setState(() => _step += 1);
          else _showSuccess();
        },
        onStepCancel: () => setState(() => _step = (_step - 1).clamp(0, 3)),
        controlsBuilder: (_, ctrl) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            ElevatedButton(
                onPressed: ctrl.onStepContinue,
                child: Text(_step == 3 ? 'Payer & bloquer' : 'Continuer')),
            const SizedBox(width: 8),
            TextButton(
                onPressed: ctrl.onStepCancel, child: const Text('Retour')),
          ]),
        ),
        steps: [
          Step(
            title: const Text('Récapitulatif'),
            isActive: _step >= 0,
            content: Card(
              child: ListTile(
                title: Text(widget.service.title),
                subtitle: Text(widget.pro.name),
                trailing: Text(formatXaf(widget.service.priceXaf),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ),
            ),
          ),
          Step(
            title: const Text('Informations utiles'),
            isActive: _step >= 1,
            content: Column(
              children: const [
                TextField(
                    decoration: InputDecoration(labelText: 'Ville / Zone')),
                SizedBox(height: 10),
                TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: 'Détail de votre besoin')),
              ],
            ),
          ),
          Step(
            title: const Text('Méthode de paiement'),
            isActive: _step >= 2,
            content: Column(children: [
              RadioListTile(
                  value: 'wallet',
                  groupValue: _payMethod,
                  onChanged: (v) => setState(() => _payMethod = v!),
                  title: const Text('Portefeuille ProLink'),
                  subtitle: const Text('Solde : 45 000 XAF')),
              RadioListTile(
                  value: 'mtn',
                  groupValue: _payMethod,
                  onChanged: (v) => setState(() => _payMethod = v!),
                  title: const Text('MTN Mobile Money'),
                  subtitle: const Text('677 00 00 00')),
              RadioListTile(
                  value: 'orange',
                  groupValue: _payMethod,
                  onChanged: (v) => setState(() => _payMethod = v!),
                  title: const Text('Orange Money'),
                  subtitle: const Text('699 00 00 00')),
            ]),
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
              child: Row(children: const [
                Icon(Icons.lock, color: AppColors.success),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Vos fonds seront bloqués en séquestre jusqu\'à la validation de la prestation.')),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
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
              const Text('Commande confirmée',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                  'Un groupe de discussion privé a été créé. Vous serez notifié dès la confirmation du pro.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Voir mes commandes')),
            ],
          ),
        ),
      ),
    );
  }
}
