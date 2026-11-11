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

class NewChatView extends ConsumerStatefulWidget {
  const NewChatView({super.key});

  @override
  ConsumerState<NewChatView> createState() => _NewChatViewState();
}

class _NewChatViewState extends ConsumerState<NewChatView> {
  String _query = '';
  bool _opening = false;

  Future<void> _open(ChatContact c) async {
    final me = ref.read(chatSessionProvider).value;
    if (me == null || _opening) return;
    setState(() => _opening = true);
    try {
      final id = await ChatService.instance.ensureDirectChat(me, c);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RoutesName.chatroom, arguments: id);
    } catch (e) {
      if (mounted) {
        setState(() => _opening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start chat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(chatContactsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(
              title: 'New Chat',
              searchHint: 'Search people...',
              onSearch: (q) => setState(() => _query = q.trim().toLowerCase()),
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
                child: Stack(
                  children: [
                    contactsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: _list,
                    ),
                    if (_opening)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Colors.white54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<ChatContact> contacts) {
    final filtered = contacts
        .where((c) => _query.isEmpty || c.name.toLowerCase().contains(_query))
        .toList();
    final team = filtered.where((c) => c.isTeamMember).toList();
    final others = filtered.where((c) => !c.isTeamMember).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty ? 'No colleagues found' : 'No one matches "$_query"',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        if (team.isNotEmpty) ...[
          _section('My Team'),
          ...team.map(_tile),
        ],
        if (others.isNotEmpty) ...[
          _section('Colleagues'),
          ...others.map(_tile),
        ],
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );

  Widget _tile(ChatContact c) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: ChatAvatar(name: c.name, size: 44),
        title: Text(
          c.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: c.role.isNotEmpty ? Text(c.role) : null,
        onTap: () => _open(c),
      );
}
