import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/model/ExhibitionModel.dart';
import '../../core/exhibition/demo_templates.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'give_demo_view.dart';
import 'widget/exhibition_common.dart';
import 'widget/exhibition_sheets.dart';

/// Phone route: "‹ Exhibitions" back row over the detail pane.
class ExhibitionDetailView extends StatelessWidget {
  final String exhibitionId;
  final Exhibition? initial;

  const ExhibitionDetailView({super.key, required this.exhibitionId, this.initial});

  @override
  Widget build(BuildContext context) => ExPage(
        title: 'Exhibitions',
        largeTitle: false,
        headerDivider: false,
        body: ExhibitionDetailPane(exhibitionId: exhibitionId, initial: initial),
      );
}

/// The hub of one exhibition: info, attendees, Give New Demo, and the
/// Demos / Leads tabs. Leads belong to the exhibition and are one list.
/// Phone: full-bleed white header. iPad split ([embedded]): header card.
class ExhibitionDetailPane extends ConsumerStatefulWidget {
  final String exhibitionId;
  final Exhibition? initial;
  final bool embedded;

  const ExhibitionDetailPane({
    super.key,
    required this.exhibitionId,
    this.initial,
    this.embedded = false,
  });

  @override
  ConsumerState<ExhibitionDetailPane> createState() => _ExhibitionDetailPaneState();
}

class _ExhibitionDetailPaneState extends ConsumerState<ExhibitionDetailPane> {
  int _tab = 0; // 0 = demos, 1 = leads
  String? _newDemoId;
  String? _expandedDemoId;
  bool _highlightNewestLead = false;

  String get _id => widget.exhibitionId;

  void _refresh() => refreshExhibition(ref, _id);

  Future<void> _giveDemo(Exhibition ex, {ExhibitionDemo? resendFrom}) async {
    final res = await Navigator.push<GiveDemoResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GiveDemoView(exhibition: ex, resendFrom: resendFrom),
      ),
    );
    if (res == null || !mounted) return;
    setState(() {
      _tab = 0;
      _newDemoId = res.demoId.isEmpty ? null : res.demoId;
    });
    _refresh();

    final capture = await showDemoSentSheet(
      context,
      callCount: res.callCount,
      exhibitionName: ex.name,
    );
    if (!capture || !mounted) return;

    var demo = ExhibitionDemo(id: res.demoId, visitorName: res.visitorName);
    if (res.demoId.isEmpty) {
      // The API did not return the id: use the newest demo from the list.
      try {
        final demos = await ref.read(exhibitionDemosProvider(_id).future);
        if (demos.isNotEmpty) demo = demos.first;
      } catch (_) {}
    }
    if (!mounted) return;
    await _captureLead(
      demo: demo.id.isEmpty ? null : demo,
      contact: res.visitorName,
      number: res.firstVisitorNumber,
    );
  }

  Future<void> _captureLead({ExhibitionDemo? demo, String? contact, String? number}) async {
    final saved = await showCaptureLeadSheet(
      context,
      exhibitionId: _id,
      demo: demo,
      prefillContact: contact,
      prefillNumber: number,
    );
    if (!saved || !mounted) return;
    setState(() {
      _tab = 1;
      _highlightNewestLead = true;
    });
    _refresh();
    exToast(context, 'Interest captured');
  }

  void _toggleDemo(ExhibitionDemo d) =>
      setState(() => _expandedDemoId = _expandedDemoId == d.id ? null : d.id);

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(exhibitionDetailProvider(_id));
    final demos = ref.watch(exhibitionDemosProvider(_id));
    final leads = ref.watch(exhibitionLeadsProvider(_id));
    final ex = detail.value ?? widget.initial;

    if (ex == null) {
      return detail.hasError
          ? ExStateView.error(detail.error!,
              title: "Couldn't load exhibition", onRetry: _refresh)
          : const Center(child: CircularProgressIndicator(color: exBrandBold));
    }
    final embedded = widget.embedded;

    return LayoutBuilder(
      builder: (context, box) {
        // Measure the pane, not the screen: in the iPad split it is narrower.
        final wide = box.maxWidth >= 640;
        final pad = embedded ? 24.0 : (wide ? 24.0 : 16.0);

        final header = _Header(
          ex: ex,
          onGiveDemo: () => _giveDemo(ex),
          // Hidden for completed shows, and until the first demo
          // (the empty Demos tab offers "Give first demo").
          showGiveDemo:
              ex.status == ExhibitionStatus.active && (demos.value?.isNotEmpty ?? ex.demoCount > 0),
          loadingTeam: detail.isLoading && widget.initial != null && ex.attendees.isEmpty,
        );
        final tabs = _Tabs(
          selected: _tab,
          demoCount: demos.value?.length ?? ex.demoCount,
          leadCount: leads.value?.length ?? ex.leadCount,
          compact: embedded,
          onChanged: (i) => setState(() => _tab = i),
        );

        return RefreshIndicator(
          color: exBrandBold,
          onRefresh: () async {
            _refresh();
            await ref.read(exhibitionDetailProvider(_id).future).catchError((_) => ex);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (embedded) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: exBorder),
                      ),
                      child: header,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
                    child: tabs,
                  ),
                ),
              ] else
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        ExMaxWidth(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
                            child: header,
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: exBorder),
                              bottom: BorderSide(color: exBorder),
                            ),
                          ),
                          child: ExMaxWidth(child: tabs),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_tab == 0)
                ..._demoSlivers(demos, ex, pad)
              else
                ..._leadSlivers(leads, pad, wide && !embedded),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }

  Widget _padded(double pad, Widget child) => ExMaxWidth(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: pad), child: child),
      );

  List<Widget> _demoSlivers(AsyncValue<List<ExhibitionDemo>> demos, Exhibition ex, double pad) {
    return demos.when<List<Widget>>(
      loading: () => [
        const SliverToBoxAdapter(child: ExMaxWidth(child: ExSkeletonList(count: 2))),
      ],
      error: (e, _) => [
        SliverToBoxAdapter(
          child: ExStateView.error(
            e,
            title: "Couldn't load demos",
            message: 'Pull down to refresh or try again.',
            onRetry: () => ref.invalidate(exhibitionDemosProvider(_id)),
          ),
        ),
      ],
      data: (items) {
        if (items.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: ex.status == ExhibitionStatus.active
                  ? ExStateView(
                      icon: Icons.graphic_eq_rounded,
                      title: 'No demos yet',
                      message: 'Play a voice demo and it will appear here.',
                      actionLabel: 'Give first demo',
                      onAction: () => _giveDemo(ex),
                    )
                  : const ExStateView(
                      icon: Icons.graphic_eq_rounded,
                      title: 'No demos',
                      message: 'No demos were given at this exhibition.',
                    ),
            ),
          ];
        }
        return [
          SliverToBoxAdapter(
            child: _padded(
              pad,
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: SizedBox(
                  width: double.infinity,
                  child: Text('Newest first · tap a demo to see each call',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: exSubtle)),
                ),
              ),
            ),
          ),
          SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _padded(
              pad,
              _DemoRow(
                demo: items[i],
                isNew: _newDemoId != null && items[i].id == _newDemoId,
                expanded: _expandedDemoId == items[i].id,
                onTap: () => _toggleDemo(items[i]),
                onCaptureLead: () => _captureLead(demo: items[i]),
                onSendAgain: () => _giveDemo(ex, resendFrom: items[i]),
              ),
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _leadSlivers(AsyncValue<List<ExhibitionLead>> leads, double pad, bool twoCols) {
    final addButton = SliverToBoxAdapter(
      child: _padded(
        pad,
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _DashedButton(
            label: 'Capture Lead',
            icon: Icons.add_rounded,
            onTap: () => _captureLead(),
          ),
        ),
      ),
    );
    return leads.when<List<Widget>>(
      loading: () => [
        addButton,
        const SliverToBoxAdapter(child: ExMaxWidth(child: ExSkeletonList(count: 2))),
      ],
      error: (e, _) => [
        SliverToBoxAdapter(
          child: ExStateView.error(
            e,
            title: "Couldn't load leads",
            message: 'Pull down to refresh or try again.',
            onRetry: () => ref.invalidate(exhibitionLeadsProvider(_id)),
          ),
        ),
      ],
      data: (items) {
        if (items.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: ExStateView(
                icon: Icons.star_outline_rounded,
                title: 'No leads yet',
                message: 'Interested schools from every demo collect here.',
                actionLabel: 'Capture a lead',
                onAction: () => _captureLead(),
              ),
            ),
          ];
        }
        final perRow = twoCols ? 2 : 1;
        final rows = (items.length + perRow - 1) ~/ perRow;
        return [
          addButton,
          SliverList.separated(
            itemCount: rows,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, r) {
              Widget card(int i) => _LeadCard(lead: items[i], isNew: _highlightNewestLead && i == 0);
              return _padded(
                pad,
                perRow == 1
                    ? card(r)
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: card(r * 2)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: r * 2 + 1 < items.length ? card(r * 2 + 1) : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        ];
      },
    );
  }
}

// MARK: - Header

class _Header extends StatelessWidget {
  final Exhibition ex;
  final VoidCallback onGiveDemo;
  final bool loadingTeam;
  final bool showGiveDemo;

  const _Header({
    required this.ex,
    required this.onGiveDemo,
    required this.loadingTeam,
    required this.showGiveDemo,
  });

  @override
  Widget build(BuildContext context) {
    final dates = exShortDateRange(ex.startDate, ex.endDate);
    final where = [if (ex.place.isNotEmpty) ex.place, if (dates.isNotEmpty) dates].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(ex.name, style: exHeadingXl),
            ExStatusBadge(status: ex.status, large: true),
          ],
        ),
        if (where.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.location_on_outlined, size: 17, color: exSubtle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(where,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500, color: exSubtle)),
              ),
            ],
          ),
        ],
        if (ex.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          ExNoteBox(text: ex.notes.trim()),
        ],
        const SizedBox(height: 16),
        const Text.rich(
          TextSpan(
            text: 'Attendees',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: exInk),
            children: [
              TextSpan(
                text: ' · Also called on every demo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: exSubtle),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (loadingTeam)
          const LinearProgressIndicator(minHeight: 2, color: exBrandBold, backgroundColor: exBorder)
        else if (ex.attendees.isEmpty)
          const Text(
            'No attendees added. Only visitors will be called.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: exSubtle),
          )
        else
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ex.attendees.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = ex.attendees[i];
                return ExPersonChip(name: m.name, number: formatIndianMobile(m.mobile));
              },
            ),
          ),
        if (showGiveDemo) ...[
          const SizedBox(height: 16),
          ExPrimaryButton(
            label: 'Give New Demo',
            icon: Icons.mic_none_rounded,
            height: 56,
            onPressed: onGiveDemo,
          ),
        ],
        if (ex.status == ExhibitionStatus.completed) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: exCompletedBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_rounded, color: exCompletedInk, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This exhibition is completed. New demos are closed.',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: exCompletedInk),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// MARK: - Tabs

/// Underline tabs: "Demos 4" / "Leads 3". Selected tab gets an ink count
/// badge and an indicator-blue underline. [compact] = left-aligned (iPad pane).
class _Tabs extends StatelessWidget {
  final int selected;
  final int demoCount;
  final int leadCount;
  final bool compact;
  final ValueChanged<int> onChanged;

  const _Tabs({
    required this.selected,
    required this.demoCount,
    required this.leadCount,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [_tab(0, 'Demos', demoCount), _tab(1, 'Leads', leadCount)];
    if (compact) {
      return Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: exBorder))),
        child: Row(children: [for (final t in tabs) SizedBox(width: 150, child: t)]),
      );
    }
    return Row(children: [for (final t in tabs) Expanded(child: t)]);
  }

  Widget _tab(int i, String label, int count) {
    final on = selected == i;
    return Semantics(
      selected: on,
      button: true,
      child: InkWell(
        onTap: () => onChanged(i),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: on ? exIndicator : Colors.transparent, width: 3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: on ? exInk : exSubtle,
                  )),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: on ? exInk : exBorder,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: on ? Colors.white : exInk,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Demo row

class _DemoRow extends StatelessWidget {
  final ExhibitionDemo demo;
  final bool isNew;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onCaptureLead;
  final VoidCallback onSendAgain;

  const _DemoRow({
    required this.demo,
    required this.isNew,
    required this.expanded,
    required this.onTap,
    required this.onCaptureLead,
    required this.onSendAgain,
  });

  String? get _voiceTitle {
    final url = demo.audioUrl;
    if (url.isEmpty) return null;
    for (final t in exhibitionDemoTemplates) {
      if (t.audioUrl.isNotEmpty && t.audioUrl == url) return t.title;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = demo;
    final (bg, fg) = callStatusColors(d.status);
    final meta = [
      '${d.recipientCount} ${d.recipientCount == 1 ? 'recipient' : 'recipients'}',
      if (d.createdBy.isNotEmpty) 'by ${d.createdBy}',
      if (d.createdAt != null) exWhen(d.createdAt),
    ].join(' · ');
    final voice = _voiceTitle;
    final active = isNew || expanded;
    return Container(
      decoration: BoxDecoration(
        color: isNew ? exTint : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? exBrand : exBorder, width: active ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Semantics(
                  button: true,
                  expanded: expanded,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: exPageBg, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.graphic_eq_rounded, color: exSubtle),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status sits beside the name, so the meta line
                              // gets the full width instead of being squeezed.
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: Text(d.displayName, style: exHeadingSm)),
                                  const SizedBox(width: 8),
                                  ExPill(label: d.status.label, background: bg, foreground: fg),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(meta, style: exBodyMd),
                              if (voice != null) Text(voice, style: exBodySm),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: expanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(Icons.chevron_right_rounded, color: exSubtle, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (expanded)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: exBorder)),
                ),
                padding: const EdgeInsets.all(16),
                child: DemoDetailPanel(demo: d, onCaptureLead: onCaptureLead, onSendAgain: onSendAgain),
              ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Lead card

class _LeadCard extends StatelessWidget {
  final ExhibitionLead lead;
  final bool isNew;

  const _LeadCard({required this.lead, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final l = lead;
    final sub = [if (l.city.isNotEmpty) l.city, if (l.contactName.isNotEmpty) l.contactName]
        .join(' · ');
    final by = [
      if (l.capturedBy.isNotEmpty) 'by ${l.capturedBy}',
      if (l.demoVisitorName.isNotEmpty) 'from demo: ${l.demoVisitorName}',
    ].join(' · ');
    final hasCall = l.contactNumber.isNotEmpty;
    final hasMail = l.contactEmail.isNotEmpty;
    return ExCard(
      highlighted: isNew,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(l.schoolName, style: exHeadingMd),
              ),
              if (l.createdAt != null) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(exWhen(l.createdAt),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: exSubtle)),
                ),
              ],
            ],
          ),
          if (l.interestLevel != null || sub.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (l.interestLevel != null) ...[
                  ExInterestTag(level: l.interestLevel!),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, color: exSubtle)),
                ),
              ],
            ),
          ],
          if (l.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExNoteBox(text: l.notes, icon: true),
          ],
          if (hasCall || hasMail) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasCall)
                  Expanded(
                    child: ExSecondaryButton(
                      label: 'Call',
                      icon: Icons.phone_outlined,
                      color: exBrandBold,
                      height: 52,
                      onPressed: () =>
                          launchUrl(Uri(scheme: 'tel', path: '+91${l.contactNumber}')),
                    ),
                  ),
                if (hasCall && hasMail) const SizedBox(width: 10),
                if (hasMail)
                  Expanded(
                    child: ExSecondaryButton(
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      color: exBrandBold,
                      height: 52,
                      onPressed: () => launchUrl(Uri(scheme: 'mailto', path: l.contactEmail)),
                    ),
                  ),
              ],
            ),
          ],
          if (by.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(by,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: exSubtle)),
          ],
        ],
      ),
    );
  }
}

// MARK: - Dashed "Capture Lead" button

class _DashedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DashedButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: _DashedBorderPainter(),
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: exBrandBold),
                  const SizedBox(width: 10),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: exBrandBold)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = exStrongBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    ).deflate(0.75);
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
