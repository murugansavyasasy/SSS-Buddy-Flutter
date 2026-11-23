import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widget/exhibition_common.dart';
import 'sc_spotlight.dart';
import 'showcase_content.dart';

/// Full-screen School Chimes presentation for visitors at the stall.
/// Five slides (swipe or auto-play), and two actions always at the bottom:
/// hear a voice demo (Give Demo) and leave details (Capture Lead).
///
/// The actions open on top of the showcase; when they finish the visitor
/// is back here, ready for the next person.
class SchoolChimesShowcase extends StatefulWidget {
  /// Null hides the button (e.g. completed exhibition).
  final VoidCallback? onGiveDemo;
  final VoidCallback onCaptureLead;

  const SchoolChimesShowcase({super.key, required this.onGiveDemo, required this.onCaptureLead});

  @override
  State<SchoolChimesShowcase> createState() => _SchoolChimesShowcaseState();
}

class _SchoolChimesShowcaseState extends State<SchoolChimesShowcase> {
  static const _slides = 5;
  static const _slideTime = Duration(seconds: 5);

  final _pages = PageController();
  int _page = 0;
  bool _autoPlay = true;
  Timer? _timer;

  /// True while the slideshow itself is moving the page (not the user).
  bool _autoMoving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_slideTime, (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  /// Auto-advance every 5 s while auto-play is on.
  void _tick() {
    if (!mounted || !_autoPlay || !_pages.hasClients) return;
    if (ModalRoute.of(context)?.isCurrent != true) return; // a demo / lead form is open
    _autoMoving = true;
    _pages
        .animateToPage((_page + 1) % _slides,
            duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic)
        .whenComplete(() => _autoMoving = false);
  }

  /// A swipe, dot tap or "Swipe to explore" by the visitor: stop auto-play
  /// (the play button turns it back on).
  void _stopAuto() {
    if (_autoPlay) setState(() => _autoPlay = false);
  }

  void _goTo(int i) {
    _stopAuto();
    _pages.animateToPage(i, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
  }

  void _run(VoidCallback action) {
    HapticFeedback.selectionClick();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final slides = <Widget>[
      _HeroSlide(onNext: () => _goTo(1)),
      const _ModulesSlide(),
      _VoiceSlide(onGiveDemo: widget.onGiveDemo == null ? null : () => _run(widget.onGiveDemo!)),
      const _RolesSlide(),
      _WhySlide(
        onGiveDemo: widget.onGiveDemo == null ? null : () => _run(widget.onGiveDemo!),
        onCaptureLead: () => _run(widget.onCaptureLead),
      ),
    ];
    return ExTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: scSoft,
          body: NotificationListener<ScrollStartNotification>(
            // A finger drag on the slides (not the slideshow's own move).
            onNotification: (n) {
              if (n.dragDetails != null && !_autoMoving && n.metrics.axis == Axis.horizontal) _stopAuto();
              return false;
            },
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    page: _page,
                    count: _slides,
                    autoPlay: _autoPlay,
                    onDot: _goTo,
                    onToggleAuto: () {
                      HapticFeedback.selectionClick();
                      setState(() => _autoPlay = !_autoPlay);
                      // Next slide a full 5 s after pressing play.
                      _timer?.cancel();
                      _timer = Timer.periodic(_slideTime, (_) => _tick());
                    },
                    onClose: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) => setState(() => _page = i),
                      children: [
                        for (final s in slides)
                          LayoutBuilder(
                            builder: (_, box) => SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: math.max(20, (box.maxWidth - 900) / 2),
                                vertical: 12,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: box.maxHeight - 24),
                                child: Center(child: s),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _ActionBar(
                    onGiveDemo: widget.onGiveDemo == null ? null : () => _run(widget.onGiveDemo!),
                    onCaptureLead: () => _run(widget.onCaptureLead),
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

// ─────────────────────────────────────────────────────────────────────────
// Chrome
// ─────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int page;
  final int count;
  final bool autoPlay;
  final ValueChanged<int> onDot;
  final VoidCallback onToggleAuto;
  final VoidCallback onClose;

  const _TopBar({
    required this.page,
    required this.count,
    required this.autoPlay,
    required this.onDot,
    required this.onToggleAuto,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: scInk),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < count; i++)
                    GestureDetector(
                      onTap: () => onDot(i),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: i == page ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == page ? scCoral : scIndigo.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: autoPlay ? 'Pause slideshow' : 'Play slideshow',
              onPressed: onToggleAuto,
              icon: Icon(autoPlay ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: scIndigo),
            ),
          ],
        ),
      );
}

class _ActionBar extends StatelessWidget {
  final VoidCallback? onGiveDemo;
  final VoidCallback onCaptureLead;
  const _ActionBar({required this.onGiveDemo, required this.onCaptureLead});

  @override
  Widget build(BuildContext context) {
    Widget button({
      required String label,
      required IconData icon,
      required VoidCallback onTap,
      required bool primary,
    }) =>
        Expanded(
          child: SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: primary ? const LinearGradient(colors: [scCoral, Color(0xFFFF7A59)]) : null,
                color: primary ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: primary ? null : Border.all(color: scIndigo.withValues(alpha: 0.25), width: 1.5),
                boxShadow: primary
                    ? const [BoxShadow(color: Color(0x40F2474F), blurRadius: 16, offset: Offset(0, 6))]
                    : null,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 21, color: primary ? Colors.white : scIndigo),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(label,
                                style: TextStyle(
                                  fontFamily: exFont,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: primary ? Colors.white : scIndigo,
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14231A5E), blurRadius: 18, offset: Offset(0, -4))],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            children: [
              if (onGiveDemo != null) ...[
                button(label: 'Hear a voice demo', icon: Icons.phone_in_talk_rounded, onTap: onGiveDemo!, primary: false),
                const SizedBox(width: 12),
              ],
              button(label: "I'm interested", icon: Icons.star_rounded, onTap: onCaptureLead, primary: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades and slides a slide's parts in, one after another.
class _Rise extends StatelessWidget {
  final int index;
  final Widget child;
  const _Rise({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    if (exReduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 110),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 22 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}

class _SlideTitle extends StatelessWidget {
  final String kicker;
  final String title;
  final String? sub;
  const _SlideTitle({required this.kicker, required this.title, this.sub});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: scCoral.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(kicker.toUpperCase(),
              style: const TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: scCoral)),
        ),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: exFont,
                fontSize: wide ? 34 : 26,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: scInk)),
        if (sub != null) ...[
          const SizedBox(height: 10),
          Text(sub!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: wide ? 17 : 15, height: 1.45, color: scMuted)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 1. Hero
// ─────────────────────────────────────────────────────────────────────────

class _HeroSlide extends StatelessWidget {
  final VoidCallback onNext;
  const _HeroSlide({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Rise(
          index: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 22, vertical: wide ? 26 : 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: Color(0x1A231A5E), blurRadius: 30, offset: Offset(0, 12))],
            ),
            // Logo is 600×214; fixed size so the card never collapses while it loads.
            child: SizedBox(
              height: wide ? 120 : 62,
              width: (wide ? 120 : 62) * 600 / 214,
              child: Image.asset(scLogoAsset, fit: BoxFit.contain),
            ),
          ),
        ),
        SizedBox(height: wide ? 28 : 20),
        _Rise(
          index: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: scCoral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: scCoral),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(scHeroBadge,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: wide ? 14.5 : 12.5, fontWeight: FontWeight.w700, color: scCoral)),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: wide ? 18 : 14),
        _Rise(
          index: 1,
          // Forced line break only on wide screens; phones wrap naturally.
          child: Text(wide ? scHeadline : scHeadline.replaceAll('\n', ' '),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: exFont,
                  fontSize: wide ? 42 : 26,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                  color: scIndigoDeep)),
        ),
        const SizedBox(height: 14),
        _Rise(
          index: 2,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(scHeroText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: wide ? 18 : 15, height: 1.5, color: scMuted)),
          ),
        ),
        SizedBox(height: wide ? 32 : 24),
        _Rise(
          index: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Row(
              children: [
                for (final (k, (value, label)) in scStats.indexed) ...[
                  if (k > 0) SizedBox(width: wide ? 14 : 8),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: wide ? 14 : 8, vertical: wide ? 16 : 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: k == 0
                              ? const [scIndigoDeep, scIndigo]
                              : k == 1
                                  ? const [scCoral, Color(0xFFFF7A59)]
                                  : const [Color(0xFFE79A2B), scYellow],
                        ),
                        borderRadius: BorderRadius.circular(wide ? 20 : 16),
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(value,
                                maxLines: 1,
                                style: TextStyle(
                                    fontFamily: exFont,
                                    fontSize: wide ? 30 : 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                          const SizedBox(height: 2),
                          Text(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: wide ? 13 : 11.5,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9))),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        _Rise(
          index: 4,
          child: TextButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.swipe_left_rounded, color: scIndigo),
            label: const Text('Swipe to explore',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: scIndigo)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 2. Modules
// ─────────────────────────────────────────────────────────────────────────

class _ModulesSlide extends StatelessWidget {
  const _ModulesSlide();

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth >= 820 ? 6 : box.maxWidth >= 560 ? 4 : 3;
        final gap = box.maxWidth >= 560 ? 14.0 : 10.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Rise(
              index: 0,
              child: _SlideTitle(
                kicker: 'One platform',
                title: 'Everything your school runs on',
                sub: 'Tap any module to see what it does.',
              ),
            ),
            const SizedBox(height: 16),
            _Rise(
              index: 1,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HighlightChip(icon: Icons.apps_rounded, label: '${scModules.length} modules', color: scIndigo),
                  const _HighlightChip(icon: Icons.login_rounded, label: 'One login', color: scCoral),
                  const _HighlightChip(icon: Icons.groups_rounded, label: 'Every role', color: Color(0xFF1E9E6A)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (k, m) in scModules.indexed)
                  _Rise(
                    index: 2 + k ~/ cols,
                    child: SizedBox(
                      width: w,
                      child: _ModuleTile(module: m, showLine: w >= 130, onTap: () => showScModuleSheet(context, m)),
                    ),
                  ),
              ],
            ),
          ],
        );
      });
}

/// Small pill under the modules title ("18 modules", "One login" …).
class _HighlightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HighlightChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}

/// One module tile: tinted gradient card, gradient icon badge, and a short
/// description when there is room. Shrinks slightly while pressed.
class _ModuleTile extends StatefulWidget {
  final ScModule module;
  final bool showLine;
  final VoidCallback onTap;
  const _ModuleTile({required this.module, required this.showLine, required this.onTap});

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _down = false;

  void _press(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    final c = m.color;
    final badge = widget.showLine ? 52.0 : 46.0;
    return AnimatedScale(
      scale: _down ? 0.95 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color.lerp(Colors.white, c, 0.07)!],
          ),
          border: Border.all(color: c.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(color: c.withValues(alpha: _down ? 0.06 : 0.13), blurRadius: _down ? 8 : 18, offset: Offset(0, _down ? 3 : 8)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: c.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            onTap: widget.onTap,
            onHighlightChanged: _press,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, widget.showLine ? 18 : 14, 8, widget.showLine ? 16 : 12),
              child: Column(
                children: [
                  Container(
                    width: badge,
                    height: badge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(badge * 0.32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.lerp(c, Colors.white, 0.18)!, c],
                      ),
                      boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(m.icon, size: badge * 0.5, color: Colors.white),
                  ),
                  SizedBox(height: widget.showLine ? 12 : 9),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(m.title,
                        maxLines: 1,
                        style: TextStyle(
                            fontFamily: exFont,
                            fontSize: widget.showLine ? 15 : 13.5,
                            fontWeight: FontWeight.w800,
                            color: scInk)),
                  ),
                  if (widget.showLine) ...[
                    const SizedBox(height: 3),
                    // Fixed two-line box so every tile in a row is the same height.
                    SizedBox(
                      height: 32,
                      child: Text(m.line,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(fontSize: 12, height: 1.3, color: scMuted)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 3. Voice calls (the thing the visitor can try right now)
// ─────────────────────────────────────────────────────────────────────────

class _VoiceSlide extends StatelessWidget {
  final VoidCallback? onGiveDemo;
  const _VoiceSlide({required this.onGiveDemo});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final points = <(IconData, String)>[
      (Icons.mic_rounded, 'Record a message once, every parent gets a call'),
      (Icons.call_received_rounded, 'See who answered and who missed it'),
      (Icons.replay_rounded, 'Missed calls can be sent again'),
      (Icons.campaign_rounded, 'Messages, circulars and homework alongside'),
    ];
    final illustration = _Rise(index: 1, child: _RingingPhone(size: wide ? 220 : 170));
    final text = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        for (final (k, (icon, line)) in points.indexed)
          _Rise(
            index: 2 + k,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: scCoral),
                  const SizedBox(width: 10),
                  Flexible(child: Text(line, style: const TextStyle(fontSize: 15, height: 1.35, color: scInk))),
                ],
              ),
            ),
          ),
        if (onGiveDemo != null) ...[
          const SizedBox(height: 8),
          _Rise(
            index: 7,
            child: FilledButton.icon(
              onPressed: onGiveDemo,
              style: FilledButton.styleFrom(
                backgroundColor: scIndigo,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.phone_in_talk_rounded),
              label: const Text('Get a demo call on your phone',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Rise(
          index: 0,
          child: _SlideTitle(
            kicker: 'Voice calls',
            title: 'Parents hear the school,\nnot just read it',
            sub: 'A voice call reaches every parent, even those who never open a message.',
          ),
        ),
        const SizedBox(height: 22),
        wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [illustration, const SizedBox(width: 36), Expanded(child: text)],
              )
            : Column(children: [illustration, const SizedBox(height: 18), text]),
      ],
    );
  }
}

/// Phone with the School Chimes bell, ringing (expanding waves).
class _RingingPhone extends StatefulWidget {
  final double size;
  const _RingingPhone({required this.size});

  @override
  State<_RingingPhone> createState() => _RingingPhoneState();
}

class _RingingPhoneState extends State<_RingingPhone> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final still = exReduceMotion(context);
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            for (final d in [0.0, 0.33, 0.66])
              Builder(builder: (_) {
                final t = still ? 0.5 : (_c.value + d) % 1.0;
                return Container(
                  width: s * (0.45 + 0.55 * t),
                  height: s * (0.45 + 0.55 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scCoral.withValues(alpha: (1 - t) * 0.45), width: 2),
                  ),
                );
              }),
            Transform.rotate(
              angle: still ? 0 : math.sin(_c.value * math.pi * 8) * 0.08 * (_c.value < 0.4 ? 1 : 0),
              child: Container(
                width: s * 0.42,
                height: s * 0.42,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [scCoral, Color(0xFFFF7A59)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x55F2474F), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: s * 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 4. Roles
// ─────────────────────────────────────────────────────────────────────────

class _RolesSlide extends StatelessWidget {
  const _RolesSlide();

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth >= 760 ? 3 : box.maxWidth >= 480 ? 2 : 1;
        const gap = 12.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        const colors = [scIndigo, scCoral, Color(0xFF1E9E6A), Color(0xFFE08A00), Color(0xFF6C4BD8)];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Rise(
              index: 0,
              child: _SlideTitle(
                kicker: 'For everyone',
                title: 'Built for everyone in the school',
                sub: 'Each person sees what they need, nothing more.',
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (k, (icon, role, line)) in scRoles.indexed)
                  _Rise(
                    index: 1 + k,
                    child: Container(
                      width: w,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border(left: BorderSide(color: colors[k % colors.length], width: 4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors[k % colors.length].withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: colors[k % colors.length], size: 23),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(role,
                                    style: const TextStyle(
                                        fontFamily: exFont, fontSize: 17, fontWeight: FontWeight.w800, color: scInk)),
                                const SizedBox(height: 3),
                                Text(line, style: const TextStyle(fontSize: 14, height: 1.4, color: scMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      });
}

// ─────────────────────────────────────────────────────────────────────────
// 5. Why + call to action
// ─────────────────────────────────────────────────────────────────────────

class _WhySlide extends StatelessWidget {
  final VoidCallback? onGiveDemo;
  final VoidCallback onCaptureLead;
  const _WhySlide({required this.onGiveDemo, required this.onCaptureLead});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth >= 640 ? 2 : 1;
        const gap = 12.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Rise(
              index: 0,
              child: _SlideTitle(kicker: 'Why School Chimes', title: 'Why schools choose us'),
            ),
            const SizedBox(height: 12),
            // Our story (About page), two lines.
            _Rise(
              index: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    for (final (k, line) in scAbout.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: k == 0 ? 0 : 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 1),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: (k == 0 ? scCoral : scIndigo).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(k == 0 ? Icons.record_voice_over_rounded : Icons.hub_rounded,
                                  size: 14, color: k == 0 ? scCoral : scIndigo),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(line, style: const TextStyle(fontSize: 15, height: 1.45, color: scMuted)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (k, (icon, title, line)) in scWhy.indexed)
                  _Rise(
                    index: 1 + k,
                    child: Container(
                      width: w,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: k.isEven ? scIndigo : scCoral, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontFamily: exFont, fontSize: 17, fontWeight: FontWeight.w800, color: scInk)),
                                const SizedBox(height: 4),
                                Text(line, style: const TextStyle(fontSize: 14, height: 1.45, color: scMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            _Rise(
              index: 6,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scIndigoDeep, scIndigo],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text('Want to see it for your school?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: exFont, fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Leave your details and our team will show you School Chimes with your own school\'s data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.5, height: 1.45, color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: onCaptureLead,
                          style: FilledButton.styleFrom(
                            backgroundColor: scCoral,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.star_rounded),
                          label: const Text("I'm interested", style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                        ),
                        if (onGiveDemo != null)
                          OutlinedButton.icon(
                            onPressed: onGiveDemo,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.phone_in_talk_rounded),
                            label: const Text('Hear a voice demo',
                                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      });
}
