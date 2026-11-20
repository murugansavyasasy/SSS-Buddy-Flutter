import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-wide motion: page transitions, scroll feel, list entrance and press
/// feedback. Wired in once (AppTheme, MaterialApp, ResponsiveCardList and
/// the shared buttons / cards) so every screen picks it up.
///
/// Everything is skipped when the user turned animations off in the
/// phone's accessibility settings.

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

// ─────────────────────────────────────────────────────────────────────────
// Page transitions
// ─────────────────────────────────────────────────────────────────────────

/// Android: the new page fades in while sliding a little from the right;
/// the page underneath shifts slightly left. iOS keeps the native Cupertino
/// slide so swipe-back still works.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_reduceMotion(context)) return child;
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final under = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
    );
    return SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(-0.06, 0),
      ).animate(under),
      child: FadeTransition(
        opacity: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.7, curve: Curves.easeOut),
          ),
        ),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(enter),
          child: child,
        ),
      ),
    );
  }
}

const appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: AppPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
);

// ─────────────────────────────────────────────────────────────────────────
// Scrolling
// ─────────────────────────────────────────────────────────────────────────

/// Smooth bouncing scroll on every list (Android included). Lists that set
/// their own `physics` keep it.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(
        decelerationRate: ScrollDecelerationRate.normal,
      );

  /// Bouncing replaces the Android glow / stretch.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

// ─────────────────────────────────────────────────────────────────────────
// List entrance
// ─────────────────────────────────────────────────────────────────────────

/// Fades and slides [child] up into place when it is first built. Items in
/// a list get a short stagger by [index] (only the first few, so cards that
/// appear while scrolling come in right away).
class AppEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final double offsetY;

  /// Horizontal start offset (e.g. 40 = slides in from the right).
  final double offsetX;

  /// Start scale (e.g. 0.88 = pops in); 1 = no scaling.
  final double fromScale;

  /// Extra wait before this item starts (on top of the [index] stagger).
  final Duration delay;

  /// Stagger step per [index].
  final Duration step;

  const AppEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offsetY = 18,
    this.offsetX = 0,
    this.fromScale = 1,
    this.delay = Duration.zero,
    this.step = _step,
  });

  static const _step = Duration(milliseconds: 45);
  static const _maxStaggered = 8;
  static const _duration = Duration(milliseconds: 360);

  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  Animation<double>? _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    if (_reduceMotion(context)) return;
    final i = widget.index.clamp(0, AppEntrance._maxStaggered);
    final delay = widget.delay + widget.step * i;
    final total = delay + AppEntrance._duration;
    // The delay lives inside the animation (an Interval), not a Timer, so
    // nothing is left pending when the widget goes away.
    _c = AnimationController(vsync: this, duration: total)..forward();
    _t = CurvedAnimation(
      parent: _c!,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (t == null) return widget.child;
    return AnimatedBuilder(
      animation: t,
      child: widget.child,
      builder: (_, child) {
        final v = t.value;
        Widget w = Transform.translate(
          offset: Offset((1 - v) * widget.offsetX, (1 - v) * widget.offsetY),
          child: child,
        );
        if (widget.fromScale != 1) {
          w = Transform.scale(scale: widget.fromScale + (1 - widget.fromScale) * v, child: w);
        }
        // easeOutBack-style curves can overshoot 1; opacity must not.
        return Opacity(opacity: v.clamp(0.0, 1.0), child: w);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Touch
// ─────────────────────────────────────────────────────────────────────────

/// Shrinks [child] slightly while a finger is on it and springs back on
/// release. Uses a raw pointer [Listener], so taps, scrolling and the
/// child's own buttons keep working exactly as before.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;
  Offset? _start;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _reduceMotion(context)) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _start = e.position;
        _set(true);
      },
      // Release the press once the finger starts scrolling the list.
      onPointerMove: (e) {
        final s = _start;
        if (s != null && (e.position - s).distance > 8) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _down ? 90 : 220),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Numbers
// ─────────────────────────────────────────────────────────────────────────

/// Counts a whole number up from 0 (first show) or from the previous value
/// (on change). Text that is not a plain integer ("—", "12.5k") is shown
/// as it is.
class AppCountUp extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;

  const AppCountUp({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    final n = int.tryParse(value.trim());
    if (n == null || _reduceMotion(context)) return Text(value, style: style);
    return TweenAnimationBuilder<double>(
      // begin is only used on the first build (0 → value); later changes
      // animate from the number currently shown.
      tween: Tween(begin: 0, end: n.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}', style: style),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Light effects
// ─────────────────────────────────────────────────────────────────────────

/// A soft light that follows the finger while it is on [child] (like a
/// cursor spotlight) and fades out on release. Taps go through unchanged.
class TouchGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double radius;
  final BorderRadius borderRadius;

  const TouchGlow({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.radius = 90,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<TouchGlow> createState() => _TouchGlowState();
}

class _TouchGlowState extends State<TouchGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 420),
  );
  Offset _at = Offset.zero;

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _move(Offset p) => setState(() => _at = p);

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _move(e.localPosition);
        _fade.forward();
      },
      onPointerMove: (e) => _move(e.localPosition),
      onPointerUp: (_) => _fade.reverse(),
      onPointerCancel: (_) => _fade.reverse(),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: AnimatedBuilder(
                  animation: _fade,
                  builder: (_, __) => _fade.value == 0
                      ? const SizedBox.shrink()
                      : CustomPaint(
                          painter: _GlowPainter(
                            at: _at,
                            radius: widget.radius * (0.7 + 0.3 * _fade.value),
                            color: widget.color,
                            strength: _fade.value,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Offset at;
  final double radius;
  final Color color;
  final double strength;

  _GlowPainter({required this.at, required this.radius, required this.color, required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.38 * strength),
          color.withValues(alpha: 0.12 * strength),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromCircle(center: at, radius: radius));
    canvas.drawCircle(at, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.at != at || old.radius != radius || old.strength != strength || old.color != color;
}

/// A diagonal band of light that sweeps once across [child] after [delay]
/// (e.g. when a screen opens). Set [repeatEvery] to sweep again later.
class AppShine extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration? repeatEvery;
  final BorderRadius borderRadius;
  final double opacity;

  /// Light colour; tint it on white cards (white shine would not show).
  final Color color;

  const AppShine({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.repeatEvery,
    this.borderRadius = BorderRadius.zero,
    this.opacity = 0.55,
    this.color = Colors.white,
  });

  @override
  State<AppShine> createState() => _AppShineState();
}

class _AppShineState extends State<AppShine> with SingleTickerProviderStateMixin {
  static const _sweep = Duration(milliseconds: 900);
  AnimationController? _c;
  late Animation<double> _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null || _reduceMotion(context)) return;
    final gap = widget.repeatEvery ?? Duration.zero;
    // Delay and repeat gap live inside one controller (no Timers).
    final total = widget.delay + _sweep + gap;
    _c = AnimationController(vsync: this, duration: total);
    final start = widget.delay.inMicroseconds / total.inMicroseconds;
    final end = (widget.delay + _sweep).inMicroseconds / total.inMicroseconds;
    _t = CurvedAnimation(parent: _c!, curve: Interval(start, end, curve: Curves.easeInOutCubic));
    if (widget.repeatEvery == null) {
      _c!.forward();
    } else {
      _c!.repeat();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c == null) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: AnimatedBuilder(
                animation: _t,
                builder: (_, __) {
                  final v = _t.value;
                  if (v <= 0 || v >= 1) return const SizedBox.shrink();
                  // Band travels from off the left edge to off the right.
                  final x = -1.6 + 3.2 * v;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(x - 0.6, -1),
                        end: Alignment(x + 0.6, 1),
                        colors: [
                          widget.color.withValues(alpha: 0),
                          widget.color.withValues(alpha: widget.opacity),
                          widget.color.withValues(alpha: 0),
                        ],
                        stops: const [0.3, 0.5, 0.7],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Carousel
// ─────────────────────────────────────────────────────────────────────────

/// 3D snapping carousel: the centred card is full size and flat; the
/// cards beside it tilt away in perspective, shrink, drop a little and
/// fade. Auto-advances every [autoPlay] (paused for a while after the user
/// touches it), ticks a haptic on each new card, and dots follow the swipe.
/// Each page gets its scroll offset (-1 … 1) through [builder] for parallax.
class AppCarousel extends StatefulWidget {
  final int itemCount;
  final double itemWidth;
  final double height;
  final Widget Function(BuildContext context, int index, double offset) builder;
  final Color dotColor;

  /// null = no auto-advance.
  final Duration? autoPlay;

  const AppCarousel({
    super.key,
    required this.itemCount,
    required this.itemWidth,
    required this.height,
    required this.builder,
    this.dotColor = const Color(0xFF1A2C4E),
    this.autoPlay = const Duration(seconds: 4),
  });

  @override
  State<AppCarousel> createState() => _AppCarouselState();
}

class _AppCarouselState extends State<AppCarousel> {
  static const _pauseAfterTouch = Duration(seconds: 8);

  PageController? _pc;
  double _lastWidth = 0;
  double _page = 0;
  int _shown = 0;
  Timer? _timer;
  DateTime _touchedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    final every = widget.autoPlay;
    if (every != null && widget.itemCount > 1) {
      _timer = Timer.periodic(every, (_) => _advance());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc?.dispose();
    super.dispose();
  }

  void _advance() {
    final pc = _pc;
    if (!mounted || pc == null || !pc.hasClients || _reduceMotion(context)) return;
    if (DateTime.now().difference(_touchedAt) < _pauseAfterTouch) return;
    final next = (_page.round() + 1) % widget.itemCount;
    pc.animateToPage(
      next,
      duration: Duration(milliseconds: next == 0 ? 900 : 700),
      curve: Curves.easeInOutCubic,
    );
  }

  PageController _controller(double width) {
    if (_pc == null || width != _lastWidth) {
      final old = _pc;
      _lastWidth = width;
      _pc = PageController(
        // Pages a bit narrower than a card: the side cards are scaled to
        // 84 %, so they sit just clear of the centre card and peek ~50 px.
        viewportFraction: ((widget.itemWidth * 0.94) / width).clamp(0.3, 1.0),
        initialPage: _page.round(),
      )..addListener(() {
          final p = _pc!.page;
          if (p == null || !mounted) return;
          setState(() => _page = p);
          final r = p.round();
          if (r != _shown) {
            _shown = r;
            HapticFeedback.selectionClick();
          }
        });
      if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    return _pc!;
  }

  Widget _page3d(Widget child, double offset) {
    final d = offset.abs().clamp(0.0, 1.0);
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0015) // perspective
      ..translateByDouble(0.0, 14 * d, 0.0, 1.0)
      ..rotateY(-0.42 * offset.clamp(-1.0, 1.0))
      ..scaleByDouble(1 - 0.16 * d, 1 - 0.16 * d, 1.0, 1.0);
    return Opacity(
      opacity: 1 - 0.5 * d,
      child: Transform(alignment: Alignment.center, transform: m, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    return Column(
      children: [
        Listener(
          onPointerDown: (_) => _touchedAt = DateTime.now(),
          child: SizedBox(
            height: widget.height,
            child: LayoutBuilder(builder: (context, box) {
              final pc = _controller(box.maxWidth);
              return PageView.builder(
                controller: pc,
                clipBehavior: Clip.none,
                physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: widget.itemCount,
                itemBuilder: (context, i) {
                  final offset = i - _page;
                  // Pages are narrower than a card (see viewportFraction):
                  // let the card keep its full width instead of squeezing.
                  final child = OverflowBox(
                    minWidth: widget.itemWidth,
                    maxWidth: widget.itemWidth,
                    child: widget.builder(
                        context, i, reduce ? 0 : offset.clamp(-1.0, 1.0)),
                  );
                  return reduce ? child : _page3d(child, offset);
                },
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.itemCount; i++)
              GestureDetector(
                onTap: () {
                  _touchedAt = DateTime.now();
                  _pc?.animateToPage(i,
                      duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
                },
                child: Builder(builder: (_) {
                  final on = (1 - (i - _page).abs()).clamp(0.0, 1.0);
                  return Container(
                    width: 7 + 16 * on,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        widget.dotColor.withValues(alpha: 0.18),
                        widget.dotColor,
                        on,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }
}
