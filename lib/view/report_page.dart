// reports_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/ReportingMembersModel.dart';
import '../auth/model/OverallTripDetailsModel.dart';
import '../components/toolbar_layout.dart';
import '../viewmodel/reporting_members_dd_viewmodel.dart';
import '../viewmodel/overall_trip_viewmodel.dart';
import 'dashboard.dart';

final selectedMemberProvider = StateProvider<Reportingmembersmodel?>(
  (ref) => null,
);

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reportingmembersProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(title: "Trip Reports", navigateTo: const Dashboard()),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: const _ReportsBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsBody extends ConsumerWidget {
  const _ReportsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(reportingmembersProvider);
    final selectedMember = ref.watch(selectedMemberProvider);
    final tripsAsync = ref.watch(overallTripProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ── Dropdown ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: membersAsync.when(
            loading: () => _DropdownSkeleton(),
            error: (e, _) =>
                Text('Error: $e', style: const TextStyle(color: Colors.red)),
            data: (members) => _MemberDropdown(
              members: members,
              selected: selectedMember,
              onChanged: (member) {
                ref.read(selectedMemberProvider.notifier).state = member;
                if (member != null) {
                  ref
                      .read(overallTripProvider.notifier)
                      .loadForMember(member.idmember);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Summary chips ─────────────────────────────────────────
        if (selectedMember != null)
          tripsAsync.whenData((trips) {
                final closed = trips.where((t) => t.is_closed == 1).length;
                final open = trips.where((t) => t.is_closed == 0).length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _SummaryChip(
                        label: 'Total',
                        count: trips.length,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        label: 'Closed',
                        count: closed,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        label: 'Open',
                        count: open,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                );
              }).value ??
              const SizedBox.shrink(),

        if (selectedMember != null) const SizedBox(height: 12),

        // ── Trip List ─────────────────────────────────────────────
        Expanded(
          child: selectedMember == null
              ? _EmptyState()
              : tripsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load trips: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  data: (trips) => trips.isEmpty
                      ? _EmptyState(message: 'No trips found for this member.')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: trips.length,
                          itemBuilder: (_, i) => _TripCard(trip: trips[i]),
                        ),
                ),
        ),
      ],
    );
  }
}

// ── Member Dropdown ───────────────────────────────────────────────────────────

class _MemberDropdown extends StatelessWidget {
  final List<Reportingmembersmodel> members;
  final Reportingmembersmodel? selected;
  final ValueChanged<Reportingmembersmodel?> onChanged;

  const _MemberDropdown({
    required this.members,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Reportingmembersmodel>(
          isExpanded: true,
          hint: const Text(
            'Select Member',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          value: selected,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: members
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          m.membername.isNotEmpty
                              ? m.membername[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.membername,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _UserTypeBadge(usertype: m.usertype),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Overalltripdetailsmodel trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final isClosed = trip.is_closed == 1;
    final visits = trip.visit_details ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isClosed
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ── Card Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip #${trip.trip_id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(trip.start_time),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(isClosed: isClosed),
              ],
            ),
          ),

          // ── Time Row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _TimeInfo(
                  label: 'Start',
                  time: trip.start_time,
                  icon: Icons.play_circle_outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(height: 1, color: Colors.grey.shade200),
                ),
                const SizedBox(width: 8),
                _TimeInfo(
                  label: 'End',
                  time: trip.end_time,
                  icon: Icons.stop_circle_outlined,
                  alignRight: true,
                ),
              ],
            ),
          ),

          // ── Visit Details ─────────────────────────────────────
          if (visits.isNotEmpty && visits.first.school_name != null) ...[
            const Divider(height: 20, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${visits.where((v) => v.school_name != null).length} Visit(s)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ...visits
                .where((v) => v.school_name != null)
                .map((v) => _VisitTile(visit: v)),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatTime(String? raw) {
    if (raw == null) return 'N/A';
    return raw.trim();
  }
}

// ── Visit Tile ────────────────────────────────────────────────────────────────

class _VisitTile extends StatelessWidget {
  final dynamic visit; // VisitDetail model

  const _VisitTile({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visit.schoolName ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (visit.reasonOfVisit != null &&
                visit.reasonOfVisit!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      visit.reasonOfVisit!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isClosed;

  const _StatusBadge({required this.isClosed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isClosed
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isClosed ? 'Closed' : 'Open',
        style: TextStyle(
          color: isClosed ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _UserTypeBadge extends StatelessWidget {
  final int usertype;

  const _UserTypeBadge({required this.usertype});

  @override
  Widget build(BuildContext context) {
    final isManager = usertype == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isManager
            ? Colors.blue.withOpacity(0.1)
            : Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isManager ? 'Manager' : 'Field',
        style: TextStyle(
          fontSize: 10,
          color: isManager ? Colors.blue.shade700 : Colors.purple.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final String? time;
  final IconData icon;
  final bool alignRight;

  const _TimeInfo({
    required this.label,
    required this.time,
    required this.icon,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: alignRight
              ? [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 3),
                  Icon(icon, size: 12, color: Colors.grey.shade500),
                ]
              : [
                  Icon(icon, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
        ),
        Text(
          time != null ? time!.trim() : '—',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({
    this.message = 'Select a member to view their trip reports.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DropdownSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
