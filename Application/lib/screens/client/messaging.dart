import 'package:flutter/material.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'chat.dart';
import 'groups.dart';

class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final convs = MockData.conversations();
    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
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
                  tooltip: 'Nouveau groupe',
                  onPressed: () =>
                      pushScreen(context, const CreateGroupScreen()),
                  icon: const Icon(Icons.group_add_outlined),
                ),
                IconButton(
                  tooltip: 'Nouveau message',
                  onPressed: () => _newMessage(context),
                  icon: const Icon(Icons.edit_note_outlined),
                ),
                const SizedBox(width: 6),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ConversationList(convs: convs),
                  _ConversationList(convs: convs.take(1).toList()),
                  const GroupList(),
                  Center(
                    child: Text(
                      'Aucune conversation archivée',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _newMessage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Nouveau message',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            ...MockData.pros.map(
              (p) => ListTile(
                leading: Avatar(url: p.avatar, size: 40),
                title: Text(p.name),
                subtitle: Text(p.job),
                onTap: () {
                  Navigator.pop(ctx);
                  pushScreen(context, ChatScreen(peer: p));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final List<Conversation> convs;
  const _ConversationList({required this.convs});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (_, i) {
        final c = convs[i];
        final last = c.messages.last;
        return ListTile(
          leading: Stack(
            children: [
              Avatar(url: c.peer.avatar, size: 48),
              const Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: AppColors.success,
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Text(
                c.peer.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              VerifiedBadge(level: c.peer.verifiedLevel),
            ],
          ),
          subtitle: Text(
            last.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo(last.at),
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              if (i == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '2',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(peer: c.peer)),
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: convs.length,
    );
  }
}
