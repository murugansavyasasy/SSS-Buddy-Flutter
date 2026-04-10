import 'package:flutter/material.dart';
import 'dart:ui';

import 'GlowCircle.dart';
import 'PillStat.dart';
import 'ShimmerBox.dart';
import 'StatCell.dart';

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

  Color get _lightColor => Color.lerp(widget.color, Colors.white, 0.25)!;
  Color get _darkColor => Color.lerp(widget.color, Colors.black, 0.2)!;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
      constraints:const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [_lightColor, _darkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.45),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: GlowCircle(color: Colors.white.withOpacity(0.15), size: 110),
            ),
            Positioned(
              bottom: -25,
              left: -15,
              child: GlowCircle(color: Colors.white.withOpacity(0.10), size: 90),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.icon ?? Icons.school_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (widget.activeLabel.isNotEmpty || widget.inactiveLabel.isNotEmpty)
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
                            ),
                          ),

                        if (widget.activeLabel.isNotEmpty && widget.inactiveLabel.isNotEmpty) ...[
                          Container(
                            width: 1,
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ],

                        if (widget.inactiveLabel.isNotEmpty)
                          Expanded(
                            child: StatCell(
                              label: widget.inactiveLabel,
                              value: widget.inactiveCount ?? "—",
                              isLoading: widget.isLoading,
                              fadeAnim: _fadeAnim,
                              slideAnim: _slideAnim,
                            ),
                          ),
                      ],
                    ),

                  if (widget.activeLabel.isNotEmpty || widget.inactiveLabel.isNotEmpty)
                    const SizedBox(height: 12),

                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    );
  }
}







