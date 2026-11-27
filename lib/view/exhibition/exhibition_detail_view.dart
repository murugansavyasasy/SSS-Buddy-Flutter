import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/model/ExhibitionModel.dart';
import '../../components/phone_call.dart';
import '../../provider/user_session_provider.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'exhibition_create_view.dart';
import 'give_demo_view.dart';
import 'showcase/school_chimes_showcase.dart';
import 'widget/demo_audio.dart';
import 'widget/exhibition_common.dart';
import 'widget/exhibition_charts.dart';
import 'widget/exhibition_insights_view.dart';
import 'widget/exhibition_sheets.dart';

/// Delete exhibition button for the creator. Hidden for now; set to true to
/// bring it back (tests switch it on to cover the flow). Edit stays visible.
bool exhibitionDeleteEnabled = false;

/// Phone route: "‹ Exhibitions" back row over the detail pane.
class ExhibitionDetailView extends StatelessWidget {
  final String exhibitionId;
  final Exhibition? initial;

  const ExhibitionDetailView({super.key, required this.exhibitionId, this.initial});

  @override
  Widget build(BuildContext context) => ExPage(
        title: 'Exhibition Details',
        headerDivider: false,
        body: ExhibitionDetailPane(exhibitionId: exhibitionId, initial: initial),
      );
}

/// The hub of one exhibition: info, attendees, the School Chimes showcase, and the
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
  int _tab = 0; // 0 = demos, 1 = leads, 2 = insights

  /// From the iPad split: show this exhibition on its own full page.
  void _openFullView(Exhibition ex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExhibitionDetailView(exhibitionId: ex.id, initial: ex),
      ),
    ).then((_) {
      if (mounted) _refresh();
    });
  }
  String? _newDemoId;
  String? _expandedDemoId;
  bool _highlightNewestLead = false;

  // Search on the Demos and Leads tabs; each tab keeps its own query.
  final _demoSearch = TextEditingController();
  final _leadSearch = TextEditingController();
  final _demoSearchFocus = FocusNode();
  final _leadSearchFocus = FocusNode();
  String _demoQuery = '';
  String _leadQuery = '';

  @override
  void dispose() {
    _demoSearch.dispose();
    _leadSearch.dispose();
    _demoSearchFocus.dispose();
    _leadSearchFocus.dispose();
    super.dispose();
  }

  /// Search field above a Demos / Leads list.
  Widget _searchSliver(double pad,
          {required TextEditingController controller,
          required FocusNode focusNode,
          required String hint,
          required ValueChanged<String> onChanged}) =>
      SliverToBoxAdapter(
        child: _padded(
          pad,
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ExSearchBox(
              controller: controller,
              focusNode: focusNode,
              hint: hint,
              onChanged: onChanged,
            ),
          ),
        ),
      );

  /// "No matches" for a search that finds nothing.
  Widget _noMatchSliver(String message, VoidCallback onClear) => SliverToBoxAdapter(
        child: ExStateView(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: message,
          actionLabel: 'Clear search',
          onAction: onClear,
        ),
      );

  String get _id => widget.exhibitionId;

  void _refresh() => refreshExhibition(ref, _id);

  /// The demo list leaves out the numbers; load them from the demo detail
  /// (already cached when the card is expanded) so Initiate Again has them.
  Future<ExhibitionDemo> _withRecipients(ExhibitionDemo d) async {
    if (d.id.isEmpty || d.recipients.any((r) => !r.isTeam && r.number.isNotEmpty)) return d;
    try {
      final detail = await ref
          .read(exhibitionDemoDetailProvider(d.id).future)
          .timeout(const Duration(seconds: 20));
      return d.mergedWith(detail);
    } catch (_) {
      if (mounted) exToast(context, "Couldn't load the demo's numbers. Add them again.", error: true);
      return d;
    }
  }

  /// Full-screen School Chimes presentation for visitors; its buttons open
  /// Give Demo / Capture Lead on top of it. Give Demo is only ever reached
  /// through here, so every visitor sees School Chimes first. [resendFrom]
  /// ("Send again" on a demo) pre-fills the demo the visitor then starts.
  void _openShowcase(Exhibition ex, {ExhibitionDemo? resendFrom}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SchoolChimesShowcase(
          onGiveDemo: ex.status == ExhibitionStatus.active
              ? () => _giveDemo(ex, resendFrom: resendFrom)
              : null,
          onCaptureLead: () => _captureLead(),
        ),
      ),
    );
  }

  Future<void> _giveDemo(Exhibition ex, {ExhibitionDemo? resendFrom}) async {
    if (resendFrom != null) {
      resendFrom = await _withRecipients(resendFrom);
      if (!mounted) return;
    }
    final res = await Navigator.push<GiveDemoResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GiveDemoView(exhibition: ex, resendFrom: resendFrom),
      ),
    );
    if (res == null || !mounted) return;
    _demoSearch.clear();
    setState(() {
      _tab = 0;
      _demoQuery = '';
      _newDemoId = res.demoId.isEmpty ? null : res.demoId;
    });
    _refresh();

    final capture = await showDemoSentSheet(
      context,
      callCount: res.callCount,
      exhibitionName: ex.name,
      visitorName: res.visitorName,
      visitorNumbers: res.visitorNumbers,
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
    _leadSearch.clear();
    setState(() {
      _tab = 1;
      _leadQuery = '';
      _highlightNewestLead = true;
    });
    _refresh();
    exToast(context, 'Interest captured');
  }

  Future<void> _editExhibition(Exhibition ex) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ExhibitionCreateView(initial: ex),
      ),
    );
    if (saved != true || !mounted) return;
    _refresh();
    exToast(context, 'Exhibition updated');
  }

  Future<void> _deleteExhibition(Exhibition ex) async {
    final ok = await showExConfirmDialog(
      context,
      title: 'Delete this exhibition?',
      message: 'Its demos and leads will be removed too. This cannot be undone.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(exhibitionRepositoryProvider).deleteExhibition(ex.id);
    } catch (e) {
      if (mounted) exToast(context, e.toString(), error: true);
      return;
    }
    if (!mounted) return;
    ref.invalidate(exhibitionListProvider);
    exToast(context, 'Exhibition deleted');
    // On the iPad split the list picks another exhibition by itself.
    if (!widget.embedded) Navigator.pop(context);
  }

  Future<void> _editLead(ExhibitionLead lead) async {
    final saved = await showCaptureLeadSheet(context, exhibitionId: _id, lead: lead);
    if (!saved || !mounted) return;
    _refresh();
    exToast(context, 'Lead updated');
  }

  void _toggleDemo(ExhibitionDemo d) =>
      setState(() => _expandedDemoId = _expandedDemoId == d.id ? null : d.id);

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(exhibitionDetailProvider(_id));
    final demos = ref.watch(exhibitionDemosProvider(_id));
    final leads = ref.watch(exhibitionLeadsProvider(_id));
    // Detail wins, but fields it leaves out (creator, lead count, …) come
    // from the list row — otherwise the creator loses Edit / Delete.
    final fresh = detail.value;
    final base = widget.initial;
    final ex = fresh == null ? base : (base == null ? fresh : fresh.mergedWith(base));

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

        final user = ref.watch(userSessionProvider).value;
        final isOwner = user != null &&
            ex.isCreatedBy(userId: user.userId, userName: user.employeeName);
        final header = _Header(
          ex: ex,
          inset: embedded || wide ? 22 : 16,
          onShowcase: () => _openShowcase(ex),
          // Active shows only: a "Give a voice demo" line inside the card.
          onGiveDemo: ex.status == ExhibitionStatus.active ? () => _openShowcase(ex) : null,
          // Only the creator can edit or delete the exhibition (Delete hidden for now).
          onEdit: isOwner ? () => _editExhibition(ex) : null,
          onDelete: exhibitionDeleteEnabled && isOwner ? () => _deleteExhibition(ex) : null,
          loadingTeam: detail.isLoading && widget.initial != null && ex.attendees.isEmpty,
          demoCount: demos.value?.length ?? ex.demoCount,
          leadCount: leads.value?.length ?? ex.leadCount,
          onShowTab: (i) => setState(() => _tab = i),
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
                // Open just this exhibition full screen (iPad split view).
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openFullView(ex),
                        icon: const Icon(Icons.open_in_full_rounded, size: 18),
                        label: const Text('Open full screen'),
                        style: TextButton.styleFrom(
                          foregroundColor: exBrandBold,
                          textStyle: const TextStyle(
                            fontFamily: exFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // Header card, then the Demos / Leads switch.
              SliverToBoxAdapter(
                child: _padded(
                  pad,
                  Padding(
                    // Room below the curved top edge of the page.
                    padding: EdgeInsets.only(top: embedded ? 4 : 20),
                    child: ExAppear(
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(exRadiusCard + 4),
                          boxShadow: exCardShadow,
                        ),
                        child: header,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _padded(
                  pad,
                  Padding(padding: const EdgeInsets.only(top: 20), child: tabs),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_tab == 0)
                ..._demoSlivers(demos, ex, pad)
              else if (_tab == 1)
                ..._leadSlivers(leads, ex, pad, wide && !embedded)
              else
                SliverToBoxAdapter(
                  child: _padded(
                    pad,
                    demos.isLoading || leads.isLoading
                        ? const ExSkeletonList(count: 2)
                        : ExhibitionInsightsView(
                            exhibition: ex,
                            demos: demos.value ?? const [],
                            leads: leads.value ?? const [],
                          ),
                  ),
                ),
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
    final templates = ref.watch(exhibitionTemplatesProvider(_id)).value ?? const <DemoTemplate>[];
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
      data: (raw) {
        // Show "Lead captured" for demos whose lead the server didn't link.
        final all =
            demosWithLeads(raw, ref.watch(exhibitionLeadsProvider(_id)).value ?? const []);
        // Download every demo voice now, so expanding a demo plays at once.
        for (final d in all) {
          if (d.audioUrl.isNotEmpty) ref.read(localAudioProvider(d.audioUrl));
        }
        if (all.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: ex.status == ExhibitionStatus.active
                  ? ExStateView(
                      icon: Icons.graphic_eq_rounded,
                      title: 'No demos yet',
                      message: 'Play a voice demo and it will appear here.',
                      actionLabel: 'Give first demo',
                      // Starts with the School Chimes showcase; the visitor
                      // takes the demo from its "Hear a voice demo" button.
                      onAction: () => _openShowcase(ex),
                    )
                  : const ExStateView(
                      icon: Icons.graphic_eq_rounded,
                      title: 'No demos',
                      message: 'No demos were given at this exhibition.',
                    ),
            ),
          ];
        }
        final search = _searchSliver(
          pad,
          controller: _demoSearch,
          focusNode: _demoSearchFocus,
          hint: 'Search visitor, number or given by',
          onChanged: (q) => setState(() => _demoQuery = q.trim()),
        );
        final items = all.where((d) => d.matches(_demoQuery)).toList();
        if (items.isEmpty) {
          return [
            search,
            _noMatchSliver('No demo matches "$_demoQuery".', () {
              _demoSearch.clear();
              setState(() => _demoQuery = '');
            }),
          ];
        }
        return [
          search,
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
              ExAppear(
                key: ValueKey('demo-${items[i].id}'),
                index: i,
                child: _DemoRow(
                demo: items[i],
                isNew: _newDemoId != null && items[i].id == _newDemoId,
                expanded: _expandedDemoId == items[i].id,
                onTap: () => _toggleDemo(items[i]),
                onCaptureLead: () => _captureLead(demo: items[i]),
                onSendAgain: () => _openShowcase(ex, resendFrom: items[i]),
                exhibitionName: ex.name,
                templates: templates,
              ),
              ),
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _leadSlivers(
      AsyncValue<List<ExhibitionLead>> leads, Exhibition ex, double pad, bool twoCols) {
    final user = ref.watch(userSessionProvider).value;
    final canWhatsApp = exDemoVideoEnabled;
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
      data: (all) {
        if (all.isEmpty) {
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
        final search = _searchSliver(
          pad,
          controller: _leadSearch,
          focusNode: _leadSearchFocus,
          hint: 'Search school, contact, number or city',
          onChanged: (q) => setState(() => _leadQuery = q.trim()),
        );
        final items = all.where((l) => l.matches(_leadQuery)).toList();
        if (items.isEmpty) {
          return [
            addButton,
            search,
            _noMatchSliver('No lead matches "$_leadQuery".', () {
              _leadSearch.clear();
              setState(() => _leadQuery = '');
            }),
          ];
        }
        final newestId = all.first.id;
        final perRow = twoCols ? 2 : 1;
        final rows = (items.length + perRow - 1) ~/ perRow;
        return [
          addButton,
          search,
          SliverList.separated(
            itemCount: rows,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, r) {
              Widget card(int i) => ExAppear(
                    key: ValueKey('lead-${items[i].id}'),
                    index: i,
                    child: _LeadCard(
                    lead: items[i],
                    isNew: _highlightNewestLead && items[i].id == newestId,
                    onWhatsApp: canWhatsApp &&
                            isValidIndianMobile(normalizeIndianMobile(items[i].contactNumber))
                        ? () => sendDemoVideoOnWhatsApp(
                              context,
                              number: items[i].contactNumber,
                              visitorName: items[i].contactName,
                              exhibitionName: ex.name,
                            )
                        : null,
                    // Only the person who captured the lead can edit it.
                    onEdit: user != null &&
                            items[i].isCreatedBy(userId: user.userId, userName: user.employeeName)
                        ? () => _editLead(items[i])
                        : null,
                  ),
                  );
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

  /// Inner padding of the header card.
  final double inset;
  /// Opens the School Chimes showcase for visitors (demos are given from
  /// its "Hear a voice demo" button; the empty Demos tab's "Give first
  /// demo" opens it too).
  final VoidCallback onShowcase;

  /// Small "Give demo" pill inside the showcase card (null hides it); it
  /// opens the showcase too.
  final VoidCallback? onGiveDemo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool loadingTeam;
  final int demoCount;
  final int leadCount;

  /// Tapping the Demos / Leads counter opens that tab.
  final ValueChanged<int> onShowTab;

  const _Header({
    required this.ex,
    required this.inset,
    required this.onShowcase,
    this.onGiveDemo,
    this.onEdit,
    this.onDelete,
    required this.loadingTeam,
    required this.demoCount,
    required this.leadCount,
    required this.onShowTab,
  });

  @override
  Widget build(BuildContext context) {
    final dates = exDateRange(ex.startDate, ex.endDate);
    final active = ex.status == ExhibitionStatus.active;
    final white80 = Colors.white.withValues(alpha: 0.85);
    Widget info(IconData icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 17, color: white80),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14.5, height: 1.3, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        );
    final hero = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(inset, inset, inset, inset + 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [Color(0xFF1E3A8A), exBrandBold, exHeaderBase]
              : const [Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExPill(
                label: ex.status.label,
                background: Colors.white.withValues(alpha: 0.18),
                foreground: Colors.white,
                dot: active,
                icon: active ? null : Icons.check_circle_rounded,
              ),
              const Spacer(),
              if (onEdit != null)
                _EditButton(
                  tooltip: 'Edit exhibition',
                  color: Colors.white,
                  background: Colors.white.withValues(alpha: 0.16),
                  onPressed: onEdit!,
                ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                _EditButton(
                  tooltip: 'Delete exhibition',
                  icon: Icons.delete_outline_rounded,
                  color: Colors.white,
                  background: Colors.white.withValues(alpha: 0.16),
                  onPressed: onDelete!,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Title gets the full width so long names wrap between words.
          Text(ex.name,
              style: exHeadingLg.copyWith(
                  fontSize: 23, height: 1.25, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          info(Icons.location_on_rounded, ex.place.isEmpty ? 'Venue not set' : ex.place),
          const SizedBox(height: 6),
          info(Icons.event_rounded, dates),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hero,
        Padding(
          padding: EdgeInsets.fromLTRB(inset, 0, inset, inset),
          child: _body(context),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [        const SizedBox(height: 14),
        // Counters
        Row(
          children: [
            Expanded(
              child: ExMetricTile(
                icon: Icons.graphic_eq_rounded,
                value: '$demoCount',
                label: demoCount == 1 ? 'Demo' : 'Demos',
                color: exAccentDemo,
                background: exAccentDemoBg,
                onTap: () => onShowTab(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ExMetricTile(
                icon: Icons.star_rounded,
                value: '$leadCount',
                label: leadCount == 1 ? 'Lead' : 'Leads',
                color: exAccentLead,
                background: exAccentLeadBg,
                onTap: () => onShowTab(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ExMetricTile(
                icon: Icons.groups_rounded,
                value: '${ex.attendees.isNotEmpty ? ex.attendees.length : ex.attendeeCount}',
                label: (ex.attendees.isNotEmpty ? ex.attendees.length : ex.attendeeCount) == 1
                    ? 'Attendee'
                    : 'Attendees',
                color: exAccentTeam,
                background: exAccentTeamBg,
              ),
            ),
          ],
        ),
        if (demoCount > 0) ...[
          const SizedBox(height: 10),
          _ConversionLink(demos: demoCount, leads: leadCount, onTap: () => onShowTab(2)),
        ],
        if (ex.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          ExNoteBox(text: ex.notes.trim(), icon: true),
        ],
        const SizedBox(height: 18),
        const ExSectionTitle(title: 'Attendees', caption: 'Also called on every demo'),
        const SizedBox(height: 10),
        if (loadingTeam)
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(2)),
            child: LinearProgressIndicator(minHeight: 3, color: exBrandBold, backgroundColor: exBorder),
          )
        else if (ex.attendees.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: exPageBg,
              borderRadius: BorderRadius.circular(exRadiusControl),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_off_outlined, size: 20, color: exSubtle),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No attendees added. Only visitors will be called.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: exSubtle),
                  ),
                ),
              ],
            ),
          )
        else
          // Wrap inside the card (a sideways list ran past its edge).
          LayoutBuilder(
            builder: (context, box) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final m in ex.attendees)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth),
                    child: ExPersonChip(name: m.name, number: formatIndianMobile(m.mobile)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        _ShowcaseButton(onTap: onShowcase, onGiveDemo: onGiveDemo),
        if (ex.status == ExhibitionStatus.completed) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: exCompletedBg,
              borderRadius: BorderRadius.circular(exRadiusControl),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.flag_rounded, color: exCompletedInk, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
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

/// "Show School Chimes to visitors" button with the brand logo.
class _ShowcaseButton extends StatelessWidget {
  final VoidCallback onTap;

  /// Shown as a text line inside the card, not as a separate button.
  final VoidCallback? onGiveDemo;
  const _ShowcaseButton({required this.onTap, this.onGiveDemo});

  static const _indigo = Color(0xFF372A8A);
  static const _deep = Color(0xFF231A5E);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(exRadiusControl + 2);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FF),
        borderRadius: radius,
        border: Border.all(color: const Color(0x33372A8A), width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Image.asset('assets/images/schoolchimes_logo.png', height: 28, width: 79), // 600×214
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Show School Chimes',
                              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _deep)),
                          const Text('Present the ERP to visitors at the stall',
                              style: TextStyle(fontSize: 12.5, color: exSubtle)),
                          // Small "Give demo" hint inside the card.
                          if (onGiveDemo != null) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onGiveDemo!();
                              },
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
                                decoration: BoxDecoration(
                                  color: const Color(0x14F2474F),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.phone_in_talk_rounded, size: 13, color: Color(0xFFF2474F)),
                                    SizedBox(width: 4),
                                    Text('Give demo',
                                        style: TextStyle(
                                            fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF2474F))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.slideshow_rounded, color: _indigo),
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

/// "7 leads from 16 demos · 44% lead rate ›" under the counters.
class _ConversionLink extends StatelessWidget {
  final int demos;
  final int leads;
  final VoidCallback onTap;
  const _ConversionLink({required this.demos, required this.leads, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = (leads * 100 / demos).round();
    return Material(
      color: const Color(0xFFFFF6EF),
      borderRadius: BorderRadius.circular(exRadiusControl),
      child: InkWell(
        borderRadius: BorderRadius.circular(exRadiusControl),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ExDemoLeadBars(demos: demos, leads: leads, height: 30, labels: false, barWidth: 11),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exConversionWords(demos, leads),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: exInk)),
                    Text('$pct% lead rate · tap for charts and insights',
                        style: const TextStyle(fontSize: 12, color: exSubtle)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: exSubtle),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Tabs

/// Segmented switch: "Demos 4" / "Leads 3". The selected side is a raised
/// white capsule with a brand count badge.
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
    final track = Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EAF8),
        borderRadius: BorderRadius.circular(exRadiusControl + 2),
      ),
      child: Stack(
        children: [
          // White thumb slides under the selected tab.
          AnimatedAlign(
            alignment: Alignment(selected - 1.0, 0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(exRadiusControl - 2),
                  boxShadow: exCardShadow,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _tab(0, 'Demos', Icons.graphic_eq_rounded, demoCount)),
              Expanded(child: _tab(1, 'Leads', Icons.star_rounded, leadCount)),
              Expanded(child: _tab(2, 'Insights', Icons.insights_rounded, null)),
            ],
          ),
        ],
      ),
    );
    if (!compact) return track;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: track),
    );
  }

  Widget _tab(int i, String label, IconData icon, int? count) {
    final on = selected == i;
    return Semantics(
      selected: on,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // Three tabs share a phone row: shrink rather than overflow.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: on ? exBrandBold : exSubtle),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                    color: on ? exInk : exSubtle,
                  )),
              if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: on ? exBrandBold : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : exSubtle,
                    )),
              ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}

// MARK: - Demo row

/// Demo card: visitor tile, name, time and call status; the voice used; a
/// strip with numbers called, who gave it and the lead state; and a
/// "View calls" footer that expands the call details.
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
    required this.templates,
    this.exhibitionName = '',
  });

  final String exhibitionName;

  /// Voice templates from the API, to name the voice a demo used.
  final List<DemoTemplate> templates;

  String? get _voiceTitle {
    final url = demo.audioUrl;
    if (url.isEmpty) return null;
    for (final t in templates) {
      if (t.audioUrl.isNotEmpty && t.audioUrl == url) return t.title;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = demo;
    final (bg, fg) = callStatusColors(d.status);
    final voice = _voiceTitle;
    final active = isNew || expanded;
    final numbers = '${d.recipientCount} ${d.recipientCount == 1 ? 'number' : 'numbers'}';
    return Container(
      decoration: BoxDecoration(
        color: isNew ? exTint : Colors.white,
        borderRadius: BorderRadius.circular(exRadiusCard),
        border: Border.all(
            color: active ? exBrand : const Color(0xFFEDF1F6), width: active ? 1.5 : 1),
        boxShadow: exCardShadow,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Visitor, time and status
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: d.hasLead
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [exSuccess, Color(0xFF34A853)],
                                      )
                                    : exHeroGradient,
                                borderRadius: BorderRadius.circular(exRadiusControl + 2),
                                boxShadow: d.hasLead ? null : exBrandGlow,
                              ),
                              child: d.visitorName.trim().isEmpty
                                  ? const Icon(Icons.person_rounded, color: Colors.white, size: 26)
                                  : Text(exInitials(d.visitorName),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: exHeadingSm.copyWith(
                                          fontSize: 17, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 14, color: exSubtle),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                            d.createdAt == null ? 'Time not known' : exWhen(d.createdAt),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: exSubtle)),
                                      ),
                                      if (isNew) ...[
                                        const SizedBox(width: 8),
                                        const ExPill(
                                          label: 'New',
                                          background: exBrandBold,
                                          foreground: Colors.white,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ExPill(label: d.status.label, background: bg, foreground: fg, dot: true),
                          ],
                        ),
                      ),
                      // Voice used
                      if (d.audioUrl.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [exTint, Color(0xFFF3F8FF)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.headphones_rounded,
                                    size: 15, color: exBrandBold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: _VoiceLine(url: d.audioUrl, title: voice)),
                            ],
                          ),
                        ),
                      // Numbers called, given by, lead state
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ExStatChip(
                              icon: Icons.call_rounded,
                              text: numbers,
                              color: exAccentTeam,
                              background: exAccentTeamBg,
                            ),
                            if (d.createdBy.isNotEmpty)
                              ExStatChip(
                                icon: Icons.badge_rounded,
                                text: d.createdBy,
                                color: exInk,
                                background: exNeutralBg,
                              ),
                            d.hasLead
                                ? const ExStatChip(
                                    icon: Icons.verified_rounded,
                                    text: 'Lead captured',
                                    color: exSuccess,
                                    background: exSuccessBg,
                                  )
                                : const ExStatChip(
                                    icon: Icons.star_outline_rounded,
                                    text: 'No lead yet',
                                    color: exAccentLead,
                                    background: exAccentLeadBg,
                                  ),
                          ],
                        ),
                      ),
                      // Expand / collapse
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: exBorder)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(expanded ? 'Hide calls' : 'View calls',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: exBrandBold)),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 20, color: exBrandBold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (expanded)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFCFE),
                  border: Border(top: BorderSide(color: exBorder)),
                ),
                padding: const EdgeInsets.all(16),
                child: DemoDetailPanel(
                  demo: d,
                  onCaptureLead: onCaptureLead,
                  onSendAgain: onSendAgain,
                  exhibitionName: exhibitionName,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Lead card

/// Lead card: school header with interest level, a contact panel with Call /
/// Email buttons, notes, photos, WhatsApp video and a "captured by" footer.
class _LeadCard extends StatelessWidget {
  final ExhibitionLead lead;
  final bool isNew;
  final VoidCallback? onEdit;

  /// Sends the demo video link to the lead's number on WhatsApp.
  final VoidCallback? onWhatsApp;

  const _LeadCard({required this.lead, required this.isNew, this.onEdit, this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    final l = lead;
    final hasCall = l.contactNumber.isNotEmpty;
    final hasMail = l.contactEmail.isNotEmpty;
    final hasPerson = l.contactName.isNotEmpty || l.contactDesignation.isNotEmpty;
    final hasActions = hasCall || hasMail || onWhatsApp != null;
    final initial = l.schoolName.trim().isEmpty ? '?' : l.schoolName.trim()[0].toUpperCase();
    final level = l.interestLevel;
    final (accentBg, accent) = level == null ? (exTint, exBrandBold) : interestLevelColors(level);

    return ExCard(
      highlighted: isNew,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // School, city, interest level
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, onEdit != null ? 8 : 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(exRadiusControl),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Text(initial,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.schoolName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: exHeadingSm.copyWith(
                              fontSize: 16.5, height: 1.25, fontWeight: FontWeight.w700)),
                      if (l.city.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: exSubtle),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(l.city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13.5, fontWeight: FontWeight.w500, color: exSubtle)),
                            ),
                          ],
                        ),
                      ],
                      if (level != null || l.demoVisitorName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (level != null) ExInterestTag(level: level),
                            if (l.demoVisitorName.isNotEmpty)
                              ExStatChip(
                                icon: Icons.graphic_eq_rounded,
                                text: 'Demo: ${l.demoVisitorName}',
                                color: exBrandBold,
                                background: exTint,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 4),
                  _EditButton(tooltip: 'Edit lead', onPressed: onEdit!),
                ],
              ],
            ),
          ),
          // Contact person: name + designation, then number / email rows
          if (hasPerson || hasCall || hasMail)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: exPageBg,
                borderRadius: BorderRadius.circular(exRadiusControl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasPerson)
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
                          ),
                          child: l.contactName.isEmpty
                              ? Icon(Icons.person_rounded, size: 18, color: accent)
                              : Text(exInitials(l.contactName),
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (l.contactName.isNotEmpty)
                                Text(l.contactName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w700, color: exInk)),
                              if (l.contactDesignation.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                _DesignationPill(text: l.contactDesignation),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (hasCall)
                    _ContactLine(
                      icon: Icons.phone_rounded,
                      text: formatIndianMobile(l.contactNumber),
                      top: hasPerson ? 10 : 0,
                    ),
                  if (hasMail)
                    _ContactLine(
                      icon: Icons.mail_outline_rounded,
                      text: l.contactEmail,
                      top: hasPerson || hasCall ? 6 : 0,
                    ),
                ],
              ),
            ),
          // Notes as a quote
          if (l.notes.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: exNotes,
                borderRadius: BorderRadius.circular(exRadiusControl),
                border: const Border(left: BorderSide(color: exAccentLead, width: 3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, size: 18, color: exAccentLead),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l.notes,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.35, color: exInk)),
                  ),
                ],
              ),
            ),
          // Uploaded photos
          if (l.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: l.attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ExAttachmentTile(
                    url: l.attachments[i],
                    size: 64,
                    gallery: l.attachments,
                  ),
                ),
              ),
            ),
          // Call / Email / WhatsApp video in one row
          if (hasActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  if (hasCall)
                    Expanded(
                      child: _LeadAction(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        filled: true,
                        onTap: () => PhoneCall.dial('+91${l.contactNumber}'),
                      ),
                    ),
                  if (hasMail) ...[
                    if (hasCall) const SizedBox(width: 8),
                    Expanded(
                      child: _LeadAction(
                        icon: Icons.mail_rounded,
                        label: 'Email',
                        onTap: () => launchUrl(Uri(scheme: 'mailto', path: l.contactEmail)),
                      ),
                    ),
                  ],
                  if (onWhatsApp != null) ...[
                    if (hasCall || hasMail) const SizedBox(width: 8),
                    Expanded(
                      child: _LeadAction(
                        icon: Icons.ondemand_video_rounded,
                        label: 'WhatsApp',
                        tooltip: 'Send demo video on WhatsApp',
                        color: exSuccess,
                        onTap: onWhatsApp!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Who captured it and when
          if (l.capturedBy.isNotEmpty || l.createdAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  if (l.capturedBy.isNotEmpty) ...[
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: exAccentTeamBg, shape: BoxShape.circle),
                      child: Text(exInitials(l.capturedBy),
                          style: const TextStyle(
                              fontSize: 8.5, fontWeight: FontWeight.w700, color: exAccentTeam)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Captured by ${l.capturedBy}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: exBodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ] else
                    const Spacer(),
                  if (l.createdAt != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule_rounded, size: 13, color: exSubtle),
                    const SizedBox(width: 4),
                    Text(exWhen(l.createdAt), style: exBodySm.copyWith(fontSize: 12.5)),
                  ],
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// The contact's role (e.g. Principal) as a small tinted pill.
class _DesignationPill extends StatelessWidget {
  final String text;
  const _DesignationPill({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: exTint, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline_rounded, size: 13, color: exBrandBold),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700, color: exBrandBold)),
            ),
          ],
        ),
      );
}

/// One icon + text line in the contact panel (number, email).
class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final double top;
  const _ContactLine({required this.icon, required this.text, this.top = 0});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top),
        child: Row(
          children: [
            SizedBox(width: 36, child: Icon(icon, size: 16, color: exSubtle)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF3F4A5A))),
            ),
          ],
        ),
      );
}

/// Labelled quick action: Call is filled green, Email is tonal blue.
class _LeadAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  /// Outline/text colour for an unfilled action (default brand blue).
  final Color? color;
  final String? tooltip;

  const _LeadAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : (color ?? exBrandBold);
    final button = Material(
      color: filled ? exSuccess : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(color: color == null ? exIndicator : color!.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
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
        child: Material(
          color: exTint.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(exRadiusControl),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(exRadiusControl),
            child: CustomPaint(
              painter: _DashedBorderPainter(),
              child: SizedBox(
                height: 54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: exBrandBold, shape: BoxShape.circle),
                      child: Icon(icon, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: exBrandBold)),
                  ],
                ),
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
      ..color = exIndicator
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(exRadiusControl),
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

/// Small pencil button used on the exhibition header and lead cards.
class _EditButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final Color background;
  const _EditButton({
    required this.tooltip,
    required this.onPressed,
    this.icon = Icons.edit_outlined,
    this.color = exBrandBold,
    this.background = exTint,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: background,
            shape: const CircleBorder(),
          ),
          icon: Icon(icon, size: 20, color: color),
        ),
      );
}

/// "🎧 Voice title · 0:34" under a demo; the length is read from the audio URL.
class _VoiceLine extends ConsumerWidget {
  final String url;
  final String? title;
  const _VoiceLine({required this.url, this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dur = ref.watch(audioDurationProvider(url));
    final length = dur.when(
      data: (d) => d == null ? null : exDuration(d),
      loading: () => '…',
      error: (_, __) => null,
    );
    final text = [title ?? 'Demo voice', if (length != null) length].join(' · ');
    return Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exBrandBold));
  }
}
