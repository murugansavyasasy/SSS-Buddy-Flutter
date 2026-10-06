import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sssbuddy/components/CustomDropdown.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/OverallTripDetailsModel.dart';
import '../provider/app_providers.dart';
import '../viewModel/overall_trip_viewmodel.dart';
import '../viewModel/reporting_members_dd_viewmodel.dart';
import 'EmptyState.dart';
import 'MemberDropdown.dart';
import 'MonthDropdown.dart';
import 'TodayEntryBar.dart';
import 'TripCard.dart';

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

  /// The 12 months of the current calendar year (Jan → Dec), most recent
  /// first. e.g. for 2026 → Dec 2026 … Jan 2026.
  List<DateTime> _currentYearMonths(DateTime now) {
    final months = <DateTime>[
      for (var month = 1; month <= 12; month++) DateTime(now.year, month),
    ];
    months.sort((a, b) => b.compareTo(a)); // most recent first
    return months;
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

          ref
              .read(selectedMemberProvider.notifier)
              .state = members[0];
          ref
              .read(overallTripProvider.notifier)
              .loadForMember(members[0].idmember);
        });
      }
    }

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ─────────────────────────────────
          // TODAY'S ENTRY STATUS (entered / no entry)
          // ─────────────────────────────────
          const TodayEntryBar(),

          // ─────────────────────────────────
          // MEMBER DROPDOWN
          // ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: membersAsync.when(

              loading: () => const CustomDropdown(),

              error: (e, _) => Text(
                'Error loading members: $e',
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),

              data: (members) => MemberDropdown(
                members: members,
                selected: selectedMember,

                onChanged: (member) {
                  setState(() {
                    expandedTripId = null;
                    // Reset the month/date filters so the new member defaults
                    // back to the current month.
                    _selectedMonth = null;
                    _selectedDate = null;
                  });

                  ref
                      .read(selectedMemberProvider.notifier)
                      .state = member;

                  if (member != null) {
                    ref
                        .read(overallTripProvider.notifier)
                        .loadForMember(member.idmember);

                  } else {

                    print(
                      '⚠️ No member selected (null)',
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─────────────────────────────────
          // TRIP LIST
          // ─────────────────────────────────
          Expanded(
            child: selectedMember == null
                ? const EmptyState()

                : tripsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Failed to load trips: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),

              // Data
              data: (allTrips) {

                if (allTrips.isEmpty) {
                  return const EmptyState(
                    message:
                    'No trips found for this member.',
                  );
                }

                // ─────────────────────────────────
                // MONTH-WISE FILTER (current calendar year only)
                // ─────────────────────────────────
                final now = DateTime.now();
                final months = _currentYearMonths(now);

                // Default to the current month (always within the FY).
                DateTime selected =
                    _selectedMonth ?? DateTime(now.year, now.month);

                // Snap to the exact list instance so DropdownButton matches.
                selected = months.firstWhere(
                  (m) =>
                      m.year == selected.year &&
                      m.month == selected.month,
                  orElse: () => months.first,
                );

                final filtered = allTrips.where((t) {
                  final d = t.startDateTime;
                  return d != null &&
                      d.year == selected.year &&
                      d.month == selected.month;
                }).toList();

                // ─────────────────────────────────
                // DAY-WISE GROUPING
                // ─────────────────────────────────
                // Group the month's trips by day-of-month.
                final Map<int, List<Overalltripdetailsmodel>> tripsByDay = {};
                for (final t in filtered) {
                  final d = t.startDateTime;
                  if (d == null) continue;
                  tripsByDay.putIfAbsent(d.day, () => []).add(t);
                }

                final isCurrentMonth = selected.year == now.year &&
                    selected.month == now.month;
                final isFutureMonth = selected.isAfter(
                  DateTime(now.year, now.month),
                );

                // Last day to list: today for the current month, otherwise
                // the full month. (day 0 of next month = last day of this one)
                final daysInMonth =
                    DateTime(selected.year, selected.month + 1, 0).day;
                final lastDay = isCurrentMonth ? now.day : daysInMonth;

                // ─────────────────────────────────
                // SPECIFIC-DATE FILTER (within the selected month)
                // ─────────────────────────────────
                // Only honour the date filter when it falls inside the
                // selected month and is not in the future.
                final DateTime? activeDate = (_selectedDate != null &&
                        _selectedDate!.year == selected.year &&
                        _selectedDate!.month == selected.month &&
                        _selectedDate!.day <= lastDay)
                    ? _selectedDate
                    : null;

                // Days to render, most recent first. When a specific date is
                // active, collapse to just that single day.
                final days = <int>[
                  if (activeDate != null)
                    activeDate.day
                  else
                    for (var d = lastDay; d >= 1; d--) d,
                ];

                // Summary reflects exactly what's listed: the single day when
                // a date filter is active, otherwise the whole month.
                final displayTrips = activeDate != null
                    ? (tripsByDay[activeDate.day] ??
                        const <Overalltripdetailsmodel>[])
                    : filtered;
                final displayKm = displayTrips.fold<double>(
                  0,
                  (sum, t) => sum + t.totalDistanceKm,
                );

                return Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    // Month dropdown + specific-date filter
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: MonthDropdown(
                              months: months,
                              selected: selected,
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
                            selectedDate: activeDate,
                            onPick: () async {
                              final firstDate = DateTime(
                                selected.year,
                                selected.month,
                                1,
                              );
                              final lastDate = DateTime(
                                selected.year,
                                selected.month,
                                lastDay,
                              );
                              final initial = activeDate ?? lastDate;
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initial,
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
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Total distance summary
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 12,
                      ),
                      child: _TotalDistanceCard(
                        month: selected,
                        date: activeDate,
                        totalKm: displayKm,
                        tripCount: displayTrips.length,
                      ),
                    ),

                    // Day-wise list: every day of the month, with its trips
                    // or a "No entry for the day" note.
                    Expanded(
                      child: isFutureMonth
                          ? const EmptyState(
                              message:
                              'No entry found for the selected month.',
                            )
                          : ListView.builder(
                              padding:
                              const EdgeInsets.fromLTRB(
                                16, 0, 16, 24,
                              ),
                              itemCount: days.length,
                              itemBuilder: (_, index) {
                                final day = days[index];
                                final date = DateTime(
                                  selected.year,
                                  selected.month,
                                  day,
                                );
                                final dayTrips =
                                    tripsByDay[day] ??
                                        const [];

                                return Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [

                                    // Day header
                                    Padding(
                                      padding:
                                      const EdgeInsets.fromLTRB(
                                        2, 6, 2, 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .calendar_today_rounded,
                                            size: 13,
                                            color: Colors
                                                .grey.shade500,
                                          ),
                                          const SizedBox(
                                            width: 6,
                                          ),
                                          Text(
                                            DateFormat(
                                              'EEE, dd MMM yyyy',
                                            ).format(date),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.w600,
                                              color: Colors
                                                  .grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Trips for the day OR no-entry note
                                    if (dayTrips.isEmpty)
                                      const _NoEntryTile()
                                    else
                                      ...dayTrips.map(
                                        (trip) => TripCard(
                                          trip: trip,
                                          isExpanded:
                                          expandedTripId ==
                                              trip.trip_id,
                                          onExpand: () {
                                            setState(() {
                                              if (expandedTripId ==
                                                  trip.trip_id) {
                                                expandedTripId =
                                                    null;
                                              } else {
                                                expandedTripId =
                                                    trip.trip_id;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
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