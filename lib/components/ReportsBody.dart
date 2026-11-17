import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sssbuddy/components/CustomDropdown.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/OverallTripDetailsModel.dart';
import '../provider/app_providers.dart';
import '../view/TripExcelExporter.dart';
import '../viewModel/overall_trip_viewmodel.dart';
import '../viewModel/reporting_members_dd_viewmodel.dart';
import 'EmptyState.dart';
import 'MemberDropdown.dart';
import 'MonthDropdown.dart';
import 'ResponsiveCardList.dart';
import 'TodayEntryBar.dart';
import 'TripCard.dart';
import 'TripRouteMap.dart';
import '../auth/model/ReportingMembersModel.dart';
import '../view/root_tracker.dart';

class ReportsBody extends ConsumerStatefulWidget {
  const ReportsBody({super.key});

  @override
  ConsumerState<ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends ConsumerState<ReportsBody> {

  // Currently expanded trip
  int? expandedTripId;

  // Ensures auto-select of the first member happens only once
  bool _autoSelected = false;

  // Selected month filter (first-of-month, day = 1). Null = default to the
  // most recent month available in the loaded trips.
  DateTime? _selectedMonth;

  // Optional specific-date filter within the selected month. When set, the
  // day-wise list narrows to just this single day. Null = show every day of
  // the selected month.
  DateTime? _selectedDate;

  // True while the Excel report is being generated / shared.
  bool _exporting = false;

  /// The 12 months of the current calendar year (Jan → Dec), most recent
  /// first. e.g. for 2026 → Dec 2026 … Jan 2026.
  List<DateTime> _currentYearMonths(DateTime now) {
    final months = <DateTime>[
      for (var month = 1; month <= 12; month++) DateTime(now.year, month),
    ];
    months.sort((a, b) => b.compareTo(a)); // most recent first
    return months;
  }

  /// Builds the Excel report for what is currently listed on screen
  /// (selected month, or the single selected date) and opens the share sheet.
  Future<void> _exportReport({
    required DateTime month,
    DateTime? date,
    required List<int> days,
    required Map<int, List<Overalltripdetailsmodel>> tripsByDay,
    required String username,
  }) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await TripExcelExporter.exportAndShare(
        month: month,
        date: date,
        days: days,
        tripsByDay: tripsByDay,
        username: username,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Width from which the page switches to the two-pane iPad layout.
  static const double _wideBreakpoint = 700;

  /// Month / date filtering and day-wise grouping of the loaded trips.
  _MonthView _computeView(List<Overalltripdetailsmodel> allTrips) {
    final now = DateTime.now();
    final months = _currentYearMonths(now);

    // Default to the current month.
    DateTime selected = _selectedMonth ?? DateTime(now.year, now.month);

    // Snap to the exact list instance so DropdownButton matches.
    selected = months.firstWhere(
      (m) => m.year == selected.year && m.month == selected.month,
      orElse: () => months.first,
    );

    final filtered = allTrips.where((t) {
      final d = t.startDateTime;
      return d != null && d.year == selected.year && d.month == selected.month;
    }).toList();

    // Group the month's trips by day-of-month.
    final Map<int, List<Overalltripdetailsmodel>> tripsByDay = {};
    for (final t in filtered) {
      final d = t.startDateTime;
      if (d == null) continue;
      tripsByDay.putIfAbsent(d.day, () => []).add(t);
    }

    final isCurrentMonth =
        selected.year == now.year && selected.month == now.month;
    final isFutureMonth = selected.isAfter(DateTime(now.year, now.month));

    // Last day to list: today for the current month, otherwise the full
    // month. (day 0 of next month = last day of this one)
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
    final lastDay = isCurrentMonth ? now.day : daysInMonth;

    // Only honour the date filter when it falls inside the selected month
    // and is not in the future.
    final DateTime? activeDate = (_selectedDate != null &&
            _selectedDate!.year == selected.year &&
            _selectedDate!.month == selected.month &&
            _selectedDate!.day <= lastDay)
        ? _selectedDate
        : null;

    // Days to render, most recent first. A specific date collapses the list
    // to that single day.
    final days = <int>[
      if (activeDate != null)
        activeDate.day
      else
        for (var d = lastDay; d >= 1; d--) d,
    ];

    // Summary reflects exactly what's listed.
    final displayTrips = activeDate != null
        ? (tripsByDay[activeDate.day] ?? const <Overalltripdetailsmodel>[])
        : filtered;
    final displayKm =
        displayTrips.fold<double>(0, (sum, t) => sum + t.totalDistanceKm);

    final daysWithEntry =
        isFutureMonth ? 0 : days.where((d) => tripsByDay[d]?.isNotEmpty ?? false).length;

    return _MonthView(
      months: months,
      selected: selected,
      activeDate: activeDate,
      lastDay: lastDay,
      isFutureMonth: isFutureMonth,
      days: days,
      tripsByDay: tripsByDay,
      displayTrips: displayTrips,
      displayKm: displayKm,
      daysWithEntry: daysWithEntry,
      daysWithoutEntry: isFutureMonth ? 0 : days.length - daysWithEntry,
    );
  }

  void _onMemberChanged(Reportingmembersmodel? member) {
    setState(() {
      expandedTripId = null;
      // Reset the month/date filters so the new member defaults back to the
      // current month.
      _selectedMonth = null;
      _selectedDate = null;
    });

    ref.read(selectedMemberProvider.notifier).state = member;

    if (member != null) {
      ref.read(overallTripProvider.notifier).loadForMember(member.idmember);
    }
  }

  Widget _memberSection(
    AsyncValue<List<Reportingmembersmodel>> membersAsync,
    Reportingmembersmodel? selectedMember,
  ) {
    return membersAsync.when(
      loading: () => const CustomDropdown(),
      error: (e, _) => Text(
        'Error loading members: $e',
        style: const TextStyle(color: Colors.red),
      ),
      data: (members) => MemberDropdown(
        members: members,
        selected: selectedMember,
        onChanged: _onMemberChanged,
      ),
    );
  }

  /// Month dropdown + specific-date filter.
  Widget _filterRow(_MonthView v) {
    return Row(
      children: [
        Expanded(
          child: MonthDropdown(
            months: v.months,
            selected: v.selected,
            onChanged: (m) {
              setState(() {
                _selectedMonth = m;
                // A new month invalidates the day filter.
                _selectedDate = null;
                expandedTripId = null;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        _DateFilterButton(
          selectedDate: v.activeDate,
          onPick: () async {
            final firstDate = DateTime(v.selected.year, v.selected.month, 1);
            final lastDate =
                DateTime(v.selected.year, v.selected.month, v.lastDay);
            final picked = await showDatePicker(
              context: context,
              initialDate: v.activeDate ?? lastDate,
              firstDate: firstDate,
              lastDate: lastDate,
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
                expandedTripId = null;
              });
            }
          },
          onClear: () {
            setState(() {
              _selectedDate = null;
              expandedTripId = null;
            });
          },
        ),
      ],
    );
  }

  Widget _summaryCard(_MonthView v) => _TotalDistanceCard(
        month: v.selected,
        date: v.activeDate,
        totalKm: v.displayKm,
        tripCount: v.displayTrips.length,
      );

  /// Header + route map (date filter) + trips (or "no entry") for one day.
  Widget _dayItem(
    _MonthView v,
    int day,
    Reportingmembersmodel? selectedMember, {
    double mapHeight = 240,
  }) {
    final date = DateTime(v.selected.year, v.selected.month, day);
    final dayTrips = v.tripsByDay[day] ?? const <Overalltripdetailsmodel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEE, dd MMM yyyy').format(date),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        // Date picked → that day's route on a map
        if (v.activeDate != null && dayTrips.isNotEmpty)
          _DayRouteMapCard(
            trips: dayTrips,
            date: date,
            member: selectedMember,
            mapHeight: mapHeight,
          ),

        // Trips for the day OR no-entry note
        if (dayTrips.isEmpty)
          const _NoEntryTile()
        else
          ...dayTrips.map(
            (trip) => TripCard(
              trip: trip,
              isExpanded: expandedTripId == trip.trip_id,
              onViewRouteMap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RootTrackerScreen(
                    initialMember: selectedMember,
                    initialDate: date,
                    initialShowMap: true,
                  ),
                ),
              ),
              onExpand: () {
                setState(() {
                  expandedTripId =
                      expandedTripId == trip.trip_id ? null : trip.trip_id;
                });
              },
            ),
          ),
      ],
    );
  }

  /// Day-wise list. On iPad the month view becomes a two-column grid of days;
  /// a single picked date stays one wide column with a taller map.
  Widget _dayList(
    _MonthView v,
    Reportingmembersmodel? selectedMember, {
    required bool wide,
  }) {
    if (v.isFutureMonth) {
      return const EmptyState(
        message: 'No entry found for the selected month.',
      );
    }

    if (!wide) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: v.days.length,
        itemBuilder: (_, index) =>
            _dayItem(v, v.days[index], selectedMember),
      );
    }

    if (v.activeDate != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          _dayItem(v, v.activeDate!.day, selectedMember, mapHeight: 420),
        ],
      );
    }

    return ResponsiveCardList(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      itemCount: v.days.length,
      spacing: 8,
      columnSpacing: 20,
      minItemWidth: 320,
      maxColumns: 2,
      itemBuilder: (_, index) => _dayItem(v, v.days[index], selectedMember),
    );
  }

  /// Wraps the trip area with the member / loading / error / empty states.
  Widget _tripsState(
    AsyncValue<List<Overalltripdetailsmodel>> tripsAsync,
    Reportingmembersmodel? selectedMember,
    Widget Function(_MonthView v) builder,
  ) {
    if (selectedMember == null) return const EmptyState();

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load trips: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref
                    .read(overallTripProvider.notifier)
                    .loadForMember(selectedMember.idmember),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (allTrips) {
        if (allTrips.isEmpty) {
          return const EmptyState(message: 'No trips found for this member.');
        }
        return builder(_computeView(allTrips));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(reportingmembersProvider);
    final selectedMember = ref.watch(selectedMemberProvider);
    final tripsAsync = ref.watch(overallTripProvider);

    // ─────────────────────────────────
    // AUTO-SELECT 0th MEMBER ON FIRST LOAD
    // ─────────────────────────────────
    if (!_autoSelected && membersAsync.hasValue) {
      final members = membersAsync.value!;

      if (members.isNotEmpty) {
        _autoSelected = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedMemberProvider.notifier).state = members[0];
          ref
              .read(overallTripProvider.notifier)
              .loadForMember(members[0].idmember);
        });
      }
    }

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _wideBreakpoint) {
            return _wideLayout(
              constraints,
              membersAsync,
              selectedMember,
              tripsAsync,
            );
          }
          return _phoneLayout(membersAsync, selectedMember, tripsAsync);
        },
      ),
    );
  }

  Widget _phoneLayout(
    AsyncValue<List<Reportingmembersmodel>> membersAsync,
    Reportingmembersmodel? selectedMember,
    AsyncValue<List<Overalltripdetailsmodel>> tripsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODAY'S ENTRY STATUS (entered / no entry)
        const TodayEntryBar(),

        // MEMBER DROPDOWN
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _memberSection(membersAsync, selectedMember),
        ),

        const SizedBox(height: 16),

        // TRIP LIST
        Expanded(
          child: _tripsState(
            tripsAsync,
            selectedMember,
            (v) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _filterRow(v),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _summaryCard(v),
                ),
                Expanded(child: _dayList(v, selectedMember, wide: false)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// iPad / tablet: filters + summary in a left panel, day-wise trips on the
  /// right as a card grid.
  Widget _wideLayout(
    BoxConstraints constraints,
    AsyncValue<List<Reportingmembersmodel>> membersAsync,
    Reportingmembersmodel? selectedMember,
    AsyncValue<List<Overalltripdetailsmodel>> tripsAsync,
  ) {
    final panelWidth = (constraints.maxWidth * 0.34).clamp(300.0, 400.0);
    final view = (selectedMember != null &&
            tripsAsync.hasValue &&
            !tripsAsync.isLoading &&
            tripsAsync.value!.isNotEmpty)
        ? _computeView(tripsAsync.value!)
        : null;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left panel: who / when / summary ──
          Container(
            width: panelWidth,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              border: Border(
                right: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              children: [
                const _PanelLabel('Team member'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _memberSection(membersAsync, selectedMember),
                ),
                if (view != null) ...[
                  const SizedBox(height: 20),
                  const _PanelLabel('Period'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _filterRow(view),
                  ),
                  const SizedBox(height: 20),
                  const _PanelLabel('Summary'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _summaryCard(view),
                  ),
                  if (!view.isFutureMonth && view.activeDate == null) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.event_available_rounded,
                              color: Colors.green.shade600,
                              value: '${view.daysWithEntry}',
                              label: 'Days with entry',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.event_busy_rounded,
                              color: Colors.red.shade400,
                              value: '${view.daysWithoutEntry}',
                              label: 'No entry',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                const _PanelLabel('Today'),
                const TodayEntryBar(),
              ],
            ),
          ),

          // ── Right: day-wise trips ──
          Expanded(
            child: _tripsState(
              tripsAsync,
              selectedMember,
              (v) => _dayList(v, selectedMember, wide: true),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything the Reports screen derives from the loaded trips for the
/// selected month (and optional single date).
class _MonthView {
  final List<DateTime> months;
  final DateTime selected;
  final DateTime? activeDate;
  final int lastDay;
  final bool isFutureMonth;
  final List<int> days;
  final Map<int, List<Overalltripdetailsmodel>> tripsByDay;
  final List<Overalltripdetailsmodel> displayTrips;
  final double displayKm;
  final int daysWithEntry;
  final int daysWithoutEntry;

  const _MonthView({
    required this.months,
    required this.selected,
    required this.activeDate,
    required this.lastDay,
    required this.isFutureMonth,
    required this.days,
    required this.tripsByDay,
    required this.displayTrips,
    required this.displayKm,
    required this.daysWithEntry,
    required this.daysWithoutEntry,
  });
}

/// Small uppercase section label used in the iPad side panel.
class _PanelLabel extends StatelessWidget {
  final String text;

  const _PanelLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

/// Compact count tile (days with / without entry) for the iPad side panel.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary card showing the total distance travelled in the selected month,
/// or the selected day when a specific-date filter is active.
class _TotalDistanceCard extends StatelessWidget {
  final DateTime? month;
  final DateTime? date;
  final double totalKm;
  final int tripCount;

  const _TotalDistanceCard({
    required this.month,
    this.date,
    required this.totalKm,
    required this.tripCount,
  });

  @override
  Widget build(BuildContext context) {
    final label = date != null
        ? DateFormat('dd MMM yyyy').format(date!)
        : month != null
        ? DateFormat('MMMM yyyy').format(month!)
        : 'All months';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Distance • $label',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalKm.toStringAsFixed(2)} Km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$tripCount ${tripCount == 1 ? 'trip' : 'trips'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown for a day on which the member recorded no trip.
class _NoEntryTile extends StatelessWidget {
  const _NoEntryTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 18,
            color: Colors.red.shade400,
          ),
          const SizedBox(width: 10),
          Text(
            'No entry for the day',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact button beside the month dropdown that opens a date picker to filter
/// trips down to a single day. When a date is active it shows the date and a
/// clear (×) affordance instead.
class _DateFilterButton extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DateFilterButton({
    required this.selectedDate,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasDate
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_rounded,
              size: 18,
              color: hasDate ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              hasDate
                  ? DateFormat('dd MMM').format(selectedDate!)
                  : 'Date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasDate ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
            if (hasDate) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Download / export button shown beside the date filter. Generates an Excel
/// report of the trips currently listed on screen. Shows a spinner while the
/// file is being built and is disabled when [onTap] is null.
class _ExportButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;

  const _ExportButton({
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;

    return Tooltip(
      message: 'Export to Excel',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: onTap == null
                ? Colors.grey.shade300
                : AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: loading
              ? const Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(
            Icons.download_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Status Report → specific date: a pin on every lat/long of the day's
/// trips (start, visits, end) with the road path between them.
/// Tap opens the full-screen Root Tracker for the same member and day.
class _DayRouteMapCard extends StatelessWidget {
  final List<Overalltripdetailsmodel> trips;
  final DateTime date;
  final Reportingmembersmodel? member;

  const _DayRouteMapCard({
    required this.trips,
    required this.date,
    required this.member,
    this.mapHeight = 240,
  });

  final double mapHeight;

  void _openFull(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RootTrackerScreen(
          initialMember: member,
          initialDate: date,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = buildRouteStops(trips);
    final visits = stops.where((s) => s.kind == StopKind.visit).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
            child: Row(
              children: [
                Icon(Icons.route_rounded,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Route map',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${stops.length} points · $visits visits',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            height: mapHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TripRouteMap(
              trips: trips,
              compact: true,
              onTap: () => _openFull(context),
              fitPadding: const EdgeInsets.fromLTRB(36, 56, 36, 28),
            ),
          ),
        ],
      ),
    );
  }
}
