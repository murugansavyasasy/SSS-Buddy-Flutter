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

class _DashboardCardState extends State<DashboardCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
    final cardWidth = (MediaQuery.of(context).size.width * 0.72).clamp(240.0, 290.0);
    final hasCounts = widget.activeLabel.isNotEmpty || widget.inactiveLabel.isNotEmpty;
    return SizedBox(
      width: cardWidth,
      child: SoftCard(
        gradient: homePastelGradient(widget.color),
        borderColor: widget.color.withValues(alpha: 0.18),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative bubbles (clipped by the card's rounded edge).
            ..._bubbles(widget.color),
            Column(
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: homeDeep(widget.color),
                      ),
                      child: Icon(
                        widget.icon ?? Icons.school_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                      if (widget.activeLabel.isNotEmpty && widget.inactiveLabel.isNotEmpty)
                        Container(
                          width: 1,
                          height: 34,
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
                      label: widget.title == "Live Schools" ? "Active Students" : "Students",
                      value: widget.totalStudent ?? "—",
                      isLoading: widget.isLoading,
                      fadeAnim: _fadeAnim,
                      accent: homeDeep(widget.color),
                    ),
                    const SizedBox(width: 8),
                    PillStat(
                      icon: Icons.badge_rounded,
                      label: widget.title == "Live Schools" ? "Active Staff" : "Staff",
                      value: widget.totalStaff ?? "—",
                      isLoading: widget.isLoading,
                      fadeAnim: _fadeAnim,
                      accent: homeDeep(widget.color),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Soft translucent circles in the card colour, mostly off the top-right
  /// and bottom-right edges.
  List<Widget> _bubbles(Color c) {
    Widget bubble(double size, double alpha, {double? top, double? right, double? bottom}) =>
        Positioned(
          top: top,
          right: right,
          bottom: bottom,
          child: IgnorePointer(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.withValues(alpha: alpha),
                    c.withValues(alpha: alpha * 0.35),
                  ],
                ),
              ),
            ),
          ),
        );
    return [
      bubble(110, 0.18, top: -52, right: -40),
      bubble(46, 0.15, top: 40, right: 54),
      bubble(80, 0.15, bottom: -44, right: 30),
      bubble(18, 0.2, bottom: 44, right: 12),
    ];
  }
}
