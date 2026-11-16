import 'package:flutter/material.dart';

import 'PillStat.dart';
import 'StatCell.dart';
import 'glass_card.dart';

class DashboardCard extends StatefulWidget {
  final String title;
  final String activeLabel;
  final String inactiveLabel;
  final String? activeCount;
  final String? inactiveCount;
  final String? totalStudent;
  final String? totalStaff;
  final Color color;
  final bool isLoading;
  final IconData? icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.color,
    this.activeCount,
    this.inactiveCount,
    this.totalStudent,
    this.totalStaff,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (!widget.isLoading) _controller.forward();
  }

  @override
  void didUpdateWidget(DashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fixed width so the card doesn't shrink while loading or with short values.
    final cardWidth =
        (MediaQuery.of(context).size.width * 0.78).clamp(260.0, 320.0);
    final hasCounts =
        widget.activeLabel.isNotEmpty || widget.inactiveLabel.isNotEmpty;
    return SizedBox(
      width: cardWidth,
      child: SoftCard(
        gradient: homePastelGradient(widget.color),
        borderColor: widget.color.withValues(alpha: 0.18),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeGlass.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: homeDeep(widget.color),
                  ),
                  child: Icon(
                    widget.icon ?? Icons.school_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasCounts)
              Row(
                children: [
                  if (widget.activeLabel.isNotEmpty)
                    Expanded(
                      child: StatCell(
                        label: widget.activeLabel,
                        value: widget.activeCount ?? "—",
                        isLoading: widget.isLoading,
                        fadeAnim: _fadeAnim,
                        slideAnim: _slideAnim,
                        valueColor: homeDeep(widget.color),
                      ),
                    ),
                  if (widget.activeLabel.isNotEmpty &&
                      widget.inactiveLabel.isNotEmpty)
                    Container(
                      width: 1,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: widget.color.withValues(alpha: 0.2),
                    ),
                  if (widget.inactiveLabel.isNotEmpty)
                    Expanded(
                      child: StatCell(
                        label: widget.inactiveLabel,
                        value: widget.inactiveCount ?? "—",
                        isLoading: widget.isLoading,
                        fadeAnim: _fadeAnim,
                        slideAnim: _slideAnim,
                        valueColor: homeDeep(widget.color),
                      ),
                    ),
                ],
              ),
            const Spacer(),
            Row(
              children: [
                PillStat(
                  icon: Icons.people_alt_rounded,
                  label: widget.title == "Live Schools"
                      ? "Active Students"
                      : "Students",
                  value: widget.totalStudent ?? "—",
                  isLoading: widget.isLoading,
                  fadeAnim: _fadeAnim,
                  accent: homeDeep(widget.color),
                ),
                const SizedBox(width: 8),
                PillStat(
                  icon: Icons.badge_rounded,
                  label: widget.title == "Live Schools"
                      ? "Active Staff"
                      : "Staff",
                  value: widget.totalStaff ?? "—",
                  isLoading: widget.isLoading,
                  fadeAnim: _fadeAnim,
                  accent: homeDeep(widget.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
