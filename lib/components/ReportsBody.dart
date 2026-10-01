import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/components/CustomDropdown.dart';

import '../Values/Colors/app_colors.dart';
import '../provider/app_providers.dart';
import '../viewModel/overall_trip_viewmodel.dart';
import '../viewModel/reporting_members_dd_viewmodel.dart';
import 'EmptyState.dart';
import 'MemberDropdown.dart';
import 'MonthlySummaryCard.dart';
import 'TripCard.dart';

class ReportsBody extends ConsumerStatefulWidget {
  const ReportsBody({super.key});

  @override
  ConsumerState<ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends ConsumerState<ReportsBody> {
  int? expandedTripId;
  bool _autoSelected = false;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(reportingmembersProvider);
    final selectedMember = ref.watch(selectedMemberProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    // state = selected month trips (viewmodel filter panni tharum)
    final tripsAsync = ref.watch(overallTripProvider);

    // Auto-select 0th member on first load
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: membersAsync.when(
              loading: () => const CustomDropdown(),
              error: (e, _) => Text(
                'Error loading members: $e',
                style: const TextStyle(color: Colors.red),
              ),
              data: (members) => MemberDropdown(
                members: members,
                selected: selectedMember,
                onChanged: (member) {
                  setState(() => expandedTripId = null);

                  ref.read(selectedMemberProvider.notifier).state = member;

                  if (member != null) {
                    ref
                        .read(overallTripProvider.notifier)
                        .loadForMember(member.idmember);
                  } else {
                    print('⚠️ No member selected (null)');
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

              // monthTrips = already filtered array
              data: (monthTrips) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount:
                  1 + (monthTrips.isEmpty ? 1 : monthTrips.length),
                  itemBuilder: (_, index) {
                    // First item = monthly summary
                    if (index == 0) {
                      return MonthlySummaryCard(
                        monthTrips: monthTrips,
                        month: selectedMonth,
                        onMonthChanged: (m) {
                          setState(() => expandedTripId = null);
                          ref
                              .read(overallTripProvider.notifier)
                              .setMonth(m);
                        },
                      );
                    }

                    if (monthTrips.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: EmptyState(
                          message: 'No trips found for this month.',
                        ),
                      );
                    }

                    final trip = monthTrips[index - 1];

                    return TripCard(
                      trip: trip,
                      isExpanded: expandedTripId == trip.trip_id,
                      onExpand: () {
                        setState(() {
                          expandedTripId = expandedTripId == trip.trip_id
                              ? null
                              : trip.trip_id;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}