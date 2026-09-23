import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LiveViewScreen extends StatefulWidget {
  final LiveEvent live;
  const LiveViewScreen({super.key, required this.live});
  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  final _c = TextEditingController();
  final List<String> _chat = [
    '👋 Bienvenue tout le monde',
    'Question : quel est le délai moyen d\'immatriculation ?',
    '🙏 Merci pour ce live',
    'Est-ce que vous acceptez les paiements en plusieurs fois ?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        CachedNetworkImage(
            imageUrl: widget.live.cover, fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.3)),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('● LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.remove_red_eye,
                    color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('${widget.live.viewers}',
                    style: const TextStyle(color: Colors.white)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.live.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  Text(widget.live.pro,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _chat.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('👤 spectateur${i + 1} : ${_chat[i]}',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(children: [
                IconButton(
                    onPressed: _tipDialog,
                    icon: const Icon(Icons.local_activity,
                        color: AppColors.accent)),
                Expanded(
                  child: TextField(
                    controller: _c,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un commentaire…',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      if (_c.text.trim().isEmpty) return;
                      setState(() {
                        _chat.add(_c.text);
                        _c.clear();
                      });
                    },
                    icon: const Icon(Icons.send, color: Colors.white)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  void _tipDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Envoyer un pourboire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [500, 1000, 2000, 5000]
                  .map((v) => ChoiceChip(
                      label: Text(formatXaf(v)), selected: false, onSelected: (_) {}))
                  .toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.send),
                    label: const Text('Envoyer'))),
          ]),
        ),
      ),
    );
  }
}
