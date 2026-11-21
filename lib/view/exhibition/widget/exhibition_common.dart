import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../auth/model/ExhibitionModel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design system (Exhibition Demos App spec)
// One brand colour (sky blue) on ink. Touch scale for a busy stall: every
// target ≥ 48 px, inputs and buttons 52 px, body copy 16 px.
// ─────────────────────────────────────────────────────────────────────────────

/// text.default
const exInk = Color(0xFF14243B);

/// background.brand
const exBrand = Color(0xFF06B6D4);

/// background.brand.bold
const exBrandBold = Color(0xFF1D4ED8);

/// selected.bold — tab underline, stepper line, toast tick
const exIndicator = Color(0xFF9CC9FF);

/// background.selected — blue tint
const exTint = Color(0xFFE8F1FF);

/// text.subtle
const exSubtle = Color(0xFF71717A);

/// background.neutral — page
const exPageBg = Color(0xFFF2F6FD);

/// border.default
const exBorder = Color(0xFFE1E7F2);

/// Inputs and outlined buttons.
const exStrongBorder = Color(0xFFC8D3E6);

/// accent.orange.subtle — calling / ringing / warm
const exCalling = Color(0xFFFFEBDC);
const exCallingInk = Color(0xFFA3561F);

/// text.danger.bold — failed / error
const exDanger = Color(0xFFC2000A);
const exDangerBg = Color(0xFFFDECEC);

/// surface.cream — notes
const exNotes = Color(0xFFF9F7E8);

/// Success (active exhibition, success states).
const exSuccess = Color(0xFF1A7F3C);
const exSuccessBg = Color(0xFFE5F5EA);

/// Grey badge (queued).
const exNeutralBg = Color(0xFFEFF1F5);

/// Completed (exhibition, demo) and answered call: blue tint, brand bold text.
const exCompletedBg = Color(0xFFE3ECFD);
const exCompletedInk = exBrandBold;

/// Recipient "Visitor" badge.
const exVisitorBg = Color(0xFFF1ECD6);

/// Recording red.
const exRecord = Color(0xFFE7000B);

/// Primary gradient: brand bold → brand.
const exBrandGradient = LinearGradient(colors: [exBrandBold, exBrand]);

const exFont = 'DMSans';

/// Screen header: deep navy fading into [exHeaderBase] (same as the app's
/// other screens); the page body curves up over it.
const exHeaderBase = Color(0xFF0891B2);
const exHeaderGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF1E40AF), Color(0xFF1D4ED8), exHeaderBase],
  stops: [0.0, 0.45, 1.0],
);

/// Status bar over the light sky header: dark icons.
const exHeaderOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
);

/// Soft, layered card shadow (cards float on the page instead of a hard border).
const exCardShadow = [
  BoxShadow(color: Color(0x0F14243B), blurRadius: 18, offset: Offset(0, 6)),
  BoxShadow(color: Color(0x0A14243B), blurRadius: 3, offset: Offset(0, 1)),
];

/// Toast / FAB overlay elevation.
const exOverlayShadow = [
  BoxShadow(color: Color(0x2E1D4ED8), blurRadius: 14, offset: Offset(0, 4)),
];

/// Brand glow under primary buttons and the FAB.
const exBrandGlow = [
  BoxShadow(color: Color(0x401D4ED8), blurRadius: 16, offset: Offset(0, 6)),
];

/// Corner radii.
const double exRadiusCard = 18;
const double exRadiusControl = 14;

/// Diagonal brand gradient for hero tiles, avatars and the FAB.
/// Deep diagonal gradient for summary / hero cards (overview, insights,
/// exhibition header).
const exDeepGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1E3A8A), exBrandBold, exHeaderBase],
);

const exHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [exBrandBold, exBrand],
);

/// Accent colours for the three counters (attendees, demos, leads).
const exAccentTeam = Color(0xFF7A5AF8);
const exAccentTeamBg = Color(0xFFF1EDFF);
const exAccentDemo = exBrandBold;
const exAccentDemoBg = exTint;
const exAccentLead = Color(0xFFE08A00);
const exAccentLeadBg = Color(0xFFFFF4DE);

/// Content never stretches wider than this on an iPad / tablet.
const double exMaxContentWidth = 820;

/// Narrower centred column for single-column forms (Create Exhibition,
/// Give Demo) so iPad doesn't stretch them edge to edge.
const double exFormMaxWidth = 640;

bool exIsWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 700;

/// iPad only: list on the left, the selected exhibition on the right.
/// Phones (and an iPad in a narrow Slide Over / multitasking window) keep the
/// single-column push navigation.
bool exIsSplit(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 && size.width >= 760;
}

/// Applies DM Sans to everything below (each route and sheet wraps itself,
/// since routes are built above any widget in this module).
class ExTheme extends StatelessWidget {
  final Widget child;
  const ExTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: exFont),
        primaryTextTheme: base.primaryTextTheme.apply(fontFamily: exFont),
        colorScheme: base.colorScheme.copyWith(primary: exBrandBold),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: exBrandBold,
          selectionColor: exIndicator,
          selectionHandleColor: exBrandBold,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: exFont, color: exInk),
        child: _ExTextScale(child: child),
      ),
    );
  }
}

/// Phone text is set a step smaller than iPad (the spec sizes are tuned for
/// the tablet). The user's own accessibility text size still applies on top,
/// capped at [exMaxUserTextScale] so large Android font settings don't break
/// the fixed-height cards and rows.
const double exPhoneTextScale = 0.85;
const double exMaxUserTextScale = 1.15;

bool exIsPhone(BuildContext context) => MediaQuery.sizeOf(context).shortestSide < 600;

class _ExTextScale extends StatelessWidget {
  final Widget child;
  const _ExTextScale({required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.textScaler is _ScaledTextScaler) return child; // already applied above
    // The app root (DeviceTextScale) already caps the user's setting and
    // shrinks text on narrow phones; this cap only guards screens shown
    // outside it.
    final user = mq.textScaler.clamp(maxScaleFactor: exMaxUserTextScale);
    final factor = exIsPhone(context) ? exPhoneTextScale : 1.0;
    return MediaQuery(
      data: mq.copyWith(textScaler: _ScaledTextScaler(user, factor)),
      child: child,
    );
  }
}

/// The system text scaler multiplied by a fixed factor.
class _ScaledTextScaler extends TextScaler {
  final TextScaler base;
  final double factor;
  const _ScaledTextScaler(this.base, this.factor);

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _ScaledTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

// Typography (DM Sans 500 / 600)
const exHeadingXl = TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w600, color: exInk);
const exHeadingLg = TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600, color: exInk);
const exHeadingMd = TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600, color: exInk);
const exHeadingSm = TextStyle(fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w600, color: exInk);
const exBodyTouch = TextStyle(fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w500, color: exInk);
const exBodyMd = TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: exSubtle);
const exBodySm = TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, color: exSubtle);
const exLabelSm = TextStyle(
    fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: exSubtle);

// ─────────────────────────────────────────────────────────────────────────────
// Status colours
// ─────────────────────────────────────────────────────────────────────────────

(Color, Color) exhibitionStatusColors(ExhibitionStatus s) => s == ExhibitionStatus.active
    ? (exSuccessBg, exSuccess)
    : (exCompletedBg, exCompletedInk);

(Color, Color) interestLevelColors(InterestLevel l) => switch (l) {
      InterestLevel.excellent => (exSuccessBg, exSuccess),
      InterestLevel.good => (exCalling, exCallingInk),
      InterestLevel.average => (exCompletedBg, exCompletedInk),
    };

(Color, Color) callStatusColors(CallStatus s) => switch (s) {
      CallStatus.queued => (exNeutralBg, exInk),
      CallStatus.ringing || CallStatus.calling => (exCalling, exCallingInk),
      CallStatus.answered || CallStatus.completed => (exCompletedBg, exCompletedInk),
      CallStatus.failed => (exDangerBg, exDanger),
    };

/// Hot / Warm / Cold tag with a coloured dot.
class ExInterestTag extends StatelessWidget {
  final InterestLevel level;
  const ExInterestTag({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = interestLevelColors(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (level) {
              InterestLevel.excellent => Icons.local_fire_department_rounded,
              InterestLevel.good => Icons.thumb_up_alt_rounded,
              InterestLevel.average => Icons.trending_flat_rounded,
            },
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(level.label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

/// Exhibition status badge (Active / Completed).
class ExStatusBadge extends StatelessWidget {
  final ExhibitionStatus status;
  final bool large;

  const ExStatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = exhibitionStatusColors(status);
    return ExPill(
      label: status.label,
      background: bg,
      foreground: fg,
      large: large,
      dot: status == ExhibitionStatus.active,
      icon: status == ExhibitionStatus.active ? null : Icons.check_circle_rounded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatting
// ─────────────────────────────────────────────────────────────────────────────

String exInitials(String name) {
  final parts = name.replaceAll(RegExp(r'[^A-Za-z ]'), ' ').trim().split(RegExp(r'\s+'));
  final words = parts.length > 1 && parts.first.length <= 3 ? parts.sublist(1) : parts;
  final s = words.take(2).map((w) => w.isEmpty ? '' : w[0]).join().toUpperCase();
  return s.isEmpty ? '?' : s;
}

String exDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Dates not set';
  final full = DateFormat('d MMM yyyy');
  if (start != null && end == null) return full.format(start);
  if (start == null) return 'Until ${full.format(end!)}';
  if (start.year == end!.year && start.month == end.month) {
    if (start.day == end.day) return full.format(start);
    return '${start.day} – ${full.format(end)}';
  }
  if (start.year == end.year) {
    return '${DateFormat('d MMM').format(start)} – ${full.format(end)}';
  }
  return '${full.format(start)} – ${full.format(end)}';
}

/// "11 – 13 Nov" (no year) for the detail header line.
String exShortDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return '';
  final dm = DateFormat('d MMM');
  if (start != null && end == null) return dm.format(start);
  if (start == null) return 'Until ${dm.format(end!)}';
  if (start.month == end!.month && start.year == end.year) {
    if (start.day == end.day) return dm.format(start);
    return '${start.day} – ${dm.format(end)}';
  }
  return '${dm.format(start)} – ${dm.format(end)}';
}

String exWhen(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final time = DateFormat('h:mm a').format(t).toLowerCase();
  bool same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  if (now.difference(t).inMinutes.abs() < 1) return 'Just now';
  if (same(t, now)) return time;
  if (same(t, now.subtract(const Duration(days: 1)))) return 'Yesterday, $time';
  if (t.year == now.year) return '${DateFormat('d MMM').format(t)}, $time';
  return DateFormat('d MMM yyyy').format(t);
}

String exDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

// ─────────────────────────────────────────────────────────────────────────────
// Page frame
// ─────────────────────────────────────────────────────────────────────────────

/// White header with a back chevron and either a large title
/// ("‹ Exhibitions") or a small back label ("‹ Exhibitions" breadcrumb),
/// optional [headerBottom] (search, chips), and the page-grey body.
class ExPage extends StatelessWidget {
  final String title;
  final Widget body;

  /// Large heading.xl title next to the chevron. When false, [title] is
  /// shown as a small grey back label instead.
  final bool largeTitle;
  final Widget? headerBottom;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final VoidCallback? onBackPressed;
  final bool headerDivider;

  /// Small line under the title ("3 active shows").
  final String? subtitle;

  const ExPage({
    super.key,
    required this.title,
    required this.body,
    this.largeTitle = true,
    this.headerBottom,
    this.actions = const [],
    this.floatingActionButton,
    this.onBackPressed,
    this.headerDivider = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final pad = exIsWide(context) ? 24.0 : 16.0;
    return ExTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: exHeaderOverlay,
        child: Scaffold(
          backgroundColor: exHeaderBase,
          floatingActionButton: floatingActionButton,
          body: Column(
            children: [
              ExGradientHeader(
                padding: EdgeInsets.fromLTRB(pad - 8, 8, pad, 18),
                child: Row(
                  children: [
                    ExBackButton(
                      onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: largeTitle
                                ? exHeadingLg.copyWith(
                                    fontWeight: FontWeight.w700, color: Colors.white)
                                : TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              Expanded(
                child: ExCurvedBody(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (headerBottom != null)
                        Container(
                          decoration: BoxDecoration(
                            color: exPageBg,
                            border: headerDivider
                                ? const Border(bottom: BorderSide(color: exBorder))
                                : null,
                          ),
                          padding: EdgeInsets.fromLTRB(pad, 18, pad, 12),
                          child: headerBottom!,
                        ),
                      // Keep the last rows above the Android navigation bar /
                      // iOS home indicator; the curved body colour still
                      // fills the area behind it.
                      Expanded(
                        child: SafeArea(top: false, child: body),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sky gradient screen header. Draws under the status bar; buttons inside
/// ([ExBackButton], [ExHeaderIconButton]) switch to glass / white circles.
class ExGradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ExGradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 16, 18),
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(gradient: exHeaderGradient),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Soft light bubbles for depth.
            const Positioned(top: -60, right: -40, child: _HeaderBubble(size: 180, alpha: 0.18)),
            const Positioned(top: 30, right: 90, child: _HeaderBubble(size: 70, alpha: 0.14)),
            const Positioned(bottom: -50, left: -30, child: _HeaderBubble(size: 120, alpha: 0.12)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: padding,
                child: _ExOnHeader(
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.white),
                    child: IconTheme.merge(
                      data: const IconThemeData(color: Colors.white),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _HeaderBubble extends StatelessWidget {
  final double size;
  final double alpha;
  const _HeaderBubble({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: alpha),
          ),
        ),
      );
}

/// Page body with rounded top corners, sitting under an [ExGradientHeader]
/// (put [exHeaderBase] behind it so the corners show the header colour).
class ExCurvedBody extends StatelessWidget {
  final Widget child;
  final Color color;

  const ExCurvedBody({super.key, required this.child, this.color = exPageBg});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: child,
      );
}

/// Marks widgets that sit on the sky header.
class _ExOnHeader extends InheritedWidget {
  const _ExOnHeader({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ExOnHeader>() != null;

  @override
  bool updateShouldNotify(_ExOnHeader oldWidget) => false;
}

/// 48 px touch target; on the sky header a glass / white circle.
class _ExHeaderButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback? onTap;
  final bool solid;

  const _ExHeaderButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.onTap,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!_ExOnHeader.of(context)) {
      return SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, size: size, color: exInk),
        ),
      );
    }
    // Back: frosted glass circle. Actions: solid white circle.
    final shape = CircleBorder(
      side: BorderSide(
        color: solid ? Colors.white : Colors.white.withValues(alpha: 0.45),
        width: 1.2,
      ),
    );
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: solid ? Colors.white : Colors.white.withValues(alpha: 0.18),
            shape: shape,
            elevation: solid ? 0.5 : 0,
            shadowColor: const Color(0x331D4ED8),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  icon,
                  size: size,
                  color: solid
                      ? (onTap == null ? exInk.withValues(alpha: 0.35) : exInk)
                      : (onTap == null ? Colors.white.withValues(alpha: 0.4) : Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 48 px back chevron.
class ExBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ExBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => _ExHeaderButton(
        icon: Icons.arrow_back_ios_new_rounded,
        size: 20,
        tooltip: 'Back',
        onTap: onPressed,
      );
}

/// 48 px header icon button (e.g. split / full screen, close, search).
class ExHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const ExHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
      _ExHeaderButton(icon: icon, size: 22, tooltip: tooltip, onTap: onTap, solid: true);
}

/// iPad header pill: "Full view" (while split) / "Split view" (while full).
class ExSplitToggle extends StatelessWidget {
  final bool split;
  final VoidCallback onTap;
  const ExSplitToggle({super.key, required this.split, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = split ? 'Full view' : 'Split view';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: Colors.white, width: 1.2)),
        elevation: 0.5,
        shadowColor: const Color(0x331D4ED8),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  split ? Icons.fullscreen_rounded : Icons.vertical_split_outlined,
                  size: 20,
                  color: exInk,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: exFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: exInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centres content and caps its width on tablets.
class ExMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ExMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = exMaxContentWidth,
  });

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges, chips, cards
// ─────────────────────────────────────────────────────────────────────────────

/// Status badge: capsule, 600 weight. [dot] shows a live dot before the label.
class ExPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final bool large;
  final bool dot;

  const ExPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.large = false,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: large ? 5 : 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: foreground,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: foreground.withValues(alpha: 0.45), blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
            ],
            // Long labels end in "…" at full size instead of overflowing.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: large ? 14 : 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Tinted count chip: "3 attendees", "4 demos". [color] tints icon and text.
class ExStatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color background;
  const ExStatChip({
    super.key,
    required this.icon,
    required this.text,
    this.color = exInk,
    this.background = exPageBg,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
      );
}

/// Big number tile: tinted icon bubble, value and label ("12 Demos").
const _metricStyle =
    TextStyle(fontSize: 20, height: 1.1, fontWeight: FontWeight.w700, color: exInk);

class ExMetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  const ExMetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(exRadiusControl + 2),
          boxShadow: exCardShadow,
        ),
        // Wide tile (iPad): icon beside the number. Narrow tile (three in a
        // phone row): icon above, or the label had no room ("De…").
        child: LayoutBuilder(builder: (context, box) {
          final iconBox = Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: color),
          );
          final texts = _texts();
          return box.maxWidth >= 150
              ? Row(children: [iconBox, const SizedBox(width: 12), Expanded(child: texts)])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [iconBox, const SizedBox(height: 10), texts],
                );
        }),
        ),
      );

  Widget _texts() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: int.tryParse(value) == null
                  ? Text(value, maxLines: 1, style: _metricStyle)
                  : ExCountUp(int.parse(value), style: _metricStyle),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label,
                  maxLines: 1, style: exBodySm.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// Motion
// ─────────────────────────────────────────────────────────────────────────────

/// True when the user asked the system to reduce motion.
bool exReduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Fades and slides its child up into place once, staggered by [index]
/// (capped so long lists don't wait). Give it a new key to replay.
///
/// With a [key], each item plays only the first time it is shown: cards
/// scrolled out of a lazy list and back, or rebuilt after a refresh, stay
/// put instead of flickering in again.
class ExAppear extends StatefulWidget {
  final int index;
  final Widget child;
  final double offset;
  const ExAppear({super.key, this.index = 0, this.offset = 16, required this.child});

  static const _step = Duration(milliseconds: 55);
  static const _run = Duration(milliseconds: 380);

  /// Keys that already played (lives for the app session; bounded below).
  static final Set<Key> _played = <Key>{};

  /// Tests: let every item play again.
  @visibleForTesting
  static void resetPlayed() => _played.clear();

  @override
  State<ExAppear> createState() => _ExAppearState();
}

class _ExAppearState extends State<ExAppear> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  late Animation<double> _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null || exReduceMotion(context)) return;
    final key = widget.key;
    if (key != null && !ExAppear._played.add(key)) return; // seen before
    if (ExAppear._played.length > 500) ExAppear._played.clear();
    final delay = ExAppear._step * widget.index.clamp(0, 6);
    final total = delay + ExAppear._run;
    // Delay inside the animation (an Interval), so nothing waits on a Timer
    // and the item is fully hidden until its turn.
    _c = AnimationController(vsync: this, duration: total)..forward();
    _t = CurvedAnimation(
      parent: _c!,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c == null) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
      ),
    );
  }
}

/// Number that counts up to [value] (and animates between later values).
class ExCountUp extends StatelessWidget {
  final int value;
  final TextStyle? style;
  const ExCountUp(this.value, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    if (exReduceMotion(context)) return Text('$value', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}', style: style),
    );
  }
}

/// Scales its child in with a small overshoot (icons, ticks, FAB).
class ExPopIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  const ExPopIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    if (exReduceMotion(context)) return child;
    final total = 450 + delay.inMilliseconds;
    final start = delay.inMilliseconds / total;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(start, 1, curve: Curves.easeOutBack),
      builder: (_, t, child) => Transform.scale(
        scale: 0.6 + 0.4 * t,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: child,
    );
  }
}

/// Section heading with an optional trailing widget ("Team · 3").
class ExSectionTitle extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;
  const ExSectionTitle({super.key, required this.title, this.caption, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [exBrand, exBrandBold],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: exInk),
                children: [
                  if (caption != null && caption!.isNotEmpty)
                    TextSpan(
                      text: '  $caption',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500, color: exSubtle),
                    ),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

/// Filter chip: ink when selected, outlined otherwise. 48 px tall.
class ExFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ExFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? exInk : Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: selected ? exInk : exStrongBorder),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : exInk,
                ),
              ),
            ),
          ),
        ),
      );
}

/// Card: white, 18 px corners, soft shadow and a hairline border; shrinks
/// a little while pressed. Selected = tint + brand border.
class ExCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted;

  const ExCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlighted = false,
  });

  @override
  State<ExCard> createState() => _ExCardState();
}

class _ExCardState extends State<ExCard> {
  bool _down = false;

  void _press(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(exRadiusCard);
    return AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: exCardShadow),
        child: Material(
          color: widget.highlighted ? exTint : Colors.white,
          borderRadius: radius,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _press(true),
            onTapUp: (_) => _press(false),
            onTapCancel: () => _press(false),
            borderRadius: radius,
            splashColor: exTint,
            highlightColor: exTint.withValues(alpha: 0.5),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: widget.highlighted ? exBrand : const Color(0xFFEDF1F6),
                  width: widget.highlighted ? 1.5 : 1,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cream notes box.
class ExNoteBox extends StatelessWidget {
  final String text;
  final bool icon;
  const ExNoteBox({super.key, required this.text, this.icon = false});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: exNotes,
          borderRadius: BorderRadius.circular(exRadiusControl),
          border: Border.all(color: const Color(0xFFEDE8C8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon) ...[
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.description_outlined, size: 16, color: exSubtle),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(text, style: exBodyMd.copyWith(color: exInk, fontSize: 15))),
          ],
        ),
      );
}

/// Attendee chip: initials avatar, name and number, bordered.
class ExPersonChip extends StatelessWidget {
  final String name;
  final String number;

  /// Shows a ✕ to remove the person (e.g. while adding attendees).
  final VoidCallback? onRemove;

  const ExPersonChip({super.key, required this.name, required this.number, this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        padding: EdgeInsets.fromLTRB(8, 0, onRemove == null ? 14 : 2, 0),
        decoration: BoxDecoration(
          color: onRemove == null ? Colors.white : exTint,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: onRemove == null ? exBorder : exIndicator),
          boxShadow: onRemove == null ? exCardShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: onRemove == null ? exHeroGradient : null,
                color: onRemove == null ? null : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(exInitials(name),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: onRemove == null ? Colors.white : exInk)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: exHeadingSm.copyWith(fontSize: 15)),
                  Text(number, maxLines: 1, style: exBodyMd.copyWith(fontSize: 13)),
                ],
              ),
            ),
            if (onRemove != null)
              SizedBox(
                width: 44,
                height: 48,
                child: IconButton(
                  tooltip: 'Remove $name',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 18, color: exSubtle),
                ),
              ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Buttons
// ─────────────────────────────────────────────────────────────────────────────

/// Primary: 52 px (56 for the hero action), 8 px corners, brand gradient.
/// Pressed = darker, loading = lighter with spinner, disabled = grey.
class ExPrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final double height;
  final bool expand;

  const ExPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.height = 52,
    this.expand = true,
  });

  @override
  State<ExPrimaryButton> createState() => _ExPrimaryButtonState();
}

class _ExPrimaryButtonState extends State<ExPrimaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final disabled = widget.onPressed == null && !widget.loading;
    final Gradient? gradient = disabled
        ? null
        : widget.loading
            ? LinearGradient(colors: [
                exBrandBold.withValues(alpha: 0.7),
                exBrand.withValues(alpha: 0.7),
              ])
            : _down
                ? const LinearGradient(colors: [Color(0xFF1E3A8A), exBrandBold])
                : exBrandGradient;
    final fg = disabled ? exSubtle : Colors.white;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          width: widget.expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: disabled ? exBorder : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(exRadiusControl),
            boxShadow: enabled && !_down ? exBrandGlow : null,
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                ),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 21, color: fg),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: _FitLabel(
                  widget.loading ? (widget.loadingLabel ?? widget.label) : widget.label,
                  style: TextStyle(
                      fontSize: widget.height >= 56 ? 18 : 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: fg),
                ),
              ),
              if (widget.trailingIcon != null && !widget.loading) ...[
                const SizedBox(width: 8),
                Icon(widget.trailingIcon, size: 22, color: fg),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// Secondary: white, outlined, 8 px corners. [color] tints text (danger).
class ExSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;
  final bool loading;

  const ExSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.height = 52,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? exInk,
            disabledForegroundColor: loading ? (color ?? exInk) : exStrongBorder,
            side: BorderSide(color: color?.withValues(alpha: 0.35) ?? exStrongBorder, width: 1.2),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(exRadiusControl)),
            textStyle: const TextStyle(fontFamily: exFont, fontSize: 16, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(exPageBg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color ?? exSubtle),
                ),
                const SizedBox(width: 10),
              ] else if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: _FitLabel(label)),
            ],
          ),
        ),
      );
}

/// Extended brand FAB: plus and a label ("New exhibition").
class ExFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  const ExFab({super.key, required this.onPressed, this.tooltip = 'New exhibition'});

  @override
  Widget build(BuildContext context) => ExPopIn(
        delay: const Duration(milliseconds: 250),
        child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        // Shadow on its own box outside the Material: Material clips its
        // ink layer (where an Ink decoration paints) to the button's
        // rectangle, which cut the glow off with hard edges.
        child: DecoratedBox(
          decoration: const ShapeDecoration(shape: StadiumBorder(), shadows: exBrandGlow),
          child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          child: Ink(
            height: 56,
            decoration: const ShapeDecoration(
              shape: StadiumBorder(),
              gradient: exHeroGradient,
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                onPressed();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 22, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tooltip,
                      style: const TextStyle(
                        fontFamily: exFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

enum ExTone { neutral, success, error }

/// Empty / error / success message: tinted icon circle, title, message and
/// one way forward.
class ExStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;
  final ExTone? tone;

  /// Use a primary (filled) action instead of an outlined one.
  final bool primaryAction;

  const ExStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message = '',
    this.actionLabel,
    this.onAction,
    this.isError = false,
    this.tone,
    this.primaryAction = false,
  });

  /// Couldn't load … — offline wording for a stall with patchy Wi-Fi.
  factory ExStateView.error(
    Object error, {
    VoidCallback? onRetry,
    String title = "Couldn't load",
    String message = 'Check the stall Wi-Fi or mobile data.',
  }) =>
      ExStateView(
        icon: Icons.wifi_off_rounded,
        title: title,
        message: message,
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
        isError: true,
      );

  @override
  Widget build(BuildContext context) {
    final t = tone ?? (isError ? ExTone.error : ExTone.neutral);
    final (bg, fg) = switch (t) {
      ExTone.neutral => (exNeutralBg, exInk),
      ExTone.success => (exSuccessBg, exSuccess),
      ExTone.error => (exDangerBg, exDanger),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon inside two soft rings.
              ExPopIn(
                child: Container(
                width: 112,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg.withValues(alpha: 0.45), shape: BoxShape.circle),
                child: Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: exCardShadow,
                    ),
                    child: Icon(icon, size: 26, color: fg),
                  ),
                ),
              ),
              ),
              const SizedBox(height: 18),
              ExAppear(
                index: 1,
                offset: 10,
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: exHeadingMd.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                ExAppear(
                  index: 2,
                  offset: 10,
                  child: Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: exSubtle)),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                primaryAction
                    ? ExPrimaryButton(
                        label: actionLabel!,
                        expand: false,
                        height: 48,
                        onPressed: onAction,
                      )
                    : ExSecondaryButton(label: actionLabel!, height: 48, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing placeholder cards while a list loads, with a caption.
class ExSkeletonList extends StatefulWidget {
  final int count;
  final String? caption;
  const ExSkeletonList({super.key, this.count = 3, this.caption});

  @override
  State<ExSkeletonList> createState() => _ExSkeletonListState();
}

class _ExSkeletonListState extends State<ExSkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < widget.count; i++) ...[
            FadeTransition(
              opacity: Tween(begin: 0.55, end: 1.0).animate(_pulse),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(exRadiusCard),
                  boxShadow: exCardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF0F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bar(0.6, 18),
                          const SizedBox(height: 12),
                          _bar(0.9, 12),
                          const SizedBox(height: 10),
                          _bar(0.45, 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (widget.caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.caption!, textAlign: TextAlign.center, style: exBodyMd),
            ),
        ],
      );

  Widget _bar(double f, double h) => FractionallySizedBox(
        widthFactor: f,
        child: Container(
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF0F5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
}

/// Inline note: error (red, warning triangle) or info (orange, i).
class ExInlineNote extends StatelessWidget {
  final String message;
  final bool error;
  final Widget? action;

  const ExInlineNote({super.key, required this.message, this.error = true, this.action});

  @override
  Widget build(BuildContext context) {
    final fg = error ? exDanger : exCallingInk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: error ? exDangerBg : const Color(0xFFFFF5EE),
        borderRadius: BorderRadius.circular(exRadiusControl),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(error ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inputs
// ─────────────────────────────────────────────────────────────────────────────

/// Labelled 52 px text field used by the exhibition forms.
/// [prefixText] "+91" renders as a separate grey segment (phone input).
class ExField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final bool required;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;
  final bool enabled;

  const ExField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.required = false,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters,
    this.prefixText,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.sentences,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (required) const TextSpan(text: ' *', style: TextStyle(color: exDanger)),
              ],
            ),
            style: exHeadingSm.copyWith(fontSize: 14, color: const Color(0xFF3A4A60)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            textCapitalization: textCapitalization,
            style: exBodyTouch,
            decoration: exInputDecoration(
              hint: hint,
              errorText: errorText,
              prefixText: prefixText,
              prefixIcon: prefixIcon,
              enabled: enabled,
            ),
          ),
        ],
      );
}

/// Turns digits typed on Hindi / Tamil / other Indian keyboards (१२३, ௧௨௩…)
/// into 0-9. Put it first, before any digits-only filter, on number fields;
/// otherwise those digits are silently dropped and nothing can be typed.
class ExAsciiDigitsFormatter extends TextInputFormatter {
  const ExAsciiDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = asciiDigits(newValue.text);
    if (text == newValue.text) return newValue;
    // Every mapped digit is one UTF-16 unit before and after, so offsets hold.
    return newValue.copyWith(text: text);
  }
}

InputDecoration exInputDecoration({
  String? hint,
  String? errorText,
  String? prefixText,
  IconData? prefixIcon,
  bool enabled = true,
}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  final phone = prefixText != null && prefixText.trim().startsWith('+');
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    errorMaxLines: 3,
    errorStyle: const TextStyle(
        fontFamily: exFont, fontSize: 13, fontWeight: FontWeight.w500, color: exDanger),
    prefixIcon: phone
        ? Container(
            width: 56,
            // Inset so the field's own border (incl. the red error border)
            // stays visible around the grey "+91" segment.
            margin: const EdgeInsets.fromLTRB(1.5, 1.5, 12, 1.5),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: exPageBg,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(10.5)),
              border: Border(right: BorderSide(color: exStrongBorder)),
            ),
            child: Text(prefixText.trim(),
                style: const TextStyle(
                    fontFamily: exFont, fontSize: 16, fontWeight: FontWeight.w600, color: exInk)),
          )
        : prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20, color: exSubtle),
    prefixIconConstraints: phone ? const BoxConstraints(minHeight: 52) : null,
    prefixText: phone ? null : prefixText,
    prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: exInk),
    hintStyle: const TextStyle(
        fontFamily: exFont, fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9A9AA3)),
    filled: true,
    fillColor: enabled ? const Color(0xFFFBFCFE) : exPageBg,
    isDense: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: b(exStrongBorder),
    enabledBorder: b(const Color(0xFFD7E0EA)),
    disabledBorder: b(exBorder),
    focusedBorder: b(exBrand, 2),
    errorBorder: b(exDanger, 1.5),
    focusedErrorBorder: b(exDanger, 1.5),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast
// ─────────────────────────────────────────────────────────────────────────────

/// Ink toast with a tinted tick ("Interest captured", "Exhibition created").
void exToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? exDanger : exInk,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: error ? Colors.white24 : exIndicator,
                shape: BoxShape.circle,
              ),
              child: Icon(error ? Icons.priority_high_rounded : Icons.check_rounded,
                  color: error ? Colors.white : exInk, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontFamily: exFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
}

/// Centered confirm popup: bold title, body, outlined cancel + filled confirm
/// side by side. Returns true when the confirm button is tapped.
Future<bool> showExConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: exFont, fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w700, color: exInk)),
              const SizedBox(height: 10),
              Text(message,
                  style: const TextStyle(
                      fontFamily: exFont, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500, color: exSubtle)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ExSecondaryButton(
                      label: cancelLabel,
                      height: 48,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: destructive ? exDanger : exBrandBold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(exRadiusControl)),
                          textStyle:
                              const TextStyle(fontFamily: exFont, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        child: _FitLabel(confirmLabel),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return ok == true;
}


/// One-line button label that shrinks to fit narrow buttons (small phones)
/// instead of being cut off with an ellipsis.
class _FitLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _FitLabel(this.text, {this.style});

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, maxLines: 1, softWrap: false, style: style),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step-by-step flows (Create Exhibition, Give Demo, Capture Lead)
// One friendly question per screen instead of a long form.
// ─────────────────────────────────────────────────────────────────────────────

/// Segmented progress bar: "●●○○○  Step 2 of 5". Filled segments animate.
class ExStepProgress extends StatelessWidget {
  final int current; // 0-based
  final int total;
  final String? label;
  const ExStepProgress({super.key, required this.current, required this.total, this.label});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: exBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      widthFactor: i <= current ? 1 : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: exHeroGradient,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(label ?? 'Step ${current + 1} of $total',
              style: exLabelSm.copyWith(color: exBrandBold, letterSpacing: 0.3)),
        ],
      );
}

/// Big friendly question: icon bubble, title and helper line, animated in.
class ExQuestion extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final Color background;
  final bool optional;

  const ExQuestion({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = exBrandBold,
    this.background = exTint,
    this.optional = false,
  });

  /// Icon on the left of the title (saves a whole row of height), title
  /// and subtitle beside it.
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExPopIn(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, size: 27, color: color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Centre a one-line title on the icon.
                const SizedBox(height: 2),
                ExAppear(
                  index: 1,
                  offset: 10,
                  child: Text.rich(
                    TextSpan(
                      text: title,
                      children: [
                        if (optional)
                          const TextSpan(
                            text: '  optional',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exSubtle),
                          ),
                      ],
                    ),
                    style: const TextStyle(
                        fontSize: 23, height: 1.2, fontWeight: FontWeight.w700, color: exInk),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ExAppear(
                    index: 2,
                    offset: 10,
                    child: Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 15.5, height: 1.35, fontWeight: FontWeight.w500, color: exSubtle)),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

/// Large, airy text input for one-question steps (no form-box look):
/// white rounded surface with a soft shadow; brand ring when focused.
class ExBigInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final int maxLines;
  final String? prefixText;
  final FocusNode? focusNode;

  const ExBigInput({
    super.key,
    required this.controller,
    this.hint,
    this.errorText,
    this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.sentences,
    this.autofocus = false,
    this.maxLines = 1,
    this.prefixText,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c, [double w = 0]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
        );
    return ExAppear(
      index: 3,
      offset: 10,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: exCardShadow,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          minLines: 1,
          cursorColor: exBrandBold,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: exInk),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFFA6ADBA)),
            errorText: errorText,
            errorMaxLines: 3,
            errorStyle: const TextStyle(
                fontFamily: exFont, fontSize: 14, fontWeight: FontWeight.w600, color: exDanger),
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(icon, size: 24, color: exBrand),
                  ),
            prefixText: prefixText,
            prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: exInk),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            border: b(exBorder),
            enabledBorder: b(exBorder),
            focusedBorder: b(exBrand, 2),
            errorBorder: b(exDanger, 1.5),
            focusedErrorBorder: b(exDanger, 2),
          ),
        ),
      ),
    );
  }
}

/// Tap-to-pick suggestion / choice chip ("Recent: [Chennai] [Kochi]").
class ExPickChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const ExPickChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: selected ? exHeroGradient : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? Colors.transparent : exStrongBorder),
            boxShadow: selected ? exBrandGlow : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected || icon != null) ...[
                      Icon(selected ? Icons.check_rounded : icon,
                          size: 18, color: selected ? Colors.white : exBrandBold),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : exInk)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Big tappable choice card (e.g. interest level, template). Tints and
/// shows a popping tick when selected.
class ExChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final Color background;

  const ExChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.color = exBrandBold,
    this.background = exTint,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? background : Colors.white,
              borderRadius: BorderRadius.circular(exRadiusCard),
              border: Border.all(color: selected ? color : exBorder, width: selected ? 2 : 1),
              boxShadow: selected
                  ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))]
                  : exCardShadow,
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: selected ? 1.1 : 1,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : background,
                      borderRadius: BorderRadius.circular(exRadiusControl),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: selected ? color : exInk)),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: exBodyMd),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: selected
                      ? Container(
                          key: const ValueKey('on'),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        )
                      : Container(
                          key: const ValueKey('off'),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: exStrongBorder, width: 2),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// One line of the final summary card: icon, label, value and an Edit link
/// that jumps back to that step.
class ExSummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final Color color;
  final Color background;

  const ExSummaryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
    this.color = exBrandBold,
    this.background = exTint,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(exRadiusControl),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: exLabelSm.copyWith(fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(value.isEmpty ? '—' : value,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: exInk)),
                  ],
                ),
              ),
              if (onEdit != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 8),
                  child: Text('Edit',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: exBrandBold)),
                ),
            ],
          ),
        ),
      );
}

/// Switches step content with a slide in the direction of travel.
/// [step] is the current index; going to a higher index slides from the right.
class ExStepSwitcher extends StatefulWidget {
  final int step;
  final Widget child;
  const ExStepSwitcher({super.key, required this.step, required this.child});

  @override
  State<ExStepSwitcher> createState() => _ExStepSwitcherState();
}

class _ExStepSwitcherState extends State<ExStepSwitcher> {
  bool _forward = true;

  @override
  void didUpdateWidget(ExStepSwitcher old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) _forward = widget.step > old.step;
  }

  @override
  Widget build(BuildContext context) {
    if (exReduceMotion(context)) return widget.child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, anim) {
        final incoming = child.key == ValueKey(widget.step);
        final dx = (incoming ? 1 : -1) * (_forward ? 0.12 : -0.12);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(widget.step), child: widget.child),
    );
  }
}

/// Bottom bar for step flows: optional round Back, and a wide Next / Save.
class ExStepBar extends StatelessWidget {
  final VoidCallback? onBack;
  final String nextLabel;
  final IconData? nextIcon;
  final VoidCallback? onNext;
  final bool loading;
  final String? loadingLabel;
  final Widget? leading; // e.g. "Skip" text button

  const ExStepBar({
    super.key,
    this.onBack,
    required this.nextLabel,
    this.nextIcon = Icons.arrow_forward_rounded,
    this.onNext,
    this.loading = false,
    this.loadingLabel,
    this.leading,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x1414243B), blurRadius: 24, offset: Offset(0, -6))],
        ),
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + MediaQuery.paddingOf(context).bottom),
        child: ExMaxWidth(
          maxWidth: exFormMaxWidth,
          child: Row(
            children: [
              if (onBack != null) ...[
                SizedBox(
                  width: 56,
                  height: 56,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: loading ? null : onBack,
                    style: IconButton.styleFrom(
                      backgroundColor: exPageBg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(exRadiusControl)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, color: exInk),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(
                child: ExPrimaryButton(
                  label: nextLabel,
                  trailingIcon: nextIcon,
                  height: 56,
                  loading: loading,
                  loadingLabel: loadingLabel,
                  onPressed: onNext,
                ),
              ),
            ],
          ),
        ),
      );
}
