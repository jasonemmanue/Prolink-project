import 'package:flutter/material.dart';
import '../../theme.dart';

class ProLiveBroadcastScreen extends StatefulWidget {
  const ProLiveBroadcastScreen({super.key});
  @override
  State<ProLiveBroadcastScreen> createState() =>
      _ProLiveBroadcastScreenState();
}

class _ProLiveBroadcastScreenState extends State<ProLiveBroadcastScreen> {
  String _mode = 'free';
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        AppBar(title: const Text('Créer un live')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=900'),
                    fit: BoxFit.cover,
                    colorFilter:
                        ColorFilter.mode(Colors.black45, BlendMode.darken),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.videocam,
                      color: Colors.white, size: 56),
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                  decoration: InputDecoration(labelText: 'Titre du live')),
              const SizedBox(height: 10),
              const TextField(
                  maxLines: 3,
                  decoration:
                      InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Date'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.schedule),
                        label: const Text('Heure'))),
              ]),
              const SizedBox(height: 16),
              const Text('Mode',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              RadioListTile(
                  value: 'free',
                  groupValue: _mode,
                  onChanged: (v) => setState(() => _mode = v!),
                  title: const Text('Gratuit ouvert'),
                  subtitle: const Text('Visible par tous')),
              RadioListTile(
                  value: 'followers',
                  groupValue: _mode,
                  onChanged: (v) => setState(() => _mode = v!),
                  title: const Text('Gratuit réservé aux abonnés')),
              RadioListTile(
                  value: 'paid',
                  groupValue: _mode,
                  onChanged: (v) => setState(() => _mode = v!),
                  title: const Text('Payant — billet unique'),
                  subtitle:
                      const Text('Commission plateforme 15%')),
              RadioListTile(
                  value: 'tips',
                  groupValue: _mode,
                  onChanged: (v) => setState(() => _mode = v!),
                  title:
                      const Text('Gratuit avec pourboires (commission 10%)')),
              if (_mode == 'paid') ...[
                const SizedBox(height: 8),
                const TextField(
                    decoration:
                        InputDecoration(labelText: 'Prix du billet (XAF)')),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Programmer / démarrer')),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
