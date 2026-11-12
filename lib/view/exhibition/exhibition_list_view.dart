import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/ExhibitionModel.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'exhibition_create_view.dart';
import 'exhibition_detail_view.dart';
import 'widget/exhibition_common.dart';

enum _Filter { all, active, completed }

/// Home of the Exhibitions module: every trade show, newest first.
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

  /// What the right side actually shows (the tapped one, or the default).
  String? _shownId;

  /// iPad only: the user's choice between split view and full screen.
  /// Remembered across launches.
  bool _splitPref = true;
  static const _splitPrefKey = 'exhibition_ipad_split_view';

  /// Split is used only on an iPad-sized window and when the user wants it.
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
    setState(() {
      _splitPref = !_splitPref;
      // Each layout has its own search box, so start the new one clean.
      _query = '';
      _searchCtrl.clear();
    });
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

  void _refreshAll() {
    ref.invalidate(exhibitionListProvider);
    final id = _shownId;
    if (id != null && _useSplit) refreshExhibition(ref, id);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(exhibitionListProvider);
    final tablet = exIsSplit(context);
    final split = tablet && _splitPref;

    return ExPage(
      title: 'Exhibitions',
      searchHint: 'Search name, city or venue',
      // On iPad the search box lives inside the list pane instead.
      onSearch: split ? null : (q) => setState(() => _query = q.trim().toLowerCase()),
      onRefresh: _refreshAll,
      // iPad only: switch between split view and full-screen list.
      trailing: tablet
          ? ExToolbarButton(
              icon: split ? Icons.fullscreen_rounded : Icons.vertical_split_rounded,
              tooltip: split ? 'Full screen' : 'Split view',
              onTap: _toggleSplit,
            )
          : null,
      floatingActionButton: split
          ? null
          : FloatingActionButton.extended(
              heroTag: 'exhibition_create',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Exhibition', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(split),
          child: split ? _splitBody(async) : _phoneBody(async),
        ),
      ),
    );
  }

  Widget _filterRow(List<Exhibition>? all) {
    int count(_Filter f) => all == null
        ? 0
        : switch (f) {
            _Filter.all => all.length,
            _Filter.active => all.where((e) => e.status == ExhibitionStatus.active).length,
            _Filter.completed => all.where((e) => e.status == ExhibitionStatus.completed).length,
          };
    return _FilterTabs(
      selected: _filter,
      counts: {for (final f in _Filter.values) f: count(f)},
      onChanged: (f) => setState(() => _filter = f),
    );
  }

  /// Empty / no-match / error states shared by both layouts, or null when
  /// there is something to list.
  Widget? _listState(AsyncValue<List<Exhibition>> async, List<Exhibition>? items) {
    return async.when(
      loading: () => const ExMaxWidth(child: ExSkeletonList()),
      error: (e, _) => ExStateView.error(e, onRetry: () => ref.invalidate(exhibitionListProvider)),
      data: (all) {
        if (all.isEmpty) {
          return ExStateView(
            icon: Icons.storefront_rounded,
            title: 'No exhibitions yet',
            message: 'Create your first trade show to start giving demos and capturing leads.',
            actionLabel: 'Create exhibition',
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

  Widget _phoneBody(AsyncValue<List<Exhibition>> async) {
    final items = async.value == null ? null : _apply(async.value!);
    final state = _listState(async, items);
    return Column(
      children: [
        ExMaxWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: _filterRow(async.value),
          ),
        ),
        Expanded(
          child:
              state ??
              RefreshIndicator(
                onRefresh: () => ref.refresh(exhibitionListProvider.future),
                child: _ExhibitionGrid(items: items!, onTap: _openDetail),
              ),
        ),
      ],
    );
  }

  Widget _splitBody(AsyncValue<List<Exhibition>> async) {
    final all = async.value;
    final items = all == null ? null : _apply(all);
    final state = _listState(async, items);

    // The right side always matches a highlighted card in the visible list:
    // if the tab / search hides the chosen exhibition, jump to the first
    // visible one. Only when nothing matches keep showing the last choice.
    Exhibition? selected;
    if (all != null && all.isNotEmpty) {
      final visible = items ?? const <Exhibition>[];
      selected = visible.isNotEmpty
          ? visible.firstWhere((e) => e.id == _selectedId, orElse: () => visible.first)
          : all.firstWhere((e) => e.id == _selectedId, orElse: () => all.first);
    }

    _shownId = selected?.id;

    final width = MediaQuery.sizeOf(context).width;
    final listWidth = (width * 0.36).clamp(320.0, 420.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: search, filters, list ──
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _SearchBox(
                      controller: _searchCtrl,
                      onChanged: (q) => setState(() => _query = q.trim().toLowerCase()),
                      onClear: () => setState(() {
                        _searchCtrl.clear();
                        _query = '';
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: _filterRow(async.value),
                  ),
                  Expanded(
                    child:
                        state ??
                        RefreshIndicator(
                          onRefresh: () => ref.refresh(exhibitionListProvider.future),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                            itemCount: items!.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => ExhibitionCard(
                              exhibition: items[i],
                              selected: items[i].id == selected?.id,
                              onTap: () => _openDetail(items[i]),
                            ),
                          ),
                        ),
                  ),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 24,
                child: FloatingActionButton(
                  heroTag: 'exhibition_create',
                  tooltip: 'New exhibition',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  onPressed: _openCreate,
                  child: const Icon(Icons.add_rounded, size: 30),
                ),
              ),
            ],
          ),
        ),
        // ── Right: the selected exhibition ──
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.02, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: selected == null
                ? const ExStateView(
                    key: ValueKey('none'),
                    icon: Icons.storefront_rounded,
                    title: 'Select an exhibition',
                    message: 'Pick a trade show on the left to see its demos and leads.',
                  )
                : ExhibitionDetailPane(
                    key: ValueKey(selected.id),
                    exhibitionId: selected.id,
                    initial: selected,
                  ),
          ),
        ),
      ],
    );
  }
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
      style: const TextStyle(fontSize: 16, color: exInk),
      decoration: InputDecoration(
        hintText: 'Search name, city or venue',
        hintStyle: const TextStyle(fontSize: 15, color: exSubtle),
        prefixIcon: const Icon(Icons.search_rounded, color: exSubtle),
        suffixIcon: v.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded, color: exSubtle),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: exPageBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    ),
  );
}

class _ExhibitionGrid extends StatelessWidget {
  final List<Exhibition> items;
  final ValueChanged<Exhibition> onTap;

  const _ExhibitionGrid({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final wide = exIsWide(context);
    if (!wide) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => ExhibitionCard(exhibition: items[i], onTap: () => onTap(items[i])),
      );
    }
    // Tablet: two columns.
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
      itemCount: (items.length + 1) ~/ 2,
      itemBuilder: (_, row) {
        final a = items[row * 2];
        final b = row * 2 + 1 < items.length ? items[row * 2 + 1] : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ExhibitionCard(exhibition: a, onTap: () => onTap(a)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: b == null
                      ? const SizedBox()
                      : ExhibitionCard(exhibition: b, onTap: () => onTap(b)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  e.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: exInk),
                ),
              ),
              const SizedBox(width: 8),
              ExStatusBadge(status: e.status),
            ],
          ),
          const SizedBox(height: 8),
          _Meta(icon: Icons.place_outlined, text: e.place.isEmpty ? 'Venue not set' : e.place),
          const SizedBox(height: 4),
          _Meta(icon: Icons.calendar_today_outlined, text: exDateRange(e.startDate, e.endDate)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Stat(
                icon: Icons.groups_outlined,
                text: '${e.attendeeCount} ${e.attendeeCount == 1 ? 'attender' : 'attenders'}',
              ),
              _Stat(
                icon: Icons.phone_in_talk_outlined,
                text: '${e.demoCount} ${e.demoCount == 1 ? 'demo' : 'demos'}',
              ),
              _Stat(
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
      Icon(icon, size: 16, color: exSubtle),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13.5, color: exSubtle),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Stat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: exPageBg, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: exInk),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: exInk),
        ),
      ],
    ),
  );
}

/// iOS-style segmented tabs: All / Active / Completed with live counts.
class _FilterTabs extends StatelessWidget {
  final _Filter selected;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onChanged;

  const _FilterTabs({required this.selected, required this.counts, required this.onChanged});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // Same text size on every tab; on narrow widths drop the icons
      // instead of shrinking only the longest label.
      final compact = box.maxWidth < 380;
      return Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          // Stretch so the selected white card fills the track's full height.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final f in _Filter.values)
              Expanded(
                // "Completed" is the longest label, give it more room.
                flex: f == _Filter.completed ? 4 : 3,
                child: _segment(f, compact),
              ),
          ],
        ),
      );
    },
  );

  Widget _segment(_Filter f, bool compact) {
    final on = selected == f;
    final (label, accent) = switch (f) {
      _Filter.all => ('All', AppColors.primary),
      _Filter.active => ('Active', const Color(0xFF16A34A)),
      _Filter.completed => ('Completed', const Color(0xFF64748B)),
    };
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: on
                ? const [BoxShadow(color: Color(0x1A1A2235), blurRadius: 8, offset: Offset(0, 2))]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (compact)
                const SizedBox.shrink()
              else if (f == _Filter.active)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                )
              else if (f == _Filter.completed)
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Icon(Icons.check_circle_rounded, size: 15, color: accent),
                ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                    color: on ? exInk : exSubtle,
                  ),
                ),
              ),
              SizedBox(width: compact ? 4 : 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: on ? accent : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${counts[f] ?? 0}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : exSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
