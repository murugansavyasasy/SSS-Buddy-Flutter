import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/TicketModel.dart';
import '../../components/ResponsiveCardList.dart';
import '../../components/app_motion.dart';
import '../../components/glass_card.dart';
import '../../components/toolbar_layout.dart';
import '../../utils/routes/routes_name.dart';
import '../../viewModel/ticket_viewmodel.dart';
import 'widget/ticket_common.dart';

/// Tickets: everyone raises tickets for app issues; Admin / Support see all
/// tickets and change their status.
class TicketListView extends ConsumerStatefulWidget {
  const TicketListView({super.key});

  @override
  ConsumerState<TicketListView> createState() => _TicketListViewState();
}

class _TicketListViewState extends ConsumerState<TicketListView> {
  /// null = all statuses.
  TicketStatus? _status;
  /// 0 = all, 1 = raised by me, 2 = assigned to me.
  int _scope = 0;
  String _query = '';

  Future<void> _raise() async {
    final ok = await Navigator.pushNamed(context, RoutesName.ticketform);
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket raised. You will be notified when it is completed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ticketsProvider);
    final user = ref.watch(ticketUserProvider).value;
    final canManage = user?.canManage ?? false;

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
          onPressed: _raise,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Raise Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: Column(
          children: [
            ToolbarLayout(
              title: 'Tickets',
              searchHint: 'Search app, description, name...',
              onSearch: (q) => setState(() => _query = q.trim().toLowerCase()),
              onRefresh: () => ref.invalidate(ticketsProvider),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ticketPageBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _stateView(
                    icon: Icons.cloud_off_rounded,
                    color: AppColors.danger,
                    title: "Couldn't load tickets",
                    message: e.toString(),
                    action: OutlinedButton.icon(
                      onPressed: () => ref.invalidate(ticketsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                  data: (all) => _content(all, user?.id ?? '', canManage),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stateView({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    Widget? action,
  }) =>
      ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: homePastelGradient(color),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: homeDeep(color)),
            ),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ticketInk)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: ticketBodyStyle),
          if (action != null) ...[
            const SizedBox(height: 18),
            Center(child: action),
          ],
        ],
      );

  Widget _content(List<Ticket> all, String userId, bool canManage) {
    final scoped =
        switch (_scope) {
          1 => all.where((t) => t.raisedById == userId).toList(),
          2 => all.where((t) => t.assignedToId == userId).toList(),
          _ => all,
        };
    final q = _query;
    final searched = q.isEmpty
        ? scoped
        : scoped
            .where((t) =>
                t.app.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q) ||
                t.raisedByName.toLowerCase().contains(q) ||
                t.displayId.contains(q))
            .toList();
    int count(TicketStatus s) => searched.where((t) => t.status == s).length;
    final items = _status == null ? searched : searched.where((t) => t.status == _status).toList();

    Widget stat(TicketStatus s, String label) => Expanded(
          child: TicketStatCard(
            label: label,
            count: count(s),
            color: ticketStatusColor(s),
            icon: ticketStatusIcon(s),
            selected: _status == s,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _status = _status == s ? null : s);
            },
          ),
        );

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Everyone: tickets they can see / raised / are assigned.
          TicketPillSwitch(
            labels: const ['All', 'Raised by me', 'Assigned to me'],
            selected: _scope,
            onChanged: (i) => setState(() => _scope = i),
          ),
          const SizedBox(height: 14),
          AppEntrance(
            child: Row(
              children: [
                stat(TicketStatus.open, 'Open'),
                const SizedBox(width: 10),
                stat(TicketStatus.inProgress, 'In Progress'),
                const SizedBox(width: 10),
                stat(TicketStatus.completed, 'Completed'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                (_status == null ? 'ALL TICKETS' : _status!.label.toUpperCase()),
                style: ticketSectionStyle,
              ),
              const SizedBox(width: 6),
              Text('· ${items.length}', style: ticketSectionStyle),
              const Spacer(),
              if (_status != null)
                GestureDetector(
                  onTap: () => setState(() => _status = null),
                  child: const Text('Clear filter',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
            ],
          ),
        ],
      ),
    );

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(ticketsProvider),
      child: Column(
        children: [
          header,
          Expanded(
            child: items.isEmpty
                ? _stateView(
                    icon: all.isEmpty
                        ? Icons.confirmation_number_outlined
                        : Icons.inbox_outlined,
                    color: AppColors.primary,
                    title: all.isEmpty ? 'No tickets yet' : 'Nothing here',
                    message: all.isEmpty
                        ? 'Found an issue in School Chimes, Gradit, Let\'s Reach or SSS Score? Raise a ticket and we\'ll let you know when it\'s fixed.'
                        : 'No tickets match this filter.',
                    action: all.isEmpty
                        ? ElevatedButton.icon(
                            onPressed: _raise,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Raise Ticket'),
                          )
                        : null,
                  )
                : ResponsiveCardList(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                    itemCount: items.length,
                    spacing: 12,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (_, i) => TicketCard(
                      ticket: items[i],
                      showRaisedBy: canManage,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RoutesName.ticketdetail,
                        arguments: items[i].id,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
