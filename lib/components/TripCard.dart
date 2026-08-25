import 'package:flutter/material.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/OverallTripDetailsModel.dart';
import 'StatusBadge.dart';
import 'TimeInfo.dart';
import 'VisitTile.dart';

class TripCard extends StatelessWidget {

  final Overalltripdetailsmodel trip;
  final bool isExpanded;
  final VoidCallback onExpand;

  const TripCard({
    super.key,
    required this.trip,
    required this.isExpanded,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {

    final isClosed =
        trip.is_closed == 1;

    final visits =
    trip.visit_details
        .where(
          (v) =>
      v.school_name != null &&
          v.school_name!
              .trim()
              .isNotEmpty,
    )
        .toList();

    return Container(
      margin:
      const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset:
            const Offset(0, 2),
          ),
        ],

        border: Border.all(
          color: isClosed
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),

      child: Column(
        children: [

          // ============================
          // HEADER
          // ============================

          Padding(
            padding:
            const EdgeInsets.all(14),

            child: Row(
              children: [

                Container(
                  padding:
                  const EdgeInsets.all(9),

                  decoration:
                  BoxDecoration(
                    color: AppColors.primary
                        .withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),

                  child: Icon(
                    Icons
                        .directions_car_rounded,
                    color:
                    AppColors.primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        'Trip #${trip.trip_id}',
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        trip.start_time.trim(),
                        style: TextStyle(
                          color:
                          Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                StatusBadge(
                  isClosed: isClosed,
                ),
              ],
            ),
          ),

          // ============================
          // START / END
          // ============================

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
            ),

            child: Row(
              children: [

                TimeInfo(
                  label: 'Start',
                  time: trip.start_time,
                  icon:
                  Icons.play_circle_outline,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Container(
                    height: 1,
                    color:
                    Colors.grey.shade200,
                  ),
                ),

                const SizedBox(width: 8),

                TimeInfo(
                  label: 'End',
                  time: trip.end_time,
                  icon:
                  Icons.stop_circle_outlined,
                  alignRight: true,
                ),
              ],
            ),
          ),

          // ============================
          // TOTAL DISTANCE
          // ============================

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              14,
              12,
              14,
              0,
            ),

            child: Row(
              children: [

                Icon(
                  Icons.route_rounded,
                  size: 18,
                  color:
                  Colors.grey.shade500,
                ),

                const SizedBox(width: 8),

                Text(
                  'Total Distance',
                  style: TextStyle(
                    color:
                    Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const Spacer(),

                Text(
                  '${trip.totalDistanceKm.toStringAsFixed(2)} Km',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                    fontSize: 14,
                    color:
                    Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // ============================
          // VISITED DETAILS
          // ============================

          if (visits.isNotEmpty) ...[

            const SizedBox(height: 10),

            const Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
            ),

            InkWell(
              onTap: onExpand,

              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),

                child: Row(
                  children: [

                    Container(
                      padding:
                      const EdgeInsets.all(7),

                      decoration:
                      BoxDecoration(
                        color: AppColors.primary
                            .withOpacity(0.08),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),

                      child: Icon(
                        Icons
                            .location_on_outlined,
                        size: 17,
                        color:
                        AppColors.primary,
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        '${visits.length} Visited Details',
                        style:
                        const TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),

                    Icon(
                      isExpanded
                          ? Icons
                          .keyboard_arrow_up_rounded
                          : Icons
                          .keyboard_arrow_down_rounded,
                      color:
                      Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),

            // ============================
            // EXPANDED VISITS
            // ============================

            AnimatedCrossFade(
              duration:
              const Duration(
                milliseconds: 250,
              ),

              crossFadeState:
              isExpanded
                  ? CrossFadeState
                  .showSecond
                  : CrossFadeState
                  .showFirst,

              firstChild:
              const SizedBox.shrink(),

              secondChild:
              Padding(
                padding:
                const EdgeInsets.only(
                  left: 14,
                  right: 14,
                  bottom: 8,
                ),

                child: Column(
                  children:
                  visits.map((visit) {
                    return VisitTile(
                      visit: visit,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}