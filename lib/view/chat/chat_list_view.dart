import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/ChatModels.dart';
import '../../components/toolbar_layout.dart';
import '../../core/chat/chat_service.dart';
import '../../utils/routes/routes_name.dart';
import '../../viewModel/chat_viewmodel.dart';
import 'widget/chat_common.dart';

class ChatListView extends ConsumerStatefulWidget {
  const ChatListView({super.key});

  @override
  ConsumerState<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends ConsumerState<ChatListView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(chatSessionProvider);
    final threadsAsync = ref.watch(chatThreadsProvider);
    final me = sessionAsync.value;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        floatingActionButton: me == null
            ? null
            : FloatingActionButton(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                tooltip: 'New chat',
                onPressed: () => Navigator.pushNamed(context, RoutesName.newchat),
                child: const Icon(Icons.edit_rounded),
              ),
        body: Column(
          children: [
            ToolbarLayout(
              title: 'Chat',
              searchHint: 'Search chats...',
              onSearch: (q) => setState(() => _query = q.trim().toLowerCase()),
              onRefresh: () => ref.invalidate(chatSessionProvider),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: _body(sessionAsync, threadsAsync, me),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    AsyncValue<ChatMe?> sessionAsync,
    AsyncValue<List<ChatThread>> threadsAsync,
    ChatMe? me,
  ) {
    if (!ChatService.instance.isReady) {
      return const _Message(
        icon: Icons.cloud_off_rounded,
        text: 'Chat is not configured yet.\nPlease contact the admin.',
      );
    }
    if (sessionAsync.hasError) {
      return _Message(
        icon: Icons.error_outline,
        text: 'Could not connect to chat.\n${sessionAsync.error}',
        onRetry: () => ref.invalidate(chatSessionProvider),
      );
    }
    if (me == null || threadsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final threads = (threadsAsync.value ?? [])
        .where((t) =>
            _query.isEmpty ||
            t.displayTitle(me.id).toLowerCase().contains(_query))
        .toList();

    if (threads.isEmpty) {
      return _Message(
        icon: Icons.chat_bubble_outline_rounded,
        text: _query.isEmpty
            ? 'No conversations yet.\nTap ✎ to message a teammate.'
            : 'No chats match "$_query"',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 12, bottom: 90),
      itemCount: threads.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 76, color: Color(0xFFEDEFF3)),
      itemBuilder: (context, i) => _ThreadTile(thread: threads[i], myId: me.id),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final String myId;

  const _ThreadTile({required this.thread, required this.myId});

  @override
  Widget build(BuildContext context) {
    final unread = thread.unreadFor(myId);
    final title = thread.displayTitle(myId);
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        RoutesName.chatroom,
        arguments: thread.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ChatAvatar(name: title, isGroup: thread.isGroup),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C2340),
                          ),
                        ),
                      ),
                      Text(
                        chatListTime(thread.lastSentAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: unread > 0
                              ? const Color(0xFF25A35A)
                              : Colors.grey.shade500,
                          fontWeight:
                              unread > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (thread.lastSentAt > 0) _typeIcon(),
                      Expanded(
                        child: Text(
                          thread.previewFor(myId),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: unread > 0
                                ? const Color(0xFF1C2340)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      UnreadBadge(count: unread),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon() {
    final icon = switch (thread.lastType) {
      ChatMessageType.text => null,
      ChatMessageType.image => Icons.photo_rounded,
      ChatMessageType.voice => Icons.mic_rounded,
      ChatMessageType.file => Icons.insert_drive_file_rounded,
    };
    if (icon == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, size: 15, color: Colors.grey.shade500),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  const _Message({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
