import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/model/ExhibitionModel.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'exhibition_create_view.dart';
import 'exhibition_detail_view.dart';
import 'widget/exhibition_charts.dart';
import 'widget/exhibition_overview.dart';
import 'widget/exhibition_common.dart';

enum _Filter { all, active, completed }

/// Home of the Exhibitions module: every trade show, newest first.
/// Phone: white header (‹ Exhibitions, search, chips) over the card list.
/// iPad: list pane on the left, the selected exhibition on the right; the
/// user can switch to a full-screen list and back (remembered).
class ExhibitionListView extends ConsumerStatefulWidget {
  const ExhibitionListView({super.key});

  @override
  ConsumerState<ExhibitionListView> createState() => _ExhibitionListViewState();
}

class _ExhibitionListViewState extends ConsumerState<ExhibitionListView> {
  String _query = '';
  _Filter _filter = _Filter.all;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  /// iPad split only: the exhibition shown on the right.
  String? _selectedId;

  /// iPad only: split view or full screen. Remembered across launches.
  bool _splitPref = true;
  static const _splitPrefKey = 'exhibition_ipad_split_view';

  bool get _useSplit => exIsSplit(context) && _splitPref;

  @override
  void initState() {
    super.initState();
    _loadSplitPref();
  }

  Future<void> _loadSplitPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_splitPrefKey);
      if (v != null && mounted) setState(() => _splitPref = v);
    } catch (_) {}
  }

  Future<void> _toggleSplit() async {
    HapticFeedback.selectionClick();
    setState(() => _splitPref = !_splitPref);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_splitPrefKey, _splitPref);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Exhibition> _apply(List<Exhibition> all) => all.where((e) {
        if (_filter == _Filter.active && e.status != ExhibitionStatus.active) return false;
        if (_filter == _Filter.completed && e.status != ExhibitionStatus.completed) return false;
        if (_query.isEmpty) return true;
        return '${e.name} ${e.city} ${e.venue}'.toLowerCase().contains(_query);
      }).toList();

  void _clearFilters() => setState(() {
        _filter = _Filter.all;
        _query = '';
        _searchCtrl.clear();
      });

  /// Search field above the filter tabs (counts come from the full list).
  Widget _headerControls(List<Exhibition>? all) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _searchBox(),
          const SizedBox(height: 12),
          _filterRow(all),
        ],
      );

  /// "2 active · 5 total" under the page title.
  String? _subtitle(List<Exhibition>? all) {
    if (all == null || all.isEmpty) return null;
    final active = all.where((e) => e.status == ExhibitionStatus.active).length;
    return '$active active · ${all.length} total';
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<Exhibition>(
      context,
      CupertinoPageRoute(builder: (_) => const ExhibitionCreateView()),
    );
    if (created == null || !mounted) return;
    ref.invalidate(exhibitionListProvider);
    exToast(context, 'Exhibition created');
    if (created.id.isNotEmpty) _openDetail(created);
  }

  void _openDetail(Exhibition e) {
    if (_useSplit) {
      setState(() => _selectedId = e.id);
      return;
    }
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => ExhibitionDetailView(exhibitionId: e.id, initial: e),
      ),
    ).then((_) {
      if (mounted) ref.invalidate(exhibitionListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(exhibitionListProvider);
    final tablet = exIsSplit(context);
    final split = tablet && _splitPref;
    final toggle = tablet
        ? Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ExSplitToggle(split: split, onTap: _toggleSplit),
          )
        : null;

    if (split) return _SplitScaffold(child: _splitBody(async, toggle!));

    return ExPage(
      title: 'Exhibitions',
      subtitle: _subtitle(async.value),
      headerDivider: false,
      actions: [
        if (toggle != null) toggle,
      ],
      headerBottom: _headerControls(async.value),
      floatingActionButton: ExFab(onPressed: _openCreate),
      body: _listArea(async, grid: exIsWide(context), overview: true),
    );
  }

  // MARK: Pieces

  Widget _searchBox() => _SearchBox(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        onChanged: (q) => setState(() => _query = q.trim().toLowerCase()),
      );

  Widget _filterRow(List<Exhibition>? all) => _CategoryTabs(
        tabs: [
          for (final f in _Filter.values)
            switch (f) {
              _Filter.all => 'All',
              _Filter.active => 'Active',
              _Filter.completed => 'Completed',
            },
        ],
        counts: all == null
            ? null
            : [
                all.length,
                all.where((e) => e.status == ExhibitionStatus.active).length,
                all.where((e) => e.status == ExhibitionStatus.completed).length,
              ],
        selected: _filter.index,
        onSelect: (i) {
          HapticFeedback.selectionClick();
          setState(() => _filter = _Filter.values[i]);
        },
      );

  /// Loading / error / empty / no-match, or null when there is a list.
  Widget? _listState(AsyncValue<List<Exhibition>> async, List<Exhibition>? items) {
    return async.when(
      loading: () => const ExMaxWidth(
        child: ExSkeletonList(caption: 'Loading exhibitions…'),
      ),
      error: (e, _) => ExStateView.error(
        e,
        title: "Couldn't load exhibitions",
        onRetry: () => ref.invalidate(exhibitionListProvider),
      ),
      data: (all) {
        if (all.isEmpty) {
          return ExStateView(
            icon: Icons.storefront_outlined,
            tone: ExTone.success,
            title: 'No exhibitions yet',
            message: 'Create your first trade show to start giving demos.',
            actionLabel: 'Create exhibition',
            primaryAction: true,
            onAction: _openCreate,
          );
        }
        if (items!.isEmpty) {
          return ExStateView(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            message: 'Try another name, city or venue.',
            actionLabel: 'Show all',
            onAction: _clearFilters,
          );
        }
        return null;
      },
    );
  }

  Widget _listArea(
    AsyncValue<List<Exhibition>> async, {
    required bool grid,
    String? selectedId,
    EdgeInsets? padding,
    bool overview = false,
  }) {
    final items = async.value == null ? null : _apply(async.value!);
    final state = _listState(async, items);
    if (state != null) return state;
    // Overview of the exhibitions shown (follows search + status filter),
    // as the first, full-width row of the list.
    final head = overview
        ? ExAppear(
            key: ValueKey('overview-${_filter.name}'),
            child: ExhibitionsOverviewCard(items: items!, onOpen: _openDetail),
          )
        : null;
    final h = head == null ? 0 : 1;
    final pad = padding ?? EdgeInsets.fromLTRB(grid ? 24 : 16, 16, grid ? 24 : 16, 112);
    return RefreshIndicator(
      color: exBrandBold,
      onRefresh: () => ref.refresh(exhibitionListProvider.future),
      child: grid
          ? LayoutBuilder(builder: (context, box) {
              // Rows of equal-height cards; height follows the content, so a
              // two-line title or wrapped chips never overflow.
              final cols = ((box.maxWidth - pad.horizontal + 16) / 536).ceil().clamp(1, 4);
              final rows = (items!.length + cols - 1) ~/ cols;
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: pad,
                itemCount: rows + h,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, rr) => rr < h
                    ? head!
                    : Builder(builder: (_) {
                  final r = rr - h;
                  return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = 0; c < cols; c++) ...[
                        if (c > 0) const SizedBox(width: 16),
                        Expanded(
                          child: r * cols + c < items.length
                              ? ExAppear(
                                  key: ValueKey('${_filter.name}-${items[r * cols + c].id}'),
                                  index: r * cols + c,
                                  child: ExhibitionCard(
                                    exhibition: items[r * cols + c],
                                    onTap: () => _openDetail(items[r * cols + c]),
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ],
                  ),
                );
                }),
              );
            })
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: pad,
              itemCount: items!.length + h,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, ii) {
                if (ii < h) return head!;
                final i = ii - h;
                return ExAppear(
                  // Replays when the filter changes.
                  key: ValueKey('${_filter.name}-${items[i].id}'),
                  index: i + h,
                  child: ExhibitionCard(
                    exhibition: items[i],
                    selected: items[i].id == selectedId,
                    onTap: () => _openDetail(items[i]),
                  ),
                );
              },
            ),
    );
  }

  Widget _splitBody(AsyncValue<List<Exhibition>> async, Widget toggle) {
    final all = async.value;
    final items = all == null ? null : _apply(all);

    // The right side always matches a highlighted card in the visible list.
    Exhibition? selected;
    if (all != null && all.isNotEmpty) {
      final visible = items ?? const <Exhibition>[];
      selected = visible.isNotEmpty
          ? visible.firstWhere((e) => e.id == _selectedId, orElse: () => visible.first)
          : all.firstWhere((e) => e.id == _selectedId, orElse: () => all.first);
    }

    final width = MediaQuery.sizeOf(context).width;
    final listWidth = (width * 0.36).clamp(340.0, 440.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Blue header across both panes ──
        ExGradientHeader(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 18),
          child: Row(
            children: [
              ExBackButton(onPressed: () => Navigator.maybePop(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Exhibitions',
                        style: exHeadingLg.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                    if (_subtitle(all) != null)
                      Text(_subtitle(all)!,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              toggle,
            ],
          ),
        ),
        Expanded(
          child: ExCurvedBody(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left: search, chips, list ──
                Container(
                  width: listWidth,
                  decoration: const BoxDecoration(
                    color: exPageBg,
                    border: Border(right: BorderSide(color: exBorder)),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 20, 24, 8),
                            child: _headerControls(all),
                          ),
                          Expanded(
                            child: _listArea(
                              async,
                              grid: false,
                              selectedId: selected?.id,
                              padding: const EdgeInsets.fromLTRB(28, 12, 24, 120),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 24,
                        bottom: 24 + MediaQuery.paddingOf(context).bottom,
                        child: ExFab(onPressed: _openCreate),
                      ),
                    ],
                  ),
                ),
                // ── Right: the selected exhibition ──
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selected == null
                        ? const ExStateView(
                            key: ValueKey('none'),
                            icon: Icons.storefront_outlined,
                            title: 'Select an exhibition',
                            message: 'Pick a trade show on the left to see its demos and leads.',
                          )
                        : ExhibitionDetailPane(
                            key: ValueKey(selected.id),
                            exhibitionId: selected.id,
                            initial: selected,
                            embedded: true,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Scaffold for the iPad split (sky header across both panes).
class _SplitScaffold extends StatelessWidget {
  final Widget child;
  const _SplitScaffold({required this.child});

  @override
  Widget build(BuildContext context) => ExTheme(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: exHeaderOverlay,
          child: Scaffold(backgroundColor: exHeaderBase, body: child),
        ),
      );
}

/// White search field with a soft shadow and a clear button.
class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(exRadiusControl + 2),
          boxShadow: exCardShadow,
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, v, __) => TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => focusNode.unfocus(),
            onTapOutside: (_) => focusNode.unfocus(),
            style: const TextStyle(fontSize: 16, color: exInk),
            cursorColor: exBrandBold,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search name, city or venue',
              hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF9A9AA3)),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              prefixIcon: const Icon(Icons.search_rounded, size: 22, color: exBrandBold),
              prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 50),
              suffixIcon: v.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.cancel_rounded, size: 20, color: exSubtle),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(exRadiusControl + 2),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(exRadiusControl + 2),
                borderSide: const BorderSide(color: exBrand, width: 1.5),
              ),
            ),
          ),
        ),
      );
}

/// Segmented control: All / Active / Completed with counts; the selected
/// segment is a white raised capsule on a tinted track.
class _CategoryTabs extends StatelessWidget {
  final List<String> tabs;
  final List<int>? counts;
  final int selected;
  final ValueChanged<int> onSelect;

  const _CategoryTabs({
    required this.tabs,
    required this.selected,
    required this.onSelect,
    this.counts,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE3EAF8),
          borderRadius: BorderRadius.circular(exRadiusControl + 2),
        ),
        child: Stack(
          children: [
            // White thumb slides under the selected segment.
            AnimatedAlign(
              alignment: Alignment(tabs.length == 1 ? 0 : -1 + 2 * selected / (tabs.length - 1), 0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: 1 / tabs.length,
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
              children: [for (var i = 0; i < tabs.length; i++) Expanded(child: _segment(i))],
            ),
          ],
        ),
      );

  Widget _segment(int i) {
    final on = i == selected;
    final count = counts?[i];
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(i),
        child: Container(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                      color: on ? exInk : exSubtle,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: on ? exBrandBold : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: on ? Colors.white : exSubtle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Exhibition card: calendar tile (month + day) beside the name, place,
/// dates and status, then a three-part counter strip (team, demos, leads).
class ExhibitionCard extends StatelessWidget {
  final Exhibition exhibition;
  final VoidCallback onTap;
  final bool selected;

  const ExhibitionCard({
    super.key,
    required this.exhibition,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final e = exhibition;
    final active = e.status == ExhibitionStatus.active;
    return ExCard(
      onTap: onTap,
      highlighted: selected,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateTile(date: e.startDate, active: active),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: exHeadingMd.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
                      const SizedBox(height: 6),
                      _Meta(
                        icon: Icons.location_on_rounded,
                        text: e.place.isEmpty ? 'Venue not set' : e.place,
                      ),
                      const SizedBox(height: 3),
                      _Meta(
                        icon: Icons.event_rounded,
                        text: exDateRange(e.startDate, e.endDate),
                      ),
                      const SizedBox(height: 10),
                      ExStatusBadge(status: e.status),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.chevron_right_rounded, color: exSubtle, size: 24),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: exPageBg,
              borderRadius: BorderRadius.circular(exRadiusControl),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _Counter(
                    icon: Icons.groups_rounded,
                    value: e.attendeeCount,
                    label: e.attendeeCount == 1 ? 'Attendee' : 'Attendees',
                    color: exAccentTeam,
                    background: exAccentTeamBg,
                  ),
                  const VerticalDivider(width: 1, thickness: 1, color: exBorder),
                  _Counter(
                    icon: Icons.graphic_eq_rounded,
                    value: e.demoCount,
                    label: e.demoCount == 1 ? 'Demo' : 'Demos',
                    color: exAccentDemo,
                    background: exAccentDemoBg,
                  ),
                  const VerticalDivider(width: 1, thickness: 1, color: exBorder),
                  _Counter(
                    icon: Icons.star_rounded,
                    value: e.leadCount,
                    label: e.leadCount == 1 ? 'Lead' : 'Leads',
                    color: exAccentLead,
                    background: exAccentLeadBg,
                  ),
                ],
              ),
            ),
          ),
          if (e.demoCount > 0) _ConversionStrip(demos: e.demoCount, leads: e.leadCount),
        ],
      ),
    );
  }
}

/// "▮▮▮▯ 38% lead rate" at the foot of a card.
class _ConversionStrip extends StatelessWidget {
  final int demos;
  final int leads;
  const _ConversionStrip({required this.demos, required this.leads});

  @override
  Widget build(BuildContext context) {
    final v = (leads / demos).clamp(0.0, 1.0);
    final pct = (leads * 100 / demos).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Semantics(
        label: '$pct percent lead rate, $leads leads from $demos demos',
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: exReduceMotion(context) ? v : 0, end: v),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, t, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(color: exChartTrack),
                        FractionallySizedBox(
                          widthFactor: t,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFF09466), exChartLead]),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '$pct%', style: const TextStyle(fontWeight: FontWeight.w800, color: exInk)),
                const TextSpan(text: ' lead rate'),
              ]),
              style: const TextStyle(fontSize: 12, color: exSubtle),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendar-style tile: brand gradient while active, grey once completed.
class _DateTile extends StatelessWidget {
  final DateTime? date;
  final bool active;
  const _DateTile({required this.date, required this.active});

  static const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : exInk;
    final d = date;
    return Container(
      width: 56,
      height: 62,
      decoration: BoxDecoration(
        gradient: active ? exHeroGradient : null,
        color: active ? null : exNeutralBg,
        borderRadius: BorderRadius.circular(exRadiusControl),
        boxShadow: active ? exBrandGlow : null,
      ),
      child: d == null
          ? Icon(Icons.storefront_rounded, color: fg, size: 26)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_months[d.month - 1],
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: fg.withValues(alpha: 0.8))),
                Text('${d.day}',
                    style: TextStyle(
                        fontSize: 24, height: 1.1, fontWeight: FontWeight.w700, color: fg)),
              ],
            ),
    );
  }
}

/// One cell of the card's counter strip.
class _Counter extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final Color background;

  const _Counter({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          label: '$value $label',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExCountUp(value,
                        style: const TextStyle(
                            fontSize: 16, height: 1.1, fontWeight: FontWeight.w700, color: exInk)),
                    // Shrink rather than cut "Attendees" on narrow phones.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(label,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: exSubtle)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      );
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: exBrand),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                maxLines: 1,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: exSubtle),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}
