import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/ZeroActivityModel.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/zeroactivity_viewmodal.dart';

class ZeroActivityScreen extends ConsumerStatefulWidget {
  const ZeroActivityScreen({
    super.key,
  });

  @override
  ConsumerState<ZeroActivityScreen> createState() =>
      _ZeroActivityScreenState();
}

class _ZeroActivityScreenState
    extends ConsumerState<ZeroActivityScreen> {
  String selectedValue = "All";

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(zeroActivityProvider);
    final statusList =
        ref.read(zeroActivityProvider.notifier).statusList;

    return Scaffold(
      backgroundColor: const Color(0xFF5B6F95),
      body: Column(
        children: [
          ToolbarLayout(
            title: "Zero Activity",
            searchHint: "Search....",
            dropdownLists: statusList,
            selectedMonth: selectedValue,

            onMonthChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                selectedValue = value;
              });

              ref
                  .read(zeroActivityProvider.notifier)
                  .filterByStatus(value);
            },
            onSearch: (query) {
              ref
                  .read(zeroActivityProvider.notifier)
                  .filter(query);
            },
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6FA),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: dataAsync.when(
                loading: () {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                error: (error, stackTrace) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Error: $error",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },

                // ======================================
                // DATA
                // ======================================

                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Data Found",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF777777),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      20,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];

                      return _zeroActivityCard(item);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zeroActivityCard(
      ZeroActivityModel item,
      ) {
    final bool isLive =
        item.instituteStatus.toUpperCase() == "LIVE";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================
            // TOP SECTION
            // ========================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ====================================
                // SCHOOL ICON
                // ====================================

                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: Color(0xFF4267B2),
                    size: 25,
                  ),
                ),

                const SizedBox(width: 12),

                // ====================================
                // INSTITUTE NAME
                // ====================================

                Expanded(
                  child: _ExpandableInstituteName(
                    name: item.instituteName,
                    instituteId: item.instituteId,
                  ),
                ),

                const SizedBox(width: 8),

                // ====================================
                // STATUS
                // ====================================

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLive
                        ? const Color(0xFFE8F7EE)
                        : const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isLive
                              ? Colors.green
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Text(
                        item.displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ========================================
            // DIVIDER
            // ========================================

            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 14),

            // ========================================
            // SALES PERSON
            // ========================================

            _infoRow(
              icon: Icons.person_outline,
              label: "Sales Person",
              value: item.salesPerson.isEmpty
                  ? "No Data"
                  : item.salesPerson,
            ),

            const SizedBox(height: 12),

            // ========================================
            // WEB LOGIN
            // ========================================

            _infoRow(
              icon: Icons.language_outlined,
              label: "Web Login",
              value: _formatDateTime(
                item.lastWebLogin,
              ),
            ),

            const SizedBox(height: 12),

            // ========================================
            // APP LOGIN
            // ========================================

            _infoRow(
              icon: Icons.phone_android_outlined,
              label: "App Login",
              value: _formatDateTime(
                item.lastAppLogin,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // INFO ROW
  // ==================================================

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),

        const SizedBox(width: 10),

        Text(
          "$label:",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ==================================================
  // DATE FORMAT
  // ==================================================

  String _formatDateTime(String value) {
    if (value.trim().isEmpty) {
      return "No Data";
    }

    try {
      final date = DateTime.tryParse(
        value.trim().replaceFirst(' ', 'T'),
      );

      if (date == null) {
        return value;
      }

      final day = date.day
          .toString()
          .padLeft(2, '0');

      final month = _monthName(
        date.month,
      );

      final year = date.year.toString();
      int hour = date.hour;

      final minute = date.minute
          .toString()
          .padLeft(2, '0');

      final period = hour >= 12
          ? "PM"
          : "AM";

      hour = hour % 12;

      if (hour == 0) {
        hour = 12;
      }

      final formattedHour = hour
          .toString()
          .padLeft(2, '0');

      return "$day $month $year, "
          "$formattedHour:$minute $period";
    } catch (_) {
      return value;
    }
  }

  // ==================================================
  // MONTH NAME
  // ==================================================

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return months[month - 1];
  }
}

// ======================================================
// EXPANDABLE INSTITUTE NAME
// ======================================================

class _ExpandableInstituteName extends StatefulWidget {
  final String name;
  final int instituteId;

  const _ExpandableInstituteName({
    required this.name,
    required this.instituteId,
  });

  @override
  State<_ExpandableInstituteName> createState() =>
      _ExpandableInstituteNameState();
}

class _ExpandableInstituteNameState
    extends State<_ExpandableInstituteName> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ============================================
        // INSTITUTE NAME
        // ============================================

        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.name,

                  // Initially 2 lines only
                  // After tap full text
                  maxLines: isExpanded ? null : 2,

                  overflow: isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202938),
                  ),
                ),
              ),

              // ======================================
              // ARROW
              // ======================================

              if (isExpanded) ...[
                const SizedBox(width: 4),

                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 4),

        // ============================================
        // INSTITUTE ID
        // ============================================

        Text(
          "Institute ID: ${widget.instituteId}",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}