import 'package:flutter/material.dart';
import '../../data.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'chat.dart';

class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final convs = MockData.conversations();
    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Column(children: [
          AppBar(
            title: const Text('Messages'),
            bottom: const TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Tous'),
                Tab(text: 'Non lus'),
                Tab(text: 'Groupes'),
                Tab(text: 'Archivés'),
              ],
            ),
            actions: [
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.search)),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_note_outlined)),
              const SizedBox(width: 6),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemBuilder: (_, i) {
                final c = convs[i];
                final last = c.messages.last;
                return ListTile(
                  leading: Stack(children: [
                    Avatar(url: c.peer.avatar, size: 48),
                    const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                            radius: 6,
                            backgroundColor: AppColors.success)),
                  ]),
                  title: Row(children: [
                    Text(c.peer.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    VerifiedBadge(level: c.peer.verifiedLevel),
                  ]),
                  subtitle: Text(last.text,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_timeAgo(last.at),
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                      if (i == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primary,
                              child: Text('2',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white))),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ChatScreen(peer: c.peer))),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: convs.length,
            ),
          ),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }
}
