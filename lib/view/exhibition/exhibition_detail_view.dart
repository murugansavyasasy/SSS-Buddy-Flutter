import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/ExhibitionModel.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'give_demo_view.dart';
import 'widget/exhibition_common.dart';
import 'widget/exhibition_sheets.dart';

/// Phone route: the detail pane inside the usual blue page frame.
class ExhibitionDetailView extends ConsumerWidget {
  final String exhibitionId;
  final Exhibition? initial;

  const ExhibitionDetailView({super.key, required this.exhibitionId, this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ex = ref.watch(exhibitionDetailProvider(exhibitionId)).value ?? initial;
    return ExPage(
      title: ex?.name ?? 'Exhibition',
      onRefresh: () => refreshExhibition(ref, exhibitionId),
      body: ExhibitionDetailPane(exhibitionId: exhibitionId, initial: initial),
    );
  }
}

/// The hub of one exhibition: info, travelling team, Give New Demo, and the
/// Demos / Leads tabs. Leads belong to the exhibition and are one list.
/// Used full-screen on phones and as the right side of the iPad split view.
class ExhibitionDetailPane extends ConsumerStatefulWidget {
  final String exhibitionId;
  final Exhibition? initial;

  const ExhibitionDetailPane({super.key, required this.exhibitionId, this.initial});

  @override
  ConsumerState<ExhibitionDetailPane> createState() => _ExhibitionDetailPaneState();
}

class _ExhibitionDetailPaneState extends ConsumerState<ExhibitionDetailPane> {
  int _tab = 0; // 0 = demos, 1 = leads
  String? _newDemoId;
  bool _highlightNewestLead = false;

  String get _id => widget.exhibitionId;

  void _refresh() => refreshExhibition(ref, _id);

  Future<void> _giveDemo(Exhibition ex) async {
    final res = await Navigator.push<GiveDemoResult>(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => GiveDemoView(exhibition: ex)),
    );
    if (res == null || !mounted) return;
    setState(() {
      _tab = 0;
      _newDemoId = res.demoId.isEmpty ? null : res.demoId;
    });
    _refresh();

    final capture = await showDemoSentSheet(context, callCount: res.callCount);
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

  Future<void> _openDemo(ExhibitionDemo d) async {
    final capture = await showDemoDetailSheet(context, d);
    if (capture && mounted) await _captureLead(demo: d);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(exhibitionDetailProvider(_id));
    final demos = ref.watch(exhibitionDemosProvider(_id));
    final leads = ref.watch(exhibitionLeadsProvider(_id));
    final ex = detail.value ?? widget.initial;

    if (ex == null) {
      return detail.hasError
          ? ExStateView.error(detail.error!, onRetry: _refresh)
          : const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, box) {
        // Measure the pane, not the screen: in the iPad split it is narrower.
        final wide = box.maxWidth >= 640;
        final pad = wide ? 24.0 : 16.0;
        return RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await ref.read(exhibitionDetailProvider(_id).future).catchError((_) => ex);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ExMaxWidth(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
                    child: _Header(
                      ex: ex,
                      onGiveDemo: () => _giveDemo(ex),
                      loadingTeam:
                          detail.isLoading && widget.initial != null && ex.attendees.isEmpty,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ExMaxWidth(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 16, pad, 8),
                    child: _Tabs(
                      selected: _tab,
                      demoCount: demos.value?.length ?? ex.demoCount,
                      leadCount: leads.value?.length ?? ex.leadCount,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ),
                ),
              ),
              if (_tab == 0) ..._demoSlivers(demos, ex, pad) else ..._leadSlivers(leads, pad, wide),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _demoSlivers(AsyncValue<List<ExhibitionDemo>> demos, Exhibition ex, double pad) {
    return demos.when<List<Widget>>(
      loading: () => [const SliverToBoxAdapter(child: ExMaxWidth(child: ExSkeletonList(count: 3)))],
      error: (e, _) => [
        SliverToBoxAdapter(
          child: ExStateView.error(e, onRetry: () => ref.invalidate(exhibitionDemosProvider(_id))),
        ),
      ],
      data: (items) {
        if (items.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: ExStateView(
                icon: Icons.graphic_eq_rounded,
                title: 'No demos yet',
                message: 'Play a voice demo to a visitor and it will appear here.',
                actionLabel: 'Give first demo',
                onAction: () => _giveDemo(ex),
              ),
            ),
          ];
        }
        return [
          SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => ExMaxWidth(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: _DemoRow(
                  demo: items[i],
                  isNew: _newDemoId != null ? items[i].id == _newDemoId : false,
                  onTap: () => _openDemo(items[i]),
                ),
              ),
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _leadSlivers(AsyncValue<List<ExhibitionLead>> leads, double pad, bool wide) {
    final addButton = SliverToBoxAdapter(
      child: ExMaxWidth(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, 10),
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _captureLead(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Capture Lead'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: exStrongBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
    return [
      addButton,
      ...leads.when<List<Widget>>(
        loading: () => [
          const SliverToBoxAdapter(child: ExMaxWidth(child: ExSkeletonList(count: 3))),
        ],
        error: (e, _) => [
          SliverToBoxAdapter(
            child: ExStateView.error(
              e,
              onRetry: () => ref.invalidate(exhibitionLeadsProvider(_id)),
            ),
          ),
        ],
        data: (items) {
          if (items.isEmpty) {
            return [
              const SliverToBoxAdapter(
                child: ExStateView(
                  icon: Icons.school_outlined,
                  title: 'No leads yet',
                  message: 'Interested schools from every demo collect here in one list.',
                ),
              ),
            ];
          }
          final perRow = wide ? 2 : 1;
          final rows = (items.length + perRow - 1) ~/ perRow;
          return [
            SliverList.separated(
              itemCount: rows,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, r) {
                Widget card(int i) =>
                    _LeadCard(lead: items[i], isNew: _highlightNewestLead && i == 0);
                return ExMaxWidth(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: perRow == 1
                        ? card(r)
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: card(r * 2)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: r * 2 + 1 < items.length
                                      ? card(r * 2 + 1)
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                  ),
                );
              },
            ),
          ];
        },
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  final Exhibition ex;
  final VoidCallback onGiveDemo;
  final bool loadingTeam;

  const _Header({required this.ex, required this.onGiveDemo, required this.loadingTeam});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: exBorder),
        boxShadow: exCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                ex.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: exInk,
                ),
              ),
              ExStatusBadge(status: ex.status, large: true),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _iconText(Icons.place_outlined, ex.place.isEmpty ? 'Venue not set' : ex.place),
              _iconText(Icons.calendar_today_outlined, exDateRange(ex.startDate, ex.endDate)),
            ],
          ),
          if (ex.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 18, color: Color(0xFF7A7148)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(ex.notes, style: const TextStyle(fontSize: 14, color: exInk)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text.rich(
            TextSpan(
              text: 'Attenders  ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: exInk),
              children: [
                TextSpan(
                  text: 'Also called on every demo',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: exSubtle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (loadingTeam)
            const LinearProgressIndicator(minHeight: 2)
          else if (ex.attendees.isEmpty)
            const Text(
              'No attenders added. Only visitors will be called.',
              style: TextStyle(fontSize: 13.5, color: exSubtle),
            )
          else
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ex.attendees.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final m = ex.attendees[i];
                  return Container(
                    padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: exBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE8ECF5),
                          child: Text(
                            exInitials(m.name),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: exInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: exInk,
                              ),
                            ),
                            Text(
                              formatIndianMobile(m.mobile),
                              style: const TextStyle(fontSize: 12, color: exSubtle),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          ExPrimaryButton(
            label: 'Give New Demo',
            icon: Icons.mic_rounded,
            height: 56,
            onPressed: onGiveDemo,
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: exSubtle),
      const SizedBox(width: 5),
      Flexible(
        child: Text(text, style: const TextStyle(fontSize: 14, color: exSubtle)),
      ),
    ],
  );
}

/// Demos / Leads switcher: a soft track with a white card that slides
/// under the selected tab. Each tab has its own accent colour.
class _Tabs extends StatelessWidget {
  final int selected;
  final int demoCount;
  final int leadCount;
  final ValueChanged<int> onChanged;

  const _Tabs({
    required this.selected,
    required this.demoCount,
    required this.leadCount,
    required this.onChanged,
  });

  static const _leadAccent = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _track(showHint: box.maxWidth >= 460));

  Widget _track({required bool showHint}) => Container(
    height: 64,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFFE9EDF4),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Stack(
      children: [
        // Sliding indicator.
        AnimatedAlign(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: selected == 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x1F1A2235), blurRadius: 12, offset: Offset(0, 3)),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            _tab(
              0,
              'Demos',
              showHint ? 'Voice demos played' : null,
              Icons.graphic_eq_rounded,
              AppColors.primary,
              demoCount,
            ),
            _tab(
              1,
              'Leads',
              showHint ? 'Interested schools' : null,
              Icons.school_rounded,
              _leadAccent,
              leadCount,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _tab(int i, String label, String? hint, IconData icon, Color accent, int count) {
    final on = selected == i;
    return Expanded(
      child: Semantics(
        selected: on,
        button: true,
        label: '$label, $count',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: on ? accent : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: on ? Colors.white : exSubtle),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: on ? exInk : exSubtle,
                        ),
                        child: Text(label, maxLines: 1),
                      ),
                      if (hint != null)
                        Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: exSubtle),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  constraints: const BoxConstraints(minWidth: 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: on
                        ? accent.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: on ? accent : exSubtle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoRow extends StatelessWidget {
  final ExhibitionDemo demo;
  final bool isNew;
  final VoidCallback onTap;

  const _DemoRow({required this.demo, required this.isNew, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = demo;
    final (bg, fg) = callStatusColors(d.status);
    final meta = [
      '${d.recipientCount} ${d.recipientCount == 1 ? 'recipient' : 'recipients'}',
      if (d.createdBy.isNotEmpty) 'by ${d.createdBy}',
      if (d.createdAt != null) exWhen(d.createdAt),
    ].join(' · ');
    return ExCard(
      highlighted: isNew,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: exTint, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.graphic_eq_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: exInk),
                ),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 13, color: exSubtle)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ExPill(label: d.status.label, background: bg, foreground: fg),
          const Icon(Icons.chevron_right_rounded, color: exSubtle),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final ExhibitionLead lead;
  final bool isNew;

  const _LeadCard({required this.lead, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final l = lead;
    final by = [
      if (l.capturedBy.isNotEmpty) 'Captured by ${l.capturedBy}',
      if (l.createdAt != null) exWhen(l.createdAt),
    ].join(' · ');
    return ExCard(
      highlighted: isNew,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.schoolName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: exInk),
          ),
          if (l.city.isNotEmpty)
            Text(l.city, style: const TextStyle(fontSize: 13.5, color: exSubtle)),
          const SizedBox(height: 8),
          if (l.contactName.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 17, color: exSubtle),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l.contactName, style: const TextStyle(fontSize: 14, color: exInk)),
                ),
              ],
            ),
          if (l.contactNumber.isNotEmpty)
            _LinkRow(
              icon: Icons.phone_outlined,
              text: formatIndianMobile(l.contactNumber),
              uri: Uri(scheme: 'tel', path: '+91${l.contactNumber}'),
            ),
          if (l.contactEmail.isNotEmpty)
            _LinkRow(
              icon: Icons.mail_outline_rounded,
              text: l.contactEmail,
              uri: Uri(scheme: 'mailto', path: l.contactEmail),
            ),
          if (l.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(l.notes, style: const TextStyle(fontSize: 13, color: exSubtle)),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: exPageBg),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(by, style: const TextStyle(fontSize: 12, color: exSubtle)),
              ),
              if (l.demoVisitorName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: exPageBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'from demo: ${l.demoVisitorName}',
                    style: const TextStyle(fontSize: 11.5, color: exSubtle),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Uri uri;

  const _LinkRow({required this.icon, required this.text, required this.uri});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => launchUrl(uri),
    borderRadius: BorderRadius.circular(6),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}
