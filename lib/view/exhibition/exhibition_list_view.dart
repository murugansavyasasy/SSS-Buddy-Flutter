import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/model/ExhibitionModel.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'exhibition_create_view.dart';
import 'exhibition_detail_view.dart';
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
        ? ExHeaderIconButton(
            icon: split ? Icons.fullscreen_rounded : Icons.vertical_split_outlined,
            tooltip: split ? 'Full screen' : 'Split view',
            onTap: _toggleSplit,
          )
        : null;

    if (split) return _SplitScaffold(child: _splitBody(async, toggle!));

    return ExPage(
      title: 'Exhibitions',
      actions: [if (toggle != null) toggle],
      headerBottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _searchBox(),
          const SizedBox(height: 12),
          _filterRow(),
        ],
      ),
      floatingActionButton: ExFab(onPressed: _openCreate),
      body: _listArea(async, grid: exIsWide(context)),
    );
  }

  // MARK: Pieces

  Widget _searchBox() => _SearchBox(
        controller: _searchCtrl,
        onChanged: (q) => setState(() => _query = q.trim().toLowerCase()),
        onClear: () => setState(() {
          _searchCtrl.clear();
          _query = '';
        }),
      );

  Widget _filterRow() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in _Filter.values) ...[
              ExFilterChip(
                label: switch (f) {
                  _Filter.all => 'All',
                  _Filter.active => 'Active',
                  _Filter.completed => 'Completed',
                },
                selected: _filter == f,
                onTap: () => setState(() => _filter = f),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
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
  }) {
    final items = async.value == null ? null : _apply(async.value!);
    final state = _listState(async, items);
    if (state != null) return state;
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
                itemCount: rows,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, r) => IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = 0; c < cols; c++) ...[
                        if (c > 0) const SizedBox(width: 16),
                        Expanded(
                          child: r * cols + c < items.length
                              ? ExhibitionCard(
                                  exhibition: items[r * cols + c],
                                  onTap: () => _openDetail(items[r * cols + c]),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            })
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: pad,
              itemCount: items!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => ExhibitionCard(
                exhibition: items[i],
                selected: items[i].id == selectedId,
                onTap: () => _openDetail(items[i]),
              ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: title, search, chips, list ──
        Container(
          width: listWidth,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: exBorder)),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SafeArea(
                    bottom: false,
                    right: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              ExBackButton(onPressed: () => Navigator.maybePop(context)),
                              const SizedBox(width: 4),
                              const Expanded(child: Text('Exhibitions', style: exHeadingXl)),
                              toggle,
                            ],
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _searchBox(),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _filterRow(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
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
          child: SafeArea(
            bottom: false,
            left: false,
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
        ),
      ],
    );
  }
}

/// Bare scaffold for the iPad split (each pane draws its own header).
class _SplitScaffold extends StatelessWidget {
  final Widget child;
  const _SplitScaffold({required this.child});

  @override
  Widget build(BuildContext context) => ExTheme(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(backgroundColor: exPageBg, body: child),
        ),
      );
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({required this.controller, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, v, __) => TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: exBodyTouch,
          decoration: exInputDecoration(hint: 'Search name, city or venue').copyWith(
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 8),
              child: Icon(Icons.search_rounded, size: 22, color: exSubtle),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 52),
            suffixIcon: v.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded, color: exSubtle),
                    onPressed: onClear,
                  ),
          ),
        ),
      );
}

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
    return ExCard(
      onTap: onTap,
      highlighted: selected,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(e.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: exHeadingMd),
              ),
              const SizedBox(width: 8),
              ExStatusBadge(status: e.status),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: exSubtle, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          _Meta(icon: Icons.location_on_outlined, text: e.place.isEmpty ? 'Venue not set' : e.place),
          const SizedBox(height: 4),
          _Meta(icon: Icons.calendar_today_outlined, text: exDateRange(e.startDate, e.endDate)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ExStatChip(
                icon: Icons.people_outline_rounded,
                text: '${e.attendeeCount} ${e.attendeeCount == 1 ? 'attendee' : 'attendees'}',
              ),
              ExStatChip(
                icon: Icons.phone_outlined,
                text: '${e.demoCount} ${e.demoCount == 1 ? 'demo' : 'demos'}',
              ),
              ExStatChip(
                icon: Icons.star_outline_rounded,
                text: '${e.leadCount} ${e.leadCount == 1 ? 'lead' : 'leads'}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 17, color: exSubtle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: exSubtle),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}
