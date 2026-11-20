import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/TicketModel.dart';
import '../../components/app_motion.dart';
import '../../components/form_width.dart';
import '../../components/glass_card.dart';
import '../../components/toolbar_layout.dart';
import '../../viewModel/ticket_viewmodel.dart';
import 'widget/ticket_common.dart';

/// One ticket: status progress, details, images / videos, timeline.
/// Admin / Support get an action bar to move the status on.
class TicketDetailView extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailView({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailView> createState() => _TicketDetailViewState();
}

class _TicketDetailViewState extends ConsumerState<TicketDetailView> {
  bool _updating = false;

  /// The usual next step for a ticket.
  TicketStatus _next(TicketStatus s) => switch (s) {
        TicketStatus.open => TicketStatus.inProgress,
        TicketStatus.inProgress => TicketStatus.completed,
        TicketStatus.completed => TicketStatus.open,
      };

  String _actionLabel(Ticket t, TicketStatus to) => switch (to) {
        TicketStatus.inProgress => 'Start work',
        TicketStatus.completed => 'Mark completed',
        TicketStatus.open => t.status == TicketStatus.completed ? 'Reopen' : 'Move to Open',
      };

  IconData _actionIcon(TicketStatus to) => switch (to) {
        TicketStatus.inProgress => Icons.play_arrow_rounded,
        TicketStatus.completed => Icons.task_alt_rounded,
        TicketStatus.open => Icons.replay_rounded,
      };

  Future<void> _changeStatus(Ticket t, TicketStatus to) async {
    final note = await _askNote(t, to);
    if (note == null || !mounted) return;
    setState(() => _updating = true);
    try {
      await ref.read(ticketActionsProvider).changeStatus(t, to, note: note);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(to == TicketStatus.completed
            ? 'Marked Completed. ${t.raisedByName.isEmpty ? 'The user' : t.raisedByName} will be notified.'
            : 'Status changed to ${to.label}'),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// Bottom sheet with an optional note. Null = cancelled.
  Future<String?> _askNote(Ticket t, TicketStatus to) {
    final c = TextEditingController();
    final color = ticketStatusColor(to);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: homePastelGradient(color),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_actionIcon(to), color: homeDeep(color)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_actionLabel(t, to),
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700, color: ticketInk)),
                        Text('${t.displayId} · ${t.app}',
                            style: const TextStyle(fontSize: 12.5, color: ticketSubtle)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: c,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: to == TicketStatus.completed
                      ? 'What was fixed? (optional, sent to ${t.raisedByName.isEmpty ? 'the user' : t.raisedByName})'
                      : 'Add a note (optional)',
                  filled: true,
                  fillColor: ticketPageBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: homeDeep(color),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, c.text.trim()),
                  icon: Icon(_actionIcon(to)),
                  label: Text(_actionLabel(t, to),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ticketsProvider);
    final user = ref.watch(ticketUserProvider).value;
    final ticket = async.value?.where((x) => x.id == widget.ticketId).firstOrNull;
    final canChange = ticket != null && canChangeTicketStatus(ticket, user);

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
              title: ticket == null ? 'Ticket' : 'Ticket ${ticket.displayId}',
              onRefresh: () => ref.invalidate(ticketsProvider),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: ticketPageBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _message(e.toString()),
                  data: (_) => ticket == null
                      ? _message('Ticket not found.')
                      : Column(
                          children: [
                            Expanded(child: _content(ticket)),
                            if (canChange) _actionBar(ticket),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, textAlign: TextAlign.center, style: ticketBodyStyle),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(ticketsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _section(String title, {String? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Row(
          children: [
            Text(title.toUpperCase(), style: ticketSectionStyle),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Text('· $trailing', style: ticketSectionStyle),
            ],
          ],
        ),
      );

  Widget _content(Ticket t) {
    final pad = formSidePadding(context, 16);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final info = <(IconData, String, String)>[
      (Icons.flag_rounded, 'Priority', t.priority.label),
      (Icons.schedule_rounded, 'Raised on', formatTicketTime(t.createdAt)),
      (Icons.person_rounded, 'Raised by', t.raisedByName.isEmpty ? '-' : t.raisedByName),
      if (t.deviceLabel.isNotEmpty) (Icons.phone_iphone_rounded, 'Device', t.deviceLabel),
    ];

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(ticketsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
        children: [
          AppEntrance(child: _hero(t)),
          const SizedBox(height: 14),
          AppEntrance(
            index: 1,
            child: LayoutBuilder(builder: (context, box) {
              final cols = wide ? 4 : 2;
              final w = (box.maxWidth - (cols - 1) * 10) / cols;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (icon, label, value) in info)
                    SizedBox(width: w, child: _infoTile(t, icon, label, value)),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          AppEntrance(index: 2, child: _assigneeTile(t)),
          if (t.description.isNotEmpty) ...[
            _section('Description'),
            AppEntrance(
              index: 2,
              child: SoftCard(
                radius: 18,
                child: SelectableText(t.description,
                    style: const TextStyle(fontSize: 14.5, height: 1.55, color: ticketInk)),
              ),
            ),
          ],
          if (t.attachments.isNotEmpty) ...[
            _section('Images / Videos', trailing: '${t.attachments.length}'),
            AppEntrance(
              index: 3,
              child: LayoutBuilder(builder: (context, box) {
                final cols = wide ? 5 : 3;
                final size = (box.maxWidth - (cols - 1) * 10) / cols;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final a in t.attachments)
                      PressableScale(
                        child: TicketAttachmentTile(
                          attachment: a,
                          size: size,
                          onTap: () => openTicketAttachment(context, a),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
          if (t.history.isNotEmpty) ...[
            _section('Activity'),
            AppEntrance(
              index: 4,
              child: SoftCard(
                radius: 18,
                child: Column(
                  children: [
                    for (var i = t.history.length - 1; i >= 0; i--)
                      _historyRow(t.history[i], first: i == 0, latest: i == t.history.length - 1),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Status-coloured header with the app, ticket id and progress stepper.
  Widget _hero(Ticket t) {
    final c = ticketStatusColor(t.status);
    final deep = homeDeep(c);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deep, Color.lerp(c, Colors.white, 0.1)!],
        ),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TicketAppAvatar(app: t.app, size: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.app,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(t.displayId,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ticketStatusIcon(t.status), size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(t.status.label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TicketProgress(status: t.status, onDark: true),
          if (t.status == TicketStatus.completed && t.latestNote.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.task_alt_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.latestNote,
                        style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(Ticket t, IconData icon, String label, String value) {
    final c = label == 'Priority' ? ticketPriorityColor(t.priority) : AppColors.primary;
    return SoftCard(
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: ticketSubtle)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: ticketInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(TicketHistory h, {required bool first, required bool latest}) {
    final c = h.isAssign ? AppColors.accent : ticketStatusColor(h.status);
    final title = first
        ? 'Ticket raised'
        : h.isAssign
            ? (h.assignedToName.isEmpty ? 'Unassigned' : 'Assigned to ${h.assignedToName}')
            : 'Moved to ${h.status.label}';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: latest ? homeDeep(c) : homePastel(c),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    first
                        ? Icons.add_rounded
                        : h.isAssign
                            ? Icons.assignment_ind_rounded
                            : ticketStatusIcon(h.status),
                    size: 16, color: latest ? Colors.white : homeDeep(c)),
              ),
              if (!first)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: ticketBorder,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: first ? 0 : 18, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700, color: ticketInk)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (h.byName.isNotEmpty) ...[
                        TicketPersonAvatar(name: h.byName, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(h.byName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: ticketInk)),
                        ),
                        const Text('  ·  ', style: TextStyle(fontSize: 12, color: ticketSubtle)),
                      ],
                      Text(formatTicketTime(h.at),
                          style: const TextStyle(fontSize: 12, color: ticketSubtle)),
                    ],
                  ),
                  if (h.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: ticketPageBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(h.note,
                          style: const TextStyle(fontSize: 13, height: 1.4, color: ticketInk)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _assign(Ticket t) async {
    final choice = await pickTicketAssignee(context, currentId: t.assignedToId);
    if (choice == null || !mounted) return;
    if (choice.to?.id == t.assignedToId && choice.to != null) return;
    try {
      await ref.read(ticketActionsProvider).assign(t, choice.to);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(choice.to == null ? 'Ticket unassigned' : 'Assigned to ${choice.to!.name}'),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Who is working on it; anyone can assign or change it.
  Widget _assigneeTile(Ticket t) => SoftCard(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        onTap: () => _assign(t),
        child: Row(
          children: [
            t.isAssigned
                ? TicketPersonAvatar(name: t.assignedToName, size: 34)
                : Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: AppColors.accent),
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assigned to', style: TextStyle(fontSize: 11, color: ticketSubtle)),
                  const SizedBox(height: 2),
                  Text(t.isAssigned ? t.assignedToName : 'Not assigned yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: t.isAssigned ? ticketInk : ticketSubtle)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _assign(t),
              icon: Icon(t.isAssigned ? Icons.swap_horiz_rounded : Icons.person_add_alt_1_rounded,
                  size: 18),
              label: Text(t.isAssigned ? 'Change' : 'Assign'),
            ),
          ],
        ),
      );

  /// Admin / Support / assignee: main next-step button + the other status.
  Widget _actionBar(Ticket t) {
    final next = _next(t.status);
    final others = TicketStatus.values.where((s) => s != t.status && s != next).toList();
    final c = ticketStatusColor(next);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ticketBorder)),
        boxShadow: [BoxShadow(color: Color(0x0F111827), blurRadius: 16, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(
        formSidePadding(context, 16),
        12,
        formSidePadding(context, 16),
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _updating
            ? const SizedBox(
                key: ValueKey('updating'),
                height: 52,
                child: Center(child: CircularProgressIndicator()),
              )
            : Row(
                key: ValueKey(t.status),
                children: [
                  for (final o in others) ...[
                    PressableScale(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: homeDeep(ticketStatusColor(o)),
                            side: BorderSide(color: ticketStatusColor(o).withValues(alpha: 0.4)),
                            shape:
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _changeStatus(t, o),
                          icon: Icon(_actionIcon(o), size: 18),
                          label: Text(_actionLabel(t, o)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: PressableScale(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: homeDeep(c),
                            foregroundColor: Colors.white,
                            shape:
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _changeStatus(t, next),
                          icon: Icon(_actionIcon(next)),
                          label: Text(_actionLabel(t, next),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
