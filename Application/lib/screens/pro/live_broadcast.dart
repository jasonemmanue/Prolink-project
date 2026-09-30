import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'live_studio.dart';

/// Écran de préparation d'un live (§8.2.5) : titre, description, mode, prix.
class ProLiveBroadcastScreen extends StatefulWidget {
  const ProLiveBroadcastScreen({super.key});
  @override
  State<ProLiveBroadcastScreen> createState() => _ProLiveBroadcastScreenState();
}

class _ProLiveBroadcastScreenState extends State<ProLiveBroadcastScreen> {
  final _title = TextEditingController();
  String _mode = 'free';
  DateTime? _date;
  TimeOfDay? _time;

  static const _modes = [
    ('free', 'Gratuit ouvert', 'Visible par tous, partageable'),
    (
      'followers',
      'Gratuit réservé aux abonnés',
      'Notifie les abonnés à cloche',
    ),
    ('paid', 'Payant — billet unique', 'Commission plateforme 15 %'),
    ('tips', 'Gratuit avec pourboires', 'Commission 10 % sur les dons'),
  ];

  bool get _scheduled => _date != null;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(title: const Text('Créer un live')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=900',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black45,
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => showInfo(
                        context,
                        'Choisissez une image de couverture',
                      ),
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Couverture',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Titre du live'),
                ),
                const SizedBox(height: 10),
                const TextField(
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _date == null ? 'Maintenant' : formatDate(_date!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          _time == null ? 'Heure' : _time!.format(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mode',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ..._modes.map(
                  (m) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: _mode == m.$1
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _mode == m.$1
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: AppColors.primary,
                      ),
                      title: Text(m.$2),
                      subtitle: Text(m.$3),
                      onTap: () => setState(() => _mode = m.$1),
                    ),
                  ),
                ),
                if (_mode == 'paid') ...[
                  const SizedBox(height: 8),
                  const TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Prix du billet',
                      suffixText: 'XAF',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _go,
                    icon: Icon(
                      _scheduled ? Icons.event_available : Icons.play_arrow,
                    ),
                    label: Text(
                      _scheduled ? 'Programmer le live' : 'Démarrer maintenant',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: _date ?? now,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _time = t);
  }

  void _go() {
    if (_scheduled) {
      showInfo(
        context,
        'Live programmé le ${formatDate(_date!)}. Vos abonnés sont notifiés.',
      );
      return;
    }
    pushScreen(
      context,
      LivePrecheckScreen(title: _title.text.trim(), mode: _mode),
    );
  }
}
