import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../auth/model/ExhibitionModel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design system (Exhibition Demos App spec)
// One brand colour (slate blue) on ink. Touch scale for a busy stall: every
// target ≥ 48 px, inputs and buttons 52 px, body copy 16 px.
// ─────────────────────────────────────────────────────────────────────────────

/// text.default
const exInk = Color(0xFF1E2B45);

/// background.brand
const exBrand = Color(0xFF5770A6);

/// background.brand.bold
const exBrandBold = Color(0xFF3F5485);

/// selected.bold — tab underline, stepper line, toast tick
const exIndicator = Color(0xFFAFC0E8);

/// background.selected — blue tint
const exTint = Color(0xFFECEFF8);

/// text.subtle
const exSubtle = Color(0xFF71717A);

/// background.neutral — page
const exPageBg = Color(0xFFF4F6FA);

/// border.default
const exBorder = Color(0xFFE3E7EF);

/// Inputs and outlined buttons.
const exStrongBorder = Color(0xFFCDD3DF);

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
const exCompletedBg = Color(0xFFE4E9F5);
const exCompletedInk = exBrandBold;

/// Recipient "Visitor" badge.
const exVisitorBg = Color(0xFFF1ECD6);

/// Recording red.
const exRecord = Color(0xFFE7000B);

/// Primary gradient: brand bold → brand.
const exBrandGradient = LinearGradient(colors: [exBrandBold, exBrand]);

const exFont = 'DMSans';

/// Kept for older call sites; the spec uses border, no shadow, on cards.
const exCardShadow = <BoxShadow>[];

/// Toast / FAB overlay elevation.
const exOverlayShadow = [
  BoxShadow(color: Color(0x2E3F5485), blurRadius: 14, offset: Offset(0, 4)),
];

/// Content never stretches wider than this on an iPad / tablet.
const double exMaxContentWidth = 820;

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
/// the tablet). The user's own accessibility text size still applies on top.
const double exPhoneTextScale = 0.85;

bool exIsPhone(BuildContext context) => MediaQuery.sizeOf(context).shortestSide < 600;

class _ExTextScale extends StatelessWidget {
  final Widget child;
  const _ExTextScale({required this.child});

  @override
  Widget build(BuildContext context) {
    if (!exIsPhone(context)) return child;
    final mq = MediaQuery.of(context);
    if (mq.textScaler is _ScaledTextScaler) return child; // already applied above
    return MediaQuery(
      data: mq.copyWith(textScaler: _ScaledTextScaler(mq.textScaler, exPhoneTextScale)),
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
      InterestLevel.hot => (exSuccessBg, exSuccess),
      InterestLevel.warm => (exCalling, exCallingInk),
      InterestLevel.cold => (exCompletedBg, exCompletedInk),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(level.label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
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
    return ExPill(label: status.label, background: bg, foreground: fg, large: large);
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
  });

  @override
  Widget build(BuildContext context) {
    final pad = exIsWide(context) ? 24.0 : 16.0;
    return ExTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: exPageBg,
          floatingActionButton: floatingActionButton,
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: headerDivider
                      ? const Border(bottom: BorderSide(color: exBorder))
                      : null,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad - 8, 8, pad, headerBottom == null ? 8 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            ExBackButton(
                              onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: largeTitle
                                    ? exHeadingXl
                                    : const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: exSubtle,
                                      ),
                              ),
                            ),
                            ...actions,
                          ],
                        ),
                        if (headerBottom != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 12),
                            child: headerBottom!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: body),
            ],
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
  Widget build(BuildContext context) => SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: 'Back',
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: exInk),
        ),
      );
}

/// 48 px plain icon button for the white header (e.g. split / full screen).
class ExHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const ExHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, size: 22, color: exInk),
        ),
      );
}

/// Centres content and caps its width on tablets.
class ExMaxWidth extends StatelessWidget {
  final Widget child;
  const ExMaxWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: exMaxContentWidth),
          child: child,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges, chips, cards
// ─────────────────────────────────────────────────────────────────────────────

/// Status badge: 6 px corners, 600 weight.
class ExPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final bool large;

  const ExPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: large ? 10 : 8, vertical: large ? 5 : 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: large ? 14 : 13,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      );
}

/// Grey count chip on cards: "3 attendees", "4 demos".
class ExStatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const ExStatChip({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: exPageBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: exInk),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: exInk)),
          ],
        ),
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
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
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

/// Card: white, 12 px corners, border, no shadow. Selected = tint + brand border.
class ExCard extends StatelessWidget {
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
  Widget build(BuildContext context) => Material(
        color: highlighted ? exTint : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlighted ? exBrand : exBorder,
                width: highlighted ? 1.5 : 1,
              ),
            ),
            child: child,
          ),
        ),
      );
}

/// Cream notes box.
class ExNoteBox extends StatelessWidget {
  final String text;
  final bool icon;
  const ExNoteBox({super.key, required this.text, this.icon = false});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: exNotes,
          borderRadius: BorderRadius.circular(8),
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
  const ExPersonChip({super.key, required this.name, required this.number});

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: exBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: exTint, shape: BoxShape.circle),
              child: Text(exInitials(name),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: exInk)),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: exHeadingSm.copyWith(fontSize: 15)),
                Text(number, style: exBodyMd.copyWith(fontSize: 13)),
              ],
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
                ? const LinearGradient(colors: [Color(0xFF34466F), exBrandBold])
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          width: widget.expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: disabled ? exBorder : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(8),
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
                child: Text(
                  widget.loading ? (widget.loadingLabel ?? widget.label) : widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: widget.height >= 56 ? 18 : 17,
                      fontWeight: FontWeight.w600,
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
            side: const BorderSide(color: exStrongBorder),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontFamily: exFont, fontSize: 16, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      );
}

/// Round 64 px brand FAB with a plus.
class ExFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  const ExFab({super.key, required this.onPressed, this.tooltip = 'New exhibition'});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: tooltip,
        child: Tooltip(
          message: tooltip,
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [exBrandBold, exBrand],
                ),
                boxShadow: exOverlayShadow,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 26, color: fg),
              ),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: exHeadingSm),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: exSubtle)),
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

/// Grey placeholder rows while a list loads, with a caption.
class ExSkeletonList extends StatelessWidget {
  final int count;
  final String? caption;
  const ExSkeletonList({super.key, this.count = 3, this.caption});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < count; i++) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: exBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(0.55, 18),
                  const SizedBox(height: 12),
                  _bar(0.85, 12),
                  const SizedBox(height: 10),
                  _bar(0.4, 12),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(caption!, textAlign: TextAlign.center, style: exBodyMd),
            ),
        ],
      );

  Widget _bar(double f, double h) => FractionallySizedBox(
        widthFactor: f,
        child: Container(
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF0F5),
            borderRadius: BorderRadius.circular(4),
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
        borderRadius: BorderRadius.circular(8),
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
            style: exHeadingSm.copyWith(fontSize: 15),
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
        borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.horizontal(left: Radius.circular(6.5)),
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
    fillColor: enabled ? Colors.white : exPageBg,
    isDense: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: b(exStrongBorder),
    enabledBorder: b(exStrongBorder),
    disabledBorder: b(exBorder),
    focusedBorder: b(exBrandBold, 1.5),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                          backgroundColor: destructive ? exDanger : exBrandBold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle:
                              const TextStyle(fontFamily: exFont, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        child: Text(confirmLabel, overflow: TextOverflow.ellipsis),
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
