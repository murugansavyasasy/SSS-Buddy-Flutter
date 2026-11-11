import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/FollowUpModel.dart';
import '../../components/toolbar_layout.dart';
import '../../core/notifications/local_notifications.dart';
import '../../utils/routes/routes_name.dart';
import '../../viewModel/followup_viewmodel.dart';
import 'widget/followup_card.dart';
import 'widget/followup_common.dart';
import 'widget/followup_sheets.dart';

enum _Tab { overdue, today, upcoming, done }

class FollowUpListView extends ConsumerStatefulWidget {
  const FollowUpListView({super.key});

  @override
  ConsumerState<FollowUpListView> createState() => _FollowUpListViewState();
}

class _FollowUpListViewState extends ConsumerState<FollowUpListView> {
  _Tab? _tab;
  String _query = '';

  @override
  void initState() {
    super.initState();
    LocalNotifications.instance.activeScreen = 'followups';
  }

  @override
  void dispose() {
    if (LocalNotifications.instance.activeScreen == 'followups') {
      LocalNotifications.instance.activeScreen = null;
    }
    super.dispose();
  }

  Map<_Tab, List<FollowUp>> _group(List<FollowUp> all) {
    final q = _query;
    final items = all.where((f) =>
        q.isEmpty ||
        f.schoolName.toLowerCase().contains(q) ||
        f.contactName.toLowerCase().contains(q) ||
        f.contactPhone.contains(q));
    final g = {for (final t in _Tab.values) t: <FollowUp>[]};
    for (final f in items) {
      if (f.status == FollowUpStatus.done) {
        g[_Tab.done]!.add(f);
      } else if (f.status == FollowUpStatus.pending) {
        if (f.isOverdue) {
          g[_Tab.overdue]!.add(f);
        } else if (f.isToday) {
          g[_Tab.today]!.add(f);
        } else {
          g[_Tab.upcoming]!.add(f);
        }
      }
    }
    // Most recently completed first.
    g[_Tab.done]!.sort((a, b) => (b.completedAt ?? b.dueAt)
        .compareTo(a.completedAt ?? a.dueAt));
    return g;
  }

  Future<void> _call(FollowUp f) async {
    final uri = Uri(scheme: 'tel', path: f.contactPhone.trim());
    await launchUrl(uri);
  }

  void _openForm([FollowUp? f]) => Navigator.pushNamed(
        context,
        RoutesName.followupform,
        arguments: FollowUpFormArgs(existing: f),
      );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(followUpProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Follow-up'),
        ),
        body: Column(
          children: [
            ToolbarLayout(
              title: 'Follow-ups',
              searchHint: 'Search school, contact...',
              onSearch: (q) => setState(() => _query = q.trim().toLowerCase()),
              onRefresh: () => ref.invalidate(followUpProvider),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (all) => _content(all),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(List<FollowUp> all) {
    final groups = _group(all);
    // Default to the most urgent non-empty tab.
    final tab = _tab ??
        (groups[_Tab.overdue]!.isNotEmpty
            ? _Tab.overdue
            : groups[_Tab.today]!.isNotEmpty
                ? _Tab.today
                : _Tab.upcoming);
    final items = groups[tab]!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Row(
            children: [
              _tabTile(_Tab.overdue, 'Overdue', overdueColor, groups, tab),
              _tabTile(_Tab.today, 'Today', todayColor, groups, tab),
              _tabTile(_Tab.upcoming, 'Upcoming', upcomingColor, groups, tab),
              _tabTile(_Tab.done, 'Done', doneColor, groups, tab),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _empty(tab, all.isEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final f = items[i];
                    return FollowUpCard(
                      item: f,
                      onTap: () => _openForm(f),
                      onCall: () => _call(f),
                      onDone: () => showCompleteSheet(context, ref, f),
                      onReschedule: () => showRescheduleSheet(context, ref, f),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _tabTile(_Tab t, String label, Color color,
      Map<_Tab, List<FollowUp>> groups, _Tab current) {
    final selected = t == current;
    final count = groups[t]!.length;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _tab = t),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected ? color : color.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(_Tab tab, bool nothingAtAll) {
    final text = nothingAtAll
        ? 'No follow-ups yet.\nAdd one after a demo or school visit so you never miss a call back.'
        : _query.isNotEmpty
            ? 'Nothing matches "$_query"'
            : switch (tab) {
                _Tab.overdue => 'Nothing overdue. Nice work!',
                _Tab.today => 'No follow-ups due today.',
                _Tab.upcoming => 'No upcoming follow-ups.',
                _Tab.done => 'No completed follow-ups yet.',
              };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab == _Tab.overdue && !nothingAtAll
                  ? Icons.celebration_outlined
                  : Icons.event_available_outlined,
              size: 58,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
