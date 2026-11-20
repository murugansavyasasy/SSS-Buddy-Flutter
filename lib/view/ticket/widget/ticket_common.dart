import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Values/Colors/app_colors.dart';
import '../../../auth/model/TicketModel.dart';
import '../../../components/glass_card.dart';
import '../../../viewModel/ticket_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────
// Tokens (home "glass" palette)
// ─────────────────────────────────────────────────────────────────────────

const ticketPageBg = HomeGlass.bg;
const ticketInk = HomeGlass.ink;
const ticketSubtle = HomeGlass.muted;
const ticketBorder = HomeGlass.line;

const _openC = HomeGlass.blue;
const _progressC = HomeGlass.orange;
const _doneC = HomeGlass.green;

Color ticketStatusColor(TicketStatus s) => switch (s) {
      TicketStatus.open => _openC,
      TicketStatus.inProgress => _progressC,
      TicketStatus.completed => _doneC,
    };

/// (background, foreground) for a status.
(Color, Color) ticketStatusColors(TicketStatus s) {
  final c = ticketStatusColor(s);
  return (homePastel(c), homeDeep(c));
}

IconData ticketStatusIcon(TicketStatus s) => switch (s) {
      TicketStatus.open => Icons.radio_button_unchecked_rounded,
      TicketStatus.inProgress => Icons.timelapse_rounded,
      TicketStatus.completed => Icons.check_circle_rounded,
    };

Color ticketPriorityColor(TicketPriority p) => switch (p) {
      TicketPriority.low => const Color(0xFF64748B),
      TicketPriority.medium => const Color(0xFFD97706),
      TicketPriority.high => const Color(0xFFDC2626),
    };

String ticketPriorityHint(TicketPriority p) => switch (p) {
      TicketPriority.low => 'Can wait',
      TicketPriority.medium => 'Fix soon',
      TicketPriority.high => 'Blocking work',
    };

/// Colour + icon per company app.
(Color, IconData) ticketAppStyle(String app) => switch (app) {
      'School Chimes' => (const Color(0xFF2563EB), Icons.notifications_active_rounded),
      'Gradit' => (const Color(0xFF7C3AED), Icons.school_rounded),
      "Let's Reach" => (const Color(0xFF0D9488), Icons.campaign_rounded),
      'SSS Score' => (const Color(0xFFEA580C), Icons.insights_rounded),
      _ => (const Color(0xFF64748B), Icons.apps_rounded),
    };

String formatTicketTime(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final d = now.difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1 && t.day == now.day) return 'Today, ${DateFormat('h:mm a').format(t)}';
  if (t.year == now.year) return DateFormat('d MMM, h:mm a').format(t);
  return DateFormat('d MMM yyyy').format(t);
}

String ticketInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

const ticketTitleStyle =
    TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ticketInk, height: 1.3);
const ticketBodyStyle = TextStyle(fontSize: 13, color: ticketSubtle, height: 1.45);
const ticketSectionStyle = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700, color: ticketSubtle, letterSpacing: 0.6);

// ─────────────────────────────────────────────────────────────────────────
// Small pieces
// ─────────────────────────────────────────────────────────────────────────

/// Rounded square with the app's icon on its pastel colour.
class TicketAppAvatar extends StatelessWidget {
  final String app;
  final double size;
  const TicketAppAvatar({super.key, required this.app, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final (c, icon) = ticketAppStyle(app);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: homePastelGradient(c),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: c.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: homeDeep(c), size: size * 0.5),
    );
  }
}

class TicketStatusBadge extends StatelessWidget {
  final TicketStatus status;
  final bool large;
  const TicketStatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = ticketStatusColors(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 9, vertical: large ? 6 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ticketStatusIcon(status), size: large ? 15 : 12, color: fg),
          const SizedBox(width: 5),
          Text(status.label,
              style: TextStyle(
                  fontSize: large ? 13 : 11, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

class TicketPriorityTag extends StatelessWidget {
  final TicketPriority priority;
  const TicketPriorityTag({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final c = ticketPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: c),
          const SizedBox(width: 3),
          Text(priority.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
        ],
      ),
    );
  }
}

/// Initials circle for a person.
class TicketPersonAvatar extends StatelessWidget {
  final String name;
  final double size;
  const TicketPersonAvatar({super.key, required this.name, this.size = 22});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.tint, shape: BoxShape.circle),
        child: Text(ticketInitials(name),
            style: TextStyle(
                fontSize: size * 0.42, fontWeight: FontWeight.w700, color: AppColors.primary)),
      );
}

/// Open → In Progress → Completed, with the current step highlighted.
class TicketProgress extends StatelessWidget {
  final TicketStatus status;
  final bool onDark;
  const TicketProgress({super.key, required this.status, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final current = status.index;
    final idle = onDark ? Colors.white.withValues(alpha: 0.35) : ticketBorder;
    final active = onDark ? Colors.white : ticketStatusColor(status);
    Widget dot(int i) {
      final on = i <= current;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: on ? active : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: on ? active : idle, width: 2),
        ),
        child: on
            ? Icon(i < current || status == TicketStatus.completed ? Icons.check_rounded : Icons.circle,
                size: i < current || status == TicketStatus.completed ? 15 : 8,
                color: onDark ? ticketStatusColor(status) : Colors.white)
            : null,
      );
    }

    Widget line(int i) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 2.5,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: i < current ? active : idle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

    final labelStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: onDark ? Colors.white.withValues(alpha: 0.9) : ticketSubtle,
    );
    return Column(
      children: [
        Row(children: [dot(0), line(0), dot(1), line(1), dot(2)]),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: Text('Open', style: labelStyle)),
            Expanded(child: Text('In Progress', textAlign: TextAlign.center, style: labelStyle)),
            Expanded(child: Text('Completed', textAlign: TextAlign.end, style: labelStyle)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Attachments
// ─────────────────────────────────────────────────────────────────────────

/// Image from an S3 URL, or a local file in demo mode.
class TicketImage extends StatelessWidget {
  final String source;
  final double? height;
  final double? width;
  final BoxFit fit;
  const TicketImage({
    super.key,
    required this.source,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final broken = Container(
      height: height,
      width: width,
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: ticketSubtle),
    );
    return source.startsWith('http')
        ? Image.network(source,
            height: height, width: width, fit: fit, errorBuilder: (_, __, ___) => broken)
        : Image.file(File(source),
            height: height, width: width, fit: fit, errorBuilder: (_, __, ___) => broken);
  }
}

/// Square tile for an attached image (thumbnail) or video (play icon).
class TicketAttachmentTile extends StatelessWidget {
  final TicketAttachment attachment;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const TicketAttachmentTile({
    super.key,
    required this.attachment,
    this.size = 96,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final a = attachment;
    final small = size < 60;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: a.isVideo ? HomeGlass.navy : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(small ? 8 : 14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: a.isVideo
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill_rounded,
                              color: Colors.white, size: small ? 18 : 34),
                          if (!small) ...[
                            const SizedBox(height: 4),
                            const Text('Video',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ],
                      )
                    : TicketImage(source: a.url, width: size, height: size),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, color: Colors.white, size: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Image: full-screen zoomable viewer. Video: the phone's video player
/// (S3 link) or file viewer (demo mode).
Future<void> openTicketAttachment(BuildContext context, TicketAttachment a) async {
  if (!a.isVideo) {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: TicketImage(source: a.url, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    return;
  }
  final uri = a.url.startsWith('http') ? Uri.parse(a.url) : Uri.file(a.url);
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the video')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// List card
// ─────────────────────────────────────────────────────────────────────────

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool showRaisedBy;
  final VoidCallback onTap;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
    this.showRaisedBy = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final statusC = ticketStatusColor(t.status);
    final note = t.status == TicketStatus.completed ? t.latestNote : '';
    return SoftCard(
      radius: 18,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status stripe
            Container(width: 4, color: statusC),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TicketAppAvatar(app: t.app, size: 38),
                        const SizedBox(width: 10),
                        // Title gets the full width; the status sits on the
                        // id line so narrow phones don't cut the app name.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.app,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ticketTitleStyle),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        '${t.displayId} · ${formatTicketTime(t.createdAt)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11.5, color: ticketSubtle)),
                                  ),
                                  const SizedBox(width: 6),
                                  TicketStatusBadge(status: t.status),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (t.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(t.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: ticketInk, height: 1.4)),
                    ],
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: homePastel(_doneC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.task_alt_rounded, size: 15, color: homeDeep(_doneC)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: homeDeep(_doneC))),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (t.isAssigned) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.assignment_ind_outlined, size: 15, color: ticketSubtle),
                          const SizedBox(width: 6),
                          const Text('Assigned to ',
                              style: TextStyle(fontSize: 12, color: ticketSubtle)),
                          TicketPersonAvatar(name: t.assignedToName, size: 18),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(t.assignedToName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: ticketInk)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TicketPriorityTag(priority: t.priority),
                        if (t.attachments.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          for (final a in t.attachments.take(3)) ...[
                            TicketAttachmentTile(attachment: a, size: 26),
                            const SizedBox(width: 4),
                          ],
                          if (t.attachments.length > 3)
                            Text('+${t.attachments.length - 3}',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: ticketSubtle)),
                        ],
                        const Spacer(),
                        if (showRaisedBy && t.raisedByName.isNotEmpty) ...[
                          TicketPersonAvatar(name: t.raisedByName),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(t.raisedByName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: ticketInk)),
                          ),
                        ] else
                          const Icon(Icons.chevron_right_rounded, color: ticketSubtle),
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
}

/// Pastel count card used as a status filter on the list.
class TicketStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const TicketStatCard({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final deep = homeDeep(color);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? deep : Colors.transparent, width: 1.6),
      ),
      child: SoftCard(
        radius: 17,
        gradient: homePastelGradient(color),
        borderColor: color.withValues(alpha: 0.15),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: deep),
                const Spacer(),
                if (selected) Icon(Icons.filter_alt_rounded, size: 14, color: deep),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: count),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text('$v',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: deep, height: 1)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label,
                  maxLines: 1,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: deep)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-option pill switch (e.g. All tickets / Raised by me).
class TicketPillSwitch extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const TicketPillSwitch({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ticketBorder),
        ),
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: w * selected,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: i == selected ? Colors.white : ticketSubtle,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(labels[i], maxLines: 1, textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        }),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Assignee picker
// ─────────────────────────────────────────────────────────────────────────

/// Result of [pickTicketAssignee]: `to` is the person, or null to unassign.
typedef AssigneeChoice = ({TicketAssignee? to});

/// Searchable list of people (reporting members, "Me" first). Returns null
/// when dismissed.
Future<AssigneeChoice?> pickTicketAssignee(
  BuildContext context, {
  String currentId = '',
  bool allowUnassign = true,
}) =>
    showModalBottomSheet<AssigneeChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssigneeSheet(currentId: currentId, allowUnassign: allowUnassign),
    );

class _AssigneeSheet extends ConsumerStatefulWidget {
  final String currentId;
  final bool allowUnassign;
  const _AssigneeSheet({required this.currentId, required this.allowUnassign});

  @override
  ConsumerState<_AssigneeSheet> createState() => _AssigneeSheetState();
}

class _AssigneeSheetState extends ConsumerState<_AssigneeSheet> {
  String _q = '';

  void _pick(TicketAssignee? a) {
    HapticFeedback.selectionClick();
    Navigator.pop(context, (to: a));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ticketAssigneesProvider);
    final me = ref.watch(ticketUserProvider).value;
    final h = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: h * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: ticketBorder, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('Assign ticket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ticketInk)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Anyone can assign a ticket to anyone.', style: ticketBodyStyle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search people',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: ticketPageBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: TextButton.icon(
                    onPressed: () => ref.invalidate(ticketAssigneesProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Couldn't load people · Retry"),
                  ),
                ),
                data: (people) {
                  final list = _q.isEmpty
                      ? people
                      : people.where((p) => p.name.toLowerCase().contains(_q)).toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                    children: [
                      if (widget.allowUnassign && widget.currentId.isNotEmpty && _q.isEmpty)
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFDECEC),
                            child: Icon(Icons.person_off_outlined, color: AppColors.danger, size: 20),
                          ),
                          title: const Text('Unassign',
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
                          onTap: () => _pick(null),
                        ),
                      for (final p in list)
                        ListTile(
                          leading: TicketPersonAvatar(name: p.name, size: 40),
                          title: Text(
                            me != null && p.id == me.id ? '${p.name} (Me)' : p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: ticketInk),
                          ),
                          trailing: p.id == widget.currentId
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                              : null,
                          onTap: () => _pick(p),
                        ),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No one matches that name.',
                              textAlign: TextAlign.center, style: ticketBodyStyle),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
