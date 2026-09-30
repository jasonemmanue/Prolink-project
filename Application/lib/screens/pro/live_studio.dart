import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Vérification caméra / micro / connexion avant démarrage (§8.2.5).
class LivePrecheckScreen extends StatefulWidget {
  final String title;
  final String mode;
  final String liveId;
  const LivePrecheckScreen({
    super.key,
    required this.title,
    required this.mode,
    this.liveId = 'demo',
  });
  @override
  State<LivePrecheckScreen> createState() => _LivePrecheckScreenState();
}

class _LivePrecheckScreenState extends State<LivePrecheckScreen> {
  final _checks = [
    ('Caméra', Icons.videocam_outlined),
    ('Microphone', Icons.mic_none),
    ('Connexion (≥ 1,5 Mb/s)', Icons.network_check),
    ('Batterie > 30 %', Icons.battery_charging_full),
  ];
  int _done = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (_done >= _checks.length) {
        t.cancel();
      } else {
        setState(() => _done++);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _done >= _checks.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Vérifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.person, size: 120, color: Colors.white24),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      for (var i = 0; i < 8; i++)
                        Container(
                          width: 4,
                          height: 6.0 + (i % 4) * 4,
                          margin: const EdgeInsets.only(right: 2),
                          color: i < 5 ? AppColors.success : Colors.white24,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.cameraswitch_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: List.generate(_checks.length, (i) {
                final ok = i < _done;
                return ListTile(
                  leading: Icon(_checks[i].$2, color: AppColors.primary),
                  title: Text(_checks[i].$1),
                  trailing: ok
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Qualité estimée : 720p · latence ~2 s (LiveKit)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: ready
                ? () async {
                    final ok = await apiCall<bool>(context, (api) async {
                      await api.post('/lives/${widget.liveId}/start');
                      return true;
                    }, demo: true);
                    if (ok != true || !context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveOnAirScreen(
                          title: widget.title,
                          mode: widget.mode,
                          liveId: widget.liveId,
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.podcasts),
            label: const Text('Passer en direct'),
          ),
        ],
      ),
    );
  }
}

/// Interface de diffusion : vidéo, chat, dons, spectateurs, contrôles.
class LiveOnAirScreen extends StatefulWidget {
  final String title;
  final String mode;
  final String liveId;
  const LiveOnAirScreen({
    super.key,
    required this.title,
    required this.mode,
    this.liveId = 'demo',
  });
  @override
  State<LiveOnAirScreen> createState() => _LiveOnAirScreenState();
}

class _LiveOnAirScreenState extends State<LiveOnAirScreen> {
  Timer? _t;
  int _seconds = 0;
  int _viewers = 12;
  int _peak = 12;
  int _tips = 0;

  bool get _online => Session.instance.online;

  /// En ligne : spectateurs et pourboires réels (toutes les 5 s).
  Future<void> _poll() async {
    try {
      final lv = await Session.instance.api.get('/lives/${widget.liveId}');
      if (!mounted) return;
      final tips = lv['tips_xaf'] as int;
      setState(() {
        if (tips > _tips) _events.add('💰 Nouveau pourboire : ${formatXaf(tips - _tips)}');
        _viewers = lv['viewers'];
        _peak = lv['peak_viewers'];
        _tips = tips;
      });
    } catch (_) {}
  }
  bool _mic = true;
  bool _cam = true;
  final _events = <String>['Grace F. a rejoint', 'Paul N. : Bonjour Maître !'];

  @override
  void initState() {
    super.initState();
    if (_online) {
      _viewers = 0;
      _peak = 0;
      _events
        ..clear()
        ..add('Vous êtes en direct 🎥');
    }
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_online) {
        setState(() => _seconds++);
        if (_seconds % 5 == 0) _poll();
        return;
      }
      setState(() {
        _seconds++;
        if (_seconds % 3 == 0) {
          _viewers += 3;
          _peak = _viewers;
        }
        if (_seconds % 7 == 0) {
          _tips += 1000;
          _events.add('💰 Brice E. a envoyé un pourboire de 1 000 XAF');
        } else if (_seconds % 5 == 0) {
          _events.add('Question : combien coûte l\'immatriculation ?');
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String get _clock =>
      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _end();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _cam ? Icons.person : Icons.videocam_off,
                  size: 160,
                  color: Colors.white12,
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Pill(
                          label: 'EN DIRECT',
                          color: AppColors.danger,
                          icon: Icons.circle,
                        ),
                        const SizedBox(width: 8),
                        _chip(Icons.timer_outlined, _clock),
                        const SizedBox(width: 6),
                        _chip(Icons.remove_red_eye_outlined, '$_viewers'),
                        const SizedBox(width: 6),
                        _chip(
                          Icons.volunteer_activism_outlined,
                          formatXaf(_tips),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.title.isEmpty ? 'Live sans titre' : widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 200,
                    child: ListView(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _events.reversed
                          .take(12)
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  e,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ctrl(
                          _mic ? Icons.mic : Icons.mic_off,
                          'Micro',
                          () => setState(() => _mic = !_mic),
                        ),
                        _ctrl(
                          _cam ? Icons.videocam : Icons.videocam_off,
                          'Caméra',
                          () => setState(() => _cam = !_cam),
                        ),
                        _ctrl(Icons.cameraswitch_outlined, 'Retourner', () {}),
                        _ctrl(Icons.push_pin_outlined, 'Épingler', () {
                          showInfo(
                            context,
                            'Question épinglée pour les spectateurs.',
                          );
                        }),
                        _ctrl(
                          Icons.stop_circle_outlined,
                          'Terminer',
                          _end,
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData i, String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(i, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );

  Widget _ctrl(
    IconData i,
    String label,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: Colors.white12,
          foregroundColor: color,
        ),
        onPressed: onTap,
        icon: Icon(i),
      ),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );

  Future<void> _end() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer le live ?'),
        content: const Text(
          'Les spectateurs seront déconnectés. Le replay sera généré automatiquement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Terminer',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    var seconds = _seconds, peak = _peak, tips = _tips;
    final r = await apiCall<Map>(
      context,
      (api) async => await api.post('/lives/${widget.liveId}/end', {'replay_policy': 'free'}) as Map,
      demo: const {},
    );
    if (r == null || !mounted) return;
    _t?.cancel();
    final s = r['summary'] as Map?;
    if (s != null) {
      seconds = s['duration_seconds'];
      peak = s['peak_viewers'];
      tips = s['tips_xaf'] + s['tickets_xaf'];
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveSummaryScreen(
          seconds: seconds,
          peakViewers: peak,
          tipsXaf: tips,
          liveId: widget.liveId,
        ),
      ),
    );
  }
}

/// Bilan de fin de live + gestion du replay (UC-PR-14).
class LiveSummaryScreen extends StatefulWidget {
  final int seconds;
  final int peakViewers;
  final int tipsXaf;
  final String liveId;
  const LiveSummaryScreen({
    super.key,
    required this.seconds,
    required this.peakViewers,
    required this.tipsXaf,
    this.liveId = 'demo',
  });
  @override
  State<LiveSummaryScreen> createState() => _LiveSummaryScreenState();
}

class _LiveSummaryScreenState extends State<LiveSummaryScreen> {
  String _replay = 'free';
  final _price = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final net = (widget.tipsXaf * 0.9).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Bilan du live')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _stat(
                'Durée',
                '${widget.seconds ~/ 60} min ${widget.seconds % 60} s',
              ),
              _stat('Spectateurs pic', '${widget.peakViewers}'),
              _stat('Recettes brutes', formatXaf(widget.tipsXaf)),
              _stat('Net estimé', formatXaf(net)),
            ],
          ),
          const SectionLabel('Replay'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'free', label: Text('Libre')),
              ButtonSegment(value: 'paid', label: Text('Payant')),
              ButtonSegment(value: 'private', label: Text('Réservé')),
            ],
            selected: {_replay},
            onSelectionChanged: (s) => setState(() => _replay = s.first),
          ),
          if (_replay == 'paid') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prix du replay',
                suffixText: 'XAF',
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final ok = await apiCall<bool>(context, (api) async {
                await api.patch('/lives/${widget.liveId}', {
                  'replay_policy': _replay,
                  'replay_price_xaf': int.tryParse(_price.text.replaceAll(' ', '')) ?? 0,
                });
                return true;
              }, demo: true);
              if (ok != true || !context.mounted) return;
              Session.instance.afterMoneyAction();
              Navigator.pop(context);
              showInfo(context, 'Replay publié sur votre profil.');
            },
            child: const Text('Publier le replay'),
          ),
        ],
      ),
    );
  }

  Widget _stat(String k, String v) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            k,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            v,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    ),
  );
}
