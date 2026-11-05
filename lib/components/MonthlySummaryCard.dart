import 'package:flutter/material.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/OverallTripDetailsModel.dart';
import '../utils/trip_date_utils.dart';

class MonthlySummaryCard extends StatefulWidget {
  /// Already selected month ku filter aana trips (viewmodel tharum)
  final List<Overalltripdetailsmodel> monthTrips;
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthlySummaryCard({
    super.key,
    required this.monthTrips,
    required this.month,
    required this.onMonthChanged,
  });

  @override
  State<MonthlySummaryCard> createState() => _MonthlySummaryCardState();
}

class _MonthlySummaryCardState extends State<MonthlySummaryCard> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // Default collapse
  bool _datesExpanded = false;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return widget.month.year == now.year && widget.month.month == now.month;
  }

  void _changeMonth(int delta) {
    widget.onMonthChanged(
      DateTime(widget.month.year, widget.month.month + delta),
    );
  }

  @override
  Widget build(BuildContext context) {
    final month = widget.month;
    final monthTrips = widget.monthTrips;

    final totalKm =
    monthTrips.fold<double>(0, (sum, t) => sum + t.totalDistanceKm);

    final entryDays = monthTrips
        .map((t) => parseTripDate(t.start_time)?.day)
        .whereType<int>()
        .toSet();

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final missingCount = daysInMonth - entryDays.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _changeMonth(-1),
              ),
              Expanded(
                child: Text(
                  '${_months[month.month - 1]} ${month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Total km
          Row(
            children: [
              Icon(Icons.route_rounded,
                  size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                'Total Distance (${monthTrips.length} trips)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${totalKm.toStringAsFixed(2)} Km',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Dates header (tap = expand / collapse)
          InkWell(
            onTap: () => setState(() => _datesExpanded = !_datesExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Entry ${entryDays.length}  •  Non Entry $missingCount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _datesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // Expanded: full month dates (green = entry, red = non entry)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _datesExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(daysInMonth, (i) {
                  final d = i + 1;
                  final hasEntry = entryDays.contains(d);
                  final color =
                  hasEntry ? Colors.green.shade700 : Colors.red.shade700;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                      '$d ${_shortMonths[month.month - 1]}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}