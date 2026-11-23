import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/model/ExhibitionModel.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'showcase/sc_spotlight.dart';
import 'showcase/showcase_content.dart';
import 'widget/exhibition_common.dart';

/// POST /api/mobile/exhibitions. Pops with the created [Exhibition].
/// With [initial] it edits that exhibition instead (PUT) and pops with true.
class ExhibitionCreateView extends ConsumerStatefulWidget {
  final Exhibition? initial;

  const ExhibitionCreateView({super.key, this.initial});

  @override
  ConsumerState<ExhibitionCreateView> createState() => _ExhibitionCreateViewState();
}

class _ExhibitionCreateViewState extends ConsumerState<ExhibitionCreateView> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _venue = TextEditingController(text: widget.initial?.venue ?? '');
  late final _city = TextEditingController(text: widget.initial?.city ?? '');
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  late DateTime? _start = widget.initial?.startDate;
  late DateTime? _end = widget.initial?.endDate;

  /// Picked attendees (SCORE users only), shown as chips. Older typed
  /// entries without a user id can't be sent, so they are left out.
  late final List<Attendee> _attendees = [
    ...?widget.initial?.attendees.where((a) => a.isLinked),
  ];
  late int _droppedTyped = widget.initial?.attendees.where((a) => !a.isLinked).length ?? 0;
  final _attSearch = TextEditingController();

  bool get _editing => widget.initial != null;

  /// Edit only: the full exhibition (team, notes, …) is fetched first so
  /// the form shows everything the API has, not just the list row.
  bool _loading = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    if (_editing) _loadForEdit();
  }

  Future<void> _loadForEdit() async {
    final base = widget.initial!;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      // Straight from the repository: invalidating exhibitionDetailProvider
      // here would rebuild the detail screen underneath mid-build and throw.
      final fresh = await ref.read(exhibitionRepositoryProvider).fetchExhibition(base.id);
      if (!mounted) return;
      _fill(fresh.mergedWith(base));
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e;
      });
    }
  }

  void _fill(Exhibition ex) {
    _name.text = ex.name;
    _venue.text = ex.venue;
    _city.text = ex.city;
    _notes.text = ex.notes;
    _start = ex.startDate;
    _end = ex.endDate;
    _status = ex.status;
    _attendees
      ..clear()
      ..addAll(ex.attendees.where((a) => a.isLinked));
    _droppedTyped = ex.attendees.where((a) => !a.isLinked).length;
  }

  /// Kept as-is on edit (there is no status picker); new ones start Active.
  late ExhibitionStatus _status = widget.initial?.status ?? ExhibitionStatus.active;

  bool _tried = false;
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _city.dispose();
    _notes.dispose();
    _attSearch.dispose();
    super.dispose();
  }

  bool _isPicked(AttendeeOption o) => _attendees.any((a) => a.userId == o.id);

  void _togglePick(AttendeeOption o) {
    if (_saving) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_isPicked(o)) {
        _attendees.removeWhere((a) => a.userId == o.id);
      } else {
        _attendees.add(o.toAttendee());
      }
    });
  }

  /// Everything except City and Notes is mandatory.
  bool get _hasErrors =>
      _name.text.trim().isEmpty ||
      _venue.text.trim().isEmpty ||
      _start == null ||
      _end == null ||
      _endBeforeStart ||
      _startInPast ||
      _attendees.isEmpty;

  bool get _endBeforeStart => _start != null && _end != null && _end!.isBefore(_start!);

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// A new exhibition can't start before today. An edit keeps its saved
  /// (possibly past) dates.
  bool get _startInPast => !_editing && _start != null && _start!.isBefore(_today);

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    var initial = (isStart ? _start : _end) ?? _start ?? now;
    // New exhibition: no past dates (the end can't go before the start).
    // Edit: widen the range so an older / far-off saved date can still open.
    var first = _editing ? DateTime(now.year - 2) : _today;
    if (!_editing && !isStart && _start != null && _start!.isAfter(first)) first = _start!;
    var last = DateTime(now.year + 3);
    if (_editing && initial.isBefore(first)) first = DateTime(initial.year);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) last = DateTime(initial.year, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end == null || _end!.isBefore(picked)) _end = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _serverError = null;
    });
    if (_hasErrors) return;

    final attendees = List<Attendee>.of(_attendees);

    setState(() => _saving = true);
    try {
      final req = CreateExhibitionRequest(
        name: _name.text.trim(),
        venue: _venue.text.trim(),
        city: _city.text.trim(),
        startDate: _start,
        endDate: _end,
        // New exhibitions start as Active; an edit keeps the current status.
        status: _status,
        notes: _notes.text.trim(),
        attendees: attendees,
      );
      final repo = ref.read(exhibitionRepositoryProvider);
      if (_editing) {
        await repo.updateExhibition(widget.initial!.id, req);
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }
      final created = await repo.createExhibition(req);
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = e.toString();
      });
    }
  }


  // MARK: Steps
  // One question per screen: Name → Place → Dates → Attendees → Notes → Review.

  static const _review = 5;
  static const _stepNames = ['Name', 'Place', 'Dates', 'Attendees', 'Notes', 'Review'];

  /// Edit opens on the summary (everything is filled in already).
  late int _step = _editing ? _review : 0;

  /// Steps where Next was tapped while something was missing; their
  /// errors show from then on.
  final Set<int> _triedSteps = {};

  /// Once the summary was reached, Next from an edited step returns there.
  late bool _reachedReview = _editing;

  bool _showErrors(int step) => _tried || _triedSteps.contains(step);

  bool _stepValid(int step) => switch (step) {
        0 => _name.text.trim().isNotEmpty,
        1 => _venue.text.trim().isNotEmpty,
        2 => _start != null && _end != null && !_endBeforeStart && !_startInPast,
        3 => _attendees.isNotEmpty,
        _ => true,
      };

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      if (step == _review) _reachedReview = true;
    });
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_stepValid(_step)) {
      HapticFeedback.mediumImpact();
      setState(() => _triedSteps.add(_step));
      return;
    }
    _goTo(_reachedReview ? _review : _step + 1);
  }

  void _back() {
    if (_saving) return;
    if (_editing && _step != _review) {
      _goTo(_review);
    } else if (_step > 0) {
      _goTo(_step - 1);
    }
  }

  /// Save from the summary; a missing value jumps back to its step.
  void _save() {
    for (var i = 0; i < _review; i++) {
      if (!_stepValid(i)) {
        setState(() => _triedSteps.add(i));
        _goTo(i);
        return;
      }
    }
    _submit();
  }

  int get _home => _editing ? _review : 0;

  /// Cities from exhibitions already loaded (no extra API call).
  List<String> get _recentCities {
    if (!ref.exists(exhibitionListProvider)) return const [];
    final all = ref.read(exhibitionListProvider).value ?? const <Exhibition>[];
    final seen = <String>{};
    return [
      for (final e in all)
        if (e.city.trim().isNotEmpty && seen.add(e.city.trim().toLowerCase())) e.city.trim(),
    ].take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wide = exIsWide(context);
    final ready = !_loading && _loadError == null;

    return PopScope(
      canPop: _step == _home && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ExTheme(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: exHeaderOverlay,
          child: Scaffold(
            backgroundColor: exHeaderBase,
            body: Column(
              children: [
                ExGradientHeader(
                  child: Row(
                    children: [
                      ExHeaderIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        onTap: _saving ? null : () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _editing ? 'Edit exhibition' : 'New exhibition',
                          style: exHeadingMd.copyWith(
                              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ExCurvedBody(
                    child: Column(
                      children: [
                        if (_loading)
                          const Expanded(
                            child: Center(child: CircularProgressIndicator(color: exBrandBold)),
                          )
                        else if (_loadError != null)
                          Expanded(
                            child: Center(
                              child: ExStateView.error(
                                _loadError!,
                                title: "Couldn't load exhibition",
                                onRetry: _loadForEdit,
                              ),
                            ),
                          )
                        else ...[
                          Padding(
                            padding: EdgeInsets.fromLTRB(wide ? 24 : 20, 20, wide ? 24 : 20, 0),
                            child: ExMaxWidth(
                              maxWidth: exFormMaxWidth,
                              child: ExStepProgress(
                                current: _step,
                                total: _stepNames.length,
                                label: 'Step ${_step + 1} of ${_stepNames.length} · ${_stepNames[_step]}',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(wide ? 24 : 20, 24, wide ? 24 : 20, 24),
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                    child: ExMaxWidth(
                                      maxWidth: exFormMaxWidth,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Phones: School Chimes ERP banner above the step.
                                          if (!wide) ...[
                                            ScSpotlightBanner(spot: _spotlight),
                                            const SizedBox(height: 22),
                                          ],
                                          ExStepSwitcher(step: _step, child: _stepBody()),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // iPad: one School Chimes ERP solution beside each step.
                                if (wide)
                                  Container(
                                    width: 380,
                                    decoration: const BoxDecoration(
                                      color: scSoft,
                                      border: Border(left: BorderSide(color: exBorder)),
                                    ),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(20, 22, 22, 24),
                                      child: ScErpPanel(spot: _spotlight),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (ready)
                  ExStepBar(
                    onBack: _step == _home ? null : _back,
                    nextLabel: _nextLabel,
                    nextIcon: _step == _review ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    loading: _saving,
                    loadingLabel: _editing ? 'Updating…' : 'Creating…',
                    onNext: _step == _review ? _save : _next,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// School Chimes ERP topic shown with the current step.
  ScSpotlight get _spotlight =>
      scCreateExhibitionSpotlights[_step.clamp(0, scCreateExhibitionSpotlights.length - 1)];

  String get _nextLabel {
    if (_step == _review) return _editing ? 'Update Exhibition' : 'Create Exhibition';
    if (_reachedReview) return 'Done';
    if (_step == 4 && _notes.text.trim().isEmpty) return 'Skip';
    return 'Next';
  }

  Widget _stepBody() => switch (_step) {
        0 => _nameStep(),
        1 => _placeStep(),
        2 => _datesStep(),
        3 => _teamStep(),
        4 => _notesStep(),
        _ => _reviewStep(),
      };

  Widget _gap([double h = 24]) => SizedBox(height: h);

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(text, style: exLabelSm.copyWith(fontSize: 13, color: const Color(0xFF3A4A60))),
      );

  // 1 · Name
  Widget _nameStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExQuestion(
            icon: Icons.storefront_rounded,
            title: "What's the exhibition called?",
            subtitle: 'Use the name people know it by.',
          ),
          _gap(28),
          ExBigInput(
            controller: _name,
            autofocus: true,
            hint: 'e.g. DIDAC India 2026',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            errorText: _showErrors(0) && !_stepValid(0) ? 'Exhibition name is required' : null,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _next(),
          ),
        ],
      );

  // 2 · Place
  Widget _placeStep() {
    final cities = _recentCities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExQuestion(
          icon: Icons.location_on_rounded,
          title: 'Where is the show?',
          subtitle: 'The venue helps the team find the stall.',
        ),
        _gap(28),
        _label('VENUE'),
        ExBigInput(
          controller: _venue,
          autofocus: true,
          icon: Icons.place_outlined,
          hint: 'e.g. Bombay Exhibition Centre',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          errorText: _showErrors(1) && !_stepValid(1) ? 'Venue is required' : null,
          onChanged: (_) => setState(() {}),
        ),
        _gap(20),
        _label('CITY  ·  OPTIONAL'),
        ExBigInput(
          controller: _city,
          icon: Icons.location_city_rounded,
          hint: 'e.g. Mumbai',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _next(),
        ),
        if (cities.isNotEmpty) ...[
          _gap(14),
          ExAppear(
            index: 4,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Recent:', style: exBodyMd),
                for (final c in cities)
                  ExPickChip(
                    label: c,
                    icon: Icons.history_rounded,
                    selected: _city.text.trim().toLowerCase() == c.toLowerCase(),
                    onTap: () => setState(() => _city.text = c),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 3 · Dates
  Widget _datesStep() {
    final show = _showErrors(2);
    final startError = !show
        ? null
        : _start == null
            ? 'Start date is required'
            : _startInPast
                ? "Start date can't be in the past"
                : null;
    final endError = !show
        ? null
        : _end == null
            ? 'End date is required'
            : _endBeforeStart
                ? "End date can't be before the start date"
                : null;
    final days = _start != null && _end != null && !_endBeforeStart
        ? _end!.difference(_start!).inDays + 1
        : null;
    final start = _DateCard(
      label: 'STARTS',
      value: _start,
      error: startError,
      onTap: () => _pickDate(true),
    );
    final end = _DateCard(
      label: 'ENDS',
      value: _end,
      error: endError,
      onTap: () => _pickDate(false),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExQuestion(
          icon: Icons.event_rounded,
          title: 'When is it on?',
          subtitle: 'Tap a card to pick the date.',
        ),
        _gap(28),
        ExAppear(
          index: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: start),
              const SizedBox(width: 12),
              Expanded(child: end),
            ],
          ),
        ),
        if (days != null) ...[
          _gap(16),
          Center(
            child: ExPopIn(
              key: ValueKey(days),
              child: ExPill(
                label: '$days ${days == 1 ? 'day' : 'days'}',
                icon: Icons.schedule_rounded,
                background: exTint,
                foreground: exBrandBold,
                large: true,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 4 · Team (picked from SCORE users; never typed)
  Widget _teamStep() {
    final error = _showErrors(3) && _attendees.isEmpty ? 'Pick at least one attendee' : null;
    final options = ref.watch(exhibitionAttendeeOptionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExQuestion(
          icon: Icons.groups_rounded,
          color: exAccentTeam,
          background: exAccentTeamBg,
          title: "Who's at the stall?",
          subtitle: 'Pick SCORE users. They get a call on every demo, so they hear what visitors hear.',
        ),
        _gap(20),
        if (_attendees.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: error != null ? exDangerBg : exPageBg,
              borderRadius: BorderRadius.circular(exRadiusControl),
            ),
            child: Row(
              children: [
                Icon(Icons.group_add_outlined, size: 24, color: error != null ? exDanger : exSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(error ?? 'No one picked yet.',
                      style: exBodyMd.copyWith(
                          color: error != null ? exDanger : exSubtle,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )
        else ...[
          ExPill(
            label: 'On the team · ${_attendees.length}',
            icon: Icons.check_circle_rounded,
            background: exSuccessBg,
            foreground: exSuccess,
          ),
          _gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in _attendees)
                ExPopIn(
                  key: ValueKey('att-${a.userId}'),
                  child: ExPersonChip(
                    name: a.name,
                    number: a.mobile.isEmpty ? 'No mobile in SCORE' : formatIndianMobile(a.mobile),
                    onRemove: () {
                      if (!_saving) setState(() => _attendees.remove(a));
                    },
                  ),
                ),
            ],
          ),
        ],
        if (_droppedTyped > 0) ...[
          _gap(12),
          Text(
            '$_droppedTyped typed ${_droppedTyped == 1 ? 'entry is' : 'entries are'} not SCORE '
            'users and will be removed on save. Pick them from the list below.',
            style: exBodyMd.copyWith(color: exSubtle),
          ),
        ],
        _gap(20),
        ExBigInput(
          controller: _attSearch,
          icon: Icons.search_rounded,
          hint: 'Search name, employee ID or role',
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
        ),
        _gap(12),
        options.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ExStateView.error(
            e,
            title: "Couldn't load SCORE users",
            message: e.toString(),
            onRetry: () => ref.invalidate(exhibitionAttendeeOptionsProvider),
          ),
          data: (all) {
            final q = _attSearch.text.trim().toLowerCase();
            final list = q.isEmpty
                ? all
                : all
                    .where((o) =>
                        o.name.toLowerCase().contains(q) ||
                        o.employeeId.toLowerCase().contains(q) ||
                        o.roleName.toLowerCase().contains(q))
                    .toList();
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(all.isEmpty ? 'No SCORE users available.' : 'No one matches "${_attSearch.text.trim()}".',
                    textAlign: TextAlign.center, style: exBodyMd.copyWith(color: exSubtle)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final o in list) _optionTile(o)],
            );
          },
        ),
      ],
    );
  }

  Widget _optionTile(AttendeeOption o) {
    final picked = _isPicked(o);
    final sub = [
      if (o.roleName.isNotEmpty) o.roleName,
      if (o.employeeId.isNotEmpty) 'ID ${o.employeeId}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: picked ? exTint : Colors.white,
        borderRadius: BorderRadius.circular(exRadiusControl),
        child: InkWell(
          borderRadius: BorderRadius.circular(exRadiusControl),
          onTap: () => _togglePick(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(exRadiusControl),
              border: Border.all(color: picked ? exIndicator : exBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: exAccentTeamBg,
                  child: Text(exInitials(o.name),
                      style: const TextStyle(
                          fontFamily: exFont, fontSize: 12, fontWeight: FontWeight.w700, color: exAccentTeam)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: exHeadingSm),
                      if (sub.isNotEmpty)
                        Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: exBodyMd.copyWith(color: exSubtle)),
                      Text(
                        o.hasPhone && o.phone.isNotEmpty
                            ? formatIndianMobile(o.phone)
                            : 'No mobile in SCORE · won\'t be called',
                        maxLines: 2,
                        style: exBodyMd.copyWith(
                            color: o.hasPhone ? exSubtle : exDanger, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  picked ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  color: picked ? exSuccess : exSubtle,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 5 · Notes
  Widget _notesStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExQuestion(
            icon: Icons.sticky_note_2_rounded,
            color: exAccentLead,
            background: exAccentLeadBg,
            title: 'Anything to remember?',
            subtitle: 'Hall, stall number, timings… Skip if there is nothing.',
            optional: true,
          ),
          _gap(28),
          ExBigInput(
            controller: _notes,
            hint: 'e.g. Hall 3, Stall 42',
            maxLines: 5,
            onChanged: (_) => setState(() {}),
          ),
        ],
      );

  // 6 · Review
  Widget _reviewStep() {
    final where = [_venue.text.trim(), _city.text.trim()].where((s) => s.isNotEmpty).join(', ');
    final team = _attendees.isEmpty
        ? ''
        : '${_attendees.length} ${_attendees.length == 1 ? 'person' : 'people'} · '
            '${_attendees.map((a) => a.name).join(', ')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExQuestion(
          icon: Icons.fact_check_rounded,
          color: exSuccess,
          background: exSuccessBg,
          title: _editing ? 'Check your changes' : 'All set?',
          subtitle: 'Tap any line to change it.',
        ),
        _gap(24),
        ExAppear(
          index: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(exRadiusCard + 4),
              boxShadow: exCardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name banner
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: const BoxDecoration(gradient: exHeroGradient),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(exRadiusControl),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _name.text.trim().isEmpty ? 'Untitled exhibition' : _name.text.trim(),
                          style: const TextStyle(
                              fontSize: 20, height: 1.25, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit name',
                        onPressed: _saving ? null : () => _goTo(0),
                        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    children: [
                      ExSummaryRow(
                        icon: Icons.location_on_rounded,
                        label: 'Place',
                        value: where,
                        onEdit: _saving ? null : () => _goTo(1),
                      ),
                      ExSummaryRow(
                        icon: Icons.event_rounded,
                        label: 'Dates',
                        value: _start == null && _end == null ? '' : exDateRange(_start, _end),
                        onEdit: _saving ? null : () => _goTo(2),
                      ),
                      ExSummaryRow(
                        icon: Icons.groups_rounded,
                        color: exAccentTeam,
                        background: exAccentTeamBg,
                        label: 'Attendees',
                        value: team,
                        onEdit: _saving ? null : () => _goTo(3),
                      ),
                      ExSummaryRow(
                        icon: Icons.sticky_note_2_rounded,
                        color: exAccentLead,
                        background: exAccentLeadBg,
                        label: 'Notes',
                        value: _notes.text.trim(),
                        onEdit: _saving ? null : () => _goTo(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_serverError != null) ...[
          _gap(16),
          ExInlineNote(message: _serverError!),
        ],
      ],
    );
  }
}

/// Big tappable date card: label, day number, month and year, weekday.
class _DateCard extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? error;

  const _DateCard({required this.label, required this.value, required this.onTap, this.error});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    final v = value;
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: v == null ? '$label, not set' : '$label ${exDateRange(v, v)}',
          excludeSemantics: true,
          child: Material(
            color: v == null ? Colors.white : exTint,
            borderRadius: BorderRadius.circular(exRadiusCard),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(exRadiusCard),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 132,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(exRadiusCard),
                  border: Border.all(
                    color: hasError ? exDanger : (v == null ? exBorder : exBrand),
                    width: hasError || v != null ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(label,
                              style: exLabelSm.copyWith(color: v == null ? exSubtle : exBrandBold)),
                        ),
                        Icon(Icons.event_rounded, size: 18, color: v == null ? exSubtle : exBrandBold),
                      ],
                    ),
                    const Spacer(),
                    if (v == null)
                      const Row(
                        children: [
                          Icon(Icons.add_circle_rounded, size: 22, color: exBrand),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text('Pick date',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700, color: exBrandBold)),
                          ),
                        ],
                      )
                    else ...[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: '${v.day} ',
                            style: const TextStyle(
                                fontSize: 32, height: 1, fontWeight: FontWeight.w800, color: exInk),
                            children: [
                              TextSpan(
                                text: '${_months[v.month - 1]} ${v.year}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700, color: exInk),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_days[v.weekday - 1],
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: exBodySm),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(error!,
              style: const TextStyle(
                  fontFamily: exFont, fontSize: 13, fontWeight: FontWeight.w600, color: exDanger)),
        ],
      ],
    );
  }
}
