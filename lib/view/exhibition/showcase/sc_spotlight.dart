import 'dart:async';

import 'package:flutter/material.dart';

import '../widget/exhibition_common.dart';
import 'showcase_content.dart';

/// A School Chimes solution card shown beside / below a Give Demo or
/// Capture Lead step, so visitors learn about the product while their
/// details are entered. Changes (with a fade) when the step changes.
class ScSpotlightCard extends StatelessWidget {
  final ScSpotlight spot;

  /// Tighter layout for phones (below the form).
  final bool compact;

  const ScSpotlightCard({super.key, required this.spot, this.compact = false});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
            child: child,
          ),
        ),
        child: _Card(key: ValueKey(spot.kicker), spot: spot, compact: compact),
      );
}

class _Card extends StatelessWidget {
  final ScSpotlight spot;
  final bool compact;
  const _Card({super.key, required this.spot, required this.compact});

  @override
  Widget build(BuildContext context) {
    final c = spot.color;
    final pad = compact ? 16.0 : 22.0;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(Colors.white, c, 0.10)!, Colors.white],
        ),
        border: Border.all(color: c.withValues(alpha: 0.18)),
        boxShadow: const [BoxShadow(color: Color(0x10231A5E), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Stack(
        children: [
          // Soft decorative circles in the brand colour.
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.07)),
            ),
          ),
          Positioned(
            right: 40,
            top: 50,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.05)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(scLogoAsset, height: compact ? 18 : 22, width: (compact ? 18 : 22) * 600 / 214),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(spot.icon, size: 13, color: c),
                          const SizedBox(width: 5),
                          Text(spot.kicker.toUpperCase(),
                              style: TextStyle(fontSize: 10.5, letterSpacing: 0.9, fontWeight: FontWeight.w800, color: c)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 46 : 56,
                      height: compact ? 46 : 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [c, Color.lerp(c, Colors.white, 0.3)!]),
                        borderRadius: BorderRadius.circular(compact ? 14 : 18),
                        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: Icon(spot.icon, color: Colors.white, size: compact ? 24 : 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(spot.headline,
                              style: TextStyle(
                                  fontFamily: exFont,
                                  fontSize: compact ? 18 : 21,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: scInk)),
                          const SizedBox(height: 5),
                          Text(spot.line,
                              style: TextStyle(fontSize: compact ? 13 : 14, height: 1.4, color: scMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 18),
                for (final (icon, text) in spot.points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.withValues(alpha: 0.10)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(icon, size: 16, color: c),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(text,
                                style: TextStyle(
                                    fontSize: compact ? 13.5 : 14, height: 1.3, fontWeight: FontWeight.w600, color: scInk)),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 15, color: scIndigo),
                    const SizedBox(width: 6),
                    Text('Trusted by 3,500+ schools in India',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scIndigo.withValues(alpha: 0.85))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim version for the top of a form: icon, label and headline, with the
/// points rotating one at a time so it stays short. Tap for the full card.
class ScSpotlightBanner extends StatefulWidget {
  final ScSpotlight spot;
  const ScSpotlightBanner({super.key, required this.spot});

  @override
  State<ScSpotlightBanner> createState() => _ScSpotlightBannerState();
}

class _ScSpotlightBannerState extends State<ScSpotlightBanner> {
  int _point = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _point = (_point + 1) % widget.spot.points.length);
    });
  }

  @override
  void didUpdateWidget(ScSpotlightBanner old) {
    super.didUpdateWidget(old);
    if (old.spot.kicker != widget.spot.kicker) _point = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openFull() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScSpotlightCard(spot: widget.spot),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: scIndigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Got it', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spot;
    final c = s.color;
    final (icon, text) = s.points[_point % s.points.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Material(
        key: ValueKey(s.kicker),
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color.lerp(Colors.white, c, 0.14)!, Color.lerp(Colors.white, c, 0.04)!],
            ),
            border: Border.all(color: c.withValues(alpha: 0.22)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _openFull,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [c, Color.lerp(c, Colors.white, 0.3)!]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: c.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(s.icon, color: Colors.white, size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SCHOOL CHIMES · ${s.kicker.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w800, color: c)),
                        const SizedBox(height: 2),
                        Text(s.headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: exFont, fontSize: 15.5, fontWeight: FontWeight.w800, color: scInk)),
                        const SizedBox(height: 3),
                        // Description: two lines on phones, three where
                        // there is more room (iPad).
                        LayoutBuilder(
                          builder: (_, box) => Text(s.line,
                              maxLines: box.maxWidth >= 420 ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, height: 1.35, color: scMuted)),
                        ),
                        const SizedBox(height: 6),
                        // One point at a time, sliding up; room for two lines
                        // so narrow phones don't cut it.
                        SizedBox(
                          height: 34,
                          child: AnimatedSwitcher(
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.topLeft,
                              children: [...previous, if (current != null) current],
                            ),
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, a) => FadeTransition(
                              opacity: a,
                              child: SlideTransition(
                                position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(a),
                                child: child,
                              ),
                            ),
                            child: Row(
                              key: ValueKey('${s.kicker}-$_point'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(icon, size: 14, color: c),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scMuted)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
