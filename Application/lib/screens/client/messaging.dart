import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/session.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'chat.dart';
import 'groups.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});
  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  List<Conversation> get _all => MockData.conversations();
  String _query = '';

  List<Conversation> _filter(bool Function(Conversation) f) => _all
      .where(f)
      .where((c) =>
          _query.isEmpty ||
          c.peer.name.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    context.watch<Session>();
    final unread = _all.where((c) => c.unread > 0 && !c.archived).length;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
            IconButton(
              tooltip: 'Nouveau groupe',
              onPressed: () => pushScreen(context, const CreateGroupScreen()),
              icon: const Icon(Icons.group_add_outlined),
            ),
            IconButton(
              tooltip: 'Nouveau message',
              onPressed: () => _newMessage(context),
              icon: const Icon(Icons.edit_note_outlined),
            ),
            const SizedBox(width: 6),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(108),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une conversation',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  const Tab(text: 'Tous'),
                  Tab(text: 'Non lus ($unread)'),
                  const Tab(text: 'Groupes'),
                  const Tab(text: 'Archivés'),
                ],
              ),
            ]),
          ),
        ),
        body: TabBarView(
          children: [
            _ConversationList(convs: _filter((c) => !c.archived)),
            _ConversationList(
                convs: _filter((c) => c.unread > 0 && !c.archived)),
            const GroupList(),
            _ConversationList(convs: _filter((c) => c.archived)),
          ],
        ),
      ),
    );
  }

  void _newMessage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scroll) => ListView(
          controller: scroll,
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
                subtitle: Text('${p.job} · ${p.city}'),
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
    final session = Session.instance;
    Future<void> refresh() async {
      if (session.online) await session.refreshConversations();
    }

    if (convs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.forum_outlined,
              size: 56, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text('Aucune conversation',
              style: TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: convs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
      itemBuilder: (_, i) {
        final c = convs[i];
        final last = c.messages.last;
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Stack(
            children: [
              Avatar(url: c.peer.avatar, size: 52),
              if (c.online)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  c.peer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight:
                          c.unread > 0 ? FontWeight.w800 : FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              VerifiedBadge(level: c.peer.verifiedLevel),
            ],
          ),
          subtitle: Text(
            '${last.fromMe ? 'Vous : ' : ''}${last.text}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: c.unread > 0
                    ? AppColors.textPrimary
                    : AppColors.textSecondary),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo(last.at).replaceFirst('il y a ', ''),
                style: TextStyle(
                    fontSize: 11,
                    color: c.unread > 0
                        ? AppColors.primary
                        : AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              if (c.unread > 0)
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.primary,
                  child: Text('${c.unread}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white)),
                )
              else if (last.fromMe)
                const Icon(Icons.done_all, size: 16, color: AppColors.secondary),
            ],
          ),
          onTap: () async {
            await pushScreen(context, ChatScreen(peer: c.peer));
            await refresh(); // compteurs de non-lus à jour
          },
        );
      },
      ),
    );
  }
}
