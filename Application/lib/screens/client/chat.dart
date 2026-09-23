import 'package:flutter/material.dart';
import '../../l10n.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Chat screen with Alibaba-style inline auto-translation.
/// The user can enable "Traduction auto" — every received or sent message is
/// translated to the user's preferred language and shown under the original,
/// with a small pill and a "Voir l'original" toggle per bubble.
class ChatScreen extends StatefulWidget {
  final Pro peer;
  const ChatScreen({super.key, required this.peer});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  bool _autoTranslate = true;
  String _myLang = 'fr';
  final List<ChatMessage> _msgs = [];

  @override
  void initState() {
    super.initState();
    _msgs.addAll([
      ChatMessage(
          id: '1',
          authorId: widget.peer.id,
          text: 'Bonjour, comment puis-je vous aider ?',
          at: DateTime.now().subtract(const Duration(minutes: 12))),
      ChatMessage(
          id: '2',
          authorId: 'me',
          fromMe: true,
          text: "Hello, I need a quote for creating a SARL.",
          at: DateTime.now().subtract(const Duration(minutes: 11))),
      ChatMessage(
          id: '3',
          authorId: widget.peer.id,
          text: "Très bien, le prix est à partir de 250 000 XAF.",
          at: DateTime.now().subtract(const Duration(minutes: 10))),
    ]);
  }

  String? _translateFor(ChatMessage m) {
    if (!_autoTranslate) return null;
    // Naïve heuristic: detect if text looks like the other language.
    final looksEn = RegExp(r'\b(the|is|hello|need|quote|price)\b',
            caseSensitive: false)
        .hasMatch(m.text);
    final looksFr = RegExp(
            r'\b(bonjour|salut|merci|prix|est|besoin|devis|à partir)\b',
            caseSensitive: false)
        .hasMatch(m.text);
    if (_myLang == 'fr' && looksEn) {
      return OfflineTranslator.translate(m.text, toEn: false);
    }
    if (_myLang == 'en' && looksFr) {
      return OfflineTranslator.translate(m.text, toEn: true);
    }
    return null;
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          authorId: 'me',
          fromMe: true,
          text: t,
          at: DateTime.now()));
      _ctrl.clear();
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _msgs.add(ChatMessage(
          id: 'r${_msgs.length}',
          authorId: widget.peer.id,
          text: "D'accord, je vous confirme cela sous 24 h.",
          at: DateTime.now())));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          Avatar(url: widget.peer.avatar, size: 34),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.peer.name,
                    style: const TextStyle(fontSize: 14)),
                const Text('en ligne',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.success)),
              ],
            ),
          ),
        ]),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.videocam_outlined)),
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.call_outlined)),
          PopupMenuButton(
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'translate',
                  child: ListTile(
                      leading: Icon(Icons.translate),
                      title: Text('Réglages de traduction'))),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          _TranslateBanner(
            enabled: _autoTranslate,
            lang: _myLang,
            onToggle: (v) => setState(() => _autoTranslate = v),
            onLangChange: (v) => setState(() => _myLang = v),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _msgs.length,
              itemBuilder: (_, i) => _Bubble(
                m: _msgs[i],
                translated: _translateFor(_msgs[i]),
                peerAvatar: widget.peer.avatar,
              ),
            ),
          ),
          _Composer(controller: _ctrl, onSend: _send),
        ],
      ),
    );
  }
}

class _TranslateBanner extends StatelessWidget {
  final bool enabled;
  final String lang;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onLangChange;
  const _TranslateBanner(
      {required this.enabled,
      required this.lang,
      required this.onToggle,
      required this.onLangChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.10),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.translate, color: AppColors.secondary, size: 18),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Traduction automatique du chat',
            style:
                TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        DropdownButton<String>(
          value: lang,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 'fr', child: Text('FR')),
            DropdownMenuItem(value: 'en', child: Text('EN')),
          ],
          onChanged: (v) => v == null ? null : onLangChange(v),
        ),
        Switch(value: enabled, onChanged: onToggle),
      ]),
    );
  }
}

class _Bubble extends StatefulWidget {
  final ChatMessage m;
  final String? translated;
  final String peerAvatar;
  const _Bubble(
      {required this.m, required this.translated, required this.peerAvatar});
  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  bool _showOriginal = false;
  @override
  Widget build(BuildContext context) {
    final me = widget.m.fromMe;
    final color = me ? AppColors.primary : AppColors.surface;
    final textColor = me ? Colors.white : AppColors.textPrimary;
    final display = (widget.translated != null && !_showOriginal)
        ? widget.translated!
        : widget.m.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            me ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!me) ...[
            Avatar(url: widget.peerAvatar, size: 26),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(me ? 14 : 4),
                      bottomRight: Radius.circular(me ? 4 : 14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(display,
                          style: TextStyle(color: textColor, height: 1.3)),
                      if (widget.translated != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.translate,
                                size: 12,
                                color: (me ? Colors.white : AppColors.secondary)
                                    .withOpacity(0.8)),
                            const SizedBox(width: 3),
                            Text(
                              _showOriginal
                                  ? 'Original affiché'
                                  : 'Traduit automatiquement',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: (me
                                          ? Colors.white
                                          : AppColors.textSecondary)
                                      .withOpacity(0.8)),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => setState(
                                  () => _showOriginal = !_showOriginal),
                              child: Text(
                                _showOriginal ? 'Voir traduction' : "Voir l'original",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: me
                                        ? Colors.white
                                        : AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(_hhmm(widget.m.at),
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.onSend});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(children: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.attach_file)),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Écrivez un message… (FR/EN, traduction auto)',
                filled: false,
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.mic_none)),
          Container(
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send, color: Colors.white)),
          )
        ]),
      ),
    );
  }
}
