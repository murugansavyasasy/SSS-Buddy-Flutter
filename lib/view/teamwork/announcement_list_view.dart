import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/TeamWorkModel.dart';
import '../../components/app_motion.dart';
import '../../components/glass_card.dart';
import '../../core/notifications/local_notifications.dart';
import '../../viewModel/teamwork_viewmodel.dart';
import '../ticket/widget/ticket_common.dart' show TicketPersonAvatar;
import 'widget/teamwork_common.dart';

/// Team announcements. Admin posts; everyone reads. Opening the screen
/// marks them read.
class AnnouncementListView extends ConsumerStatefulWidget {
  const AnnouncementListView({super.key});

  @override
  ConsumerState<AnnouncementListView> createState() => _AnnouncementListViewState();
}

class _AnnouncementListViewState extends ConsumerState<AnnouncementListView> {
  /// Unread when the screen opened (keeps the "New" tag until leaving).
  Set<String>? _newIds;

  @override
  void initState() {
    super.initState();
    LocalNotifications.instance.activeScreen = 'announcements';
  }

  @override
  void dispose() {
    if (LocalNotifications.instance.activeScreen == 'announcements') {
      LocalNotifications.instance.activeScreen = null;
    }
    super.dispose();
  }

  Future<void> _post() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _PostSheet(),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement posted.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(announcementsProvider);
    final isAdmin = ref.watch(teamWorkUserProvider).value?.isAdmin ?? false;
    final read = ref.watch(announcementReadProvider);

    return TeamPage(
      title: 'Announcements',
      onRefresh: () => ref.invalidate(announcementsProvider),
      fab: isAdmin ? TeamFab(label: 'Post', icon: Icons.campaign_rounded, onPressed: _post) : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            TeamStateView.error(e, title: "Couldn't load announcements", onRetry: () => ref.invalidate(announcementsProvider)),
        data: (items) {
          final readIds = read.value;
          if (readIds != null && _newIds == null) {
            _newIds = items.map((a) => a.id).where((id) => !readIds.contains(id)).toSet();
            if (_newIds!.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => ref.read(announcementReadProvider.notifier).markRead(items.map((a) => a.id)));
            }
          }
          if (items.isEmpty) {
            return TeamStateView(
              icon: Icons.campaign_outlined,
              color: const Color(0xFFDB2777),
              title: 'No announcements yet',
              message: isAdmin ? 'Post an update for the whole team.' : 'Updates from your lead will show here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(announcementsProvider),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => AppEntrance(
                    index: i.clamp(0, 8),
                    child: _AnnouncementCard(a: items[i], isNew: _newIds?.contains(items[i].id) ?? false),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement a;
  final bool isNew;
  const _AnnouncementCard({required this.a, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final c = a.important ? AppColors.danger : const Color(0xFFDB2777);
    return SoftCard(
      radius: 20,
      padding: EdgeInsets.zero,
      borderColor: a.important ? c.withValues(alpha: 0.35) : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (a.important)
                          _tag('IMPORTANT', c, Icons.priority_high_rounded)
                        else
                          _tag('UPDATE', c, Icons.campaign_rounded),
                        if (isNew) ...[const SizedBox(width: 6), _tag('NEW', HomeGlass.blue, Icons.fiber_new_rounded)],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(a.title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: teamInk)),
                    if (a.body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(a.body, style: const TextStyle(fontSize: 14, color: teamInk, height: 1.5)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TicketPersonAvatar(name: a.byName, size: 22),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(a.byName.isEmpty ? 'Team lead' : a.byName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: teamSubtle)),
                        ),
                        Text(teamDateTime(a.createdAt), style: const TextStyle(fontSize: 11.5, color: teamSubtle)),
                      ],
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

  Widget _tag(String text, Color c, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: homePastel(c), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: homeDeep(c)),
            const SizedBox(width: 3),
            Text(text, style: TextStyle(fontSize: 10, letterSpacing: 0.6, fontWeight: FontWeight.w800, color: homeDeep(c))),
          ],
        ),
      );
}

class _PostSheet extends ConsumerStatefulWidget {
  const _PostSheet();

  @override
  ConsumerState<_PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends ConsumerState<_PostSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _important = false;
  bool _tried = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    setState(() => _tried = true);
    if (_title.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(teamWorkActionsProvider)
          .postAnnouncement(title: _title.text.trim(), body: _body.text.trim(), important: _important);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                      width: 40, height: 4, decoration: BoxDecoration(color: teamBorder, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                const Text('New announcement', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: teamInk)),
                const SizedBox(height: 14),
                TeamFormField(
                  label: 'Title',
                  error: _tried && _title.text.trim().isEmpty ? 'Title is required' : null,
                  child: TextField(
                    controller: _title,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _tried ? setState(() {}) : null,
                    decoration: teamInput('e.g. Release freeze on Friday'),
                  ),
                ),
                TeamFormField(
                  label: 'Message',
                  child: TextField(
                    controller: _body,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: teamInput('Write the details for the team...'),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _important,
                  onChanged: (v) => setState(() => _important = v),
                  title: const Text('Mark as important', style: TextStyle(fontWeight: FontWeight.w700, color: teamInk)),
                  subtitle: const Text('Highlighted in red for everyone', style: TextStyle(fontSize: 12.5)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _post,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: Text(_saving ? 'Posting…' : 'Post to team',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
