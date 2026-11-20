import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'glass_card.dart';

class DashboardTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  /// When the opening light sweep crosses this tile.
  final Duration shineDelay;

  const DashboardTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
    this.shineDelay = const Duration(milliseconds: 900),
  });

  @override
  State<DashboardTile> createState() => _DashboardTileState();
}

class _DashboardTileState extends State<DashboardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Gradient squircle: lighter top-left → deeper bottom-right, a soft
  /// highlight on the upper half and a coloured glow underneath.
  Widget _iconBadge() {
    final c = widget.color;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(c, Colors.white, 0.18)!, c, Color.lerp(c, Colors.black, 0.14)!],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.32), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          // Glassy top highlight.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.26), Colors.white.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Center(child: Icon(widget.icon, color: Colors.white, size: 20)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        // Spotlight under the finger (tile colour) + one light sweep when
        // the dashboard opens.
        child: TouchGlow(
        color: widget.color,
        radius: 110,
        borderRadius: BorderRadius.circular(20),
        child: AppShine(
        delay: widget.shineDelay,
        color: widget.color,
        opacity: 0.16,
        borderRadius: BorderRadius.circular(20),
        child: SoftCard(
          radius: 20,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon + optional unread badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBadge(),
                  const Spacer(),
                  if (widget.badgeCount > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              // Title + arrow row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: HomeGlass.ink,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Arrow badge
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: HomeGlass.bg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      color: HomeGlass.muted,
                      size: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
        ),
      ),
    );
  }
}
