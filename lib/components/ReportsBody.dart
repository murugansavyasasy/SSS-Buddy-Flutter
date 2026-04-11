import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/components/CustomDropdown.dart';
import '../Values/Colors/app_colors.dart';
import '../provider/app_providers.dart';
import '../viewModel/overall_trip_viewmodel.dart';
import '../viewModel/reporting_members_dd_viewmodel.dart';
import 'EmptyState.dart';
import 'MemberDropdown.dart';
import 'SummaryChip.dart';
import 'TripCard.dart';

class ReportsBody extends ConsumerWidget {
  const ReportsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(reportingmembersProvider);
    final selectedMember = ref.watch(selectedMemberProvider);
    final tripsAsync = ref.watch(overallTripProvider);

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
                  print('🔽 DROPDOWN onChanged FIRED');
                  print('   Selected member: ${member?.membername ?? "null"}');
                  print('   Member ID: ${member?.idmember ?? "null"}');

                  ref.read(selectedMemberProvider.notifier).state = member;

                  if (member != null) {
                    print('🚀 CALLING loadForMember(${member.idmember})');
                    ref
                        .read(overallTripProvider.notifier)
                        .loadForMember(member.idmember);
                  } else {
                    print('⚠️  No member selected (null)');
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

         if (selectedMember != null)
            tripsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (trips) {
                final closed = trips.where((t) => t.is_closed == 1).length;
                final open = trips.where((t) => t.is_closed == 0).length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SummaryChip(
                        label: 'Total',
                        count: trips.length,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      SummaryChip(
                        label: 'Closed',
                        count: closed,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      SummaryChip(
                        label: 'Open',
                        count: open,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                );
              },
            ),

          if (selectedMember != null) const SizedBox(height: 12),

          Expanded(
            child: selectedMember == null
                ? const EmptyState()
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
                  ? const EmptyState(
                message: 'No trips found for this member.',
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: trips.length,
                itemBuilder: (_, i) => TripCard(trip: trips[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}