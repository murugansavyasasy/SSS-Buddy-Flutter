import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../Values/Colors/app_colors.dart';
import '../../../auth/model/ExhibitionModel.dart';
import '../../../components/toolbar_layout.dart';

const exPageBg = Color(0xFFF5F7FB);
const exInk = Color(0xFF1A2235);
const exSubtle = Color(0xFF6B7280);
const exBorder = Color(0xFFE3E7EF);
const exStrongBorder = Color(0xFFC8CFDC);
const exTint = Color(0xFFECEFF8);
const exDanger = Color(0xFFC2000A);

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

/// Round translucent button for the blue toolbar (matches its refresh button).
class ExToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const ExToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: Colors.white30),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(icon, key: ValueKey(icon), color: Colors.white, size: 21),
              ),
            ),
          ),
        ),
      );
}

const exCardShadow = [
  BoxShadow(color: Color(0x0D1A2235), blurRadius: 14, offset: Offset(0, 4)),
];

(Color, Color) exhibitionStatusColors(ExhibitionStatus s) => s == ExhibitionStatus.active
    ? (const Color(0xFFE7F7EC), const Color(0xFF1A7F3C))
    : (const Color(0xFFEFF1F5), exInk);

(Color, Color) callStatusColors(CallStatus s) => switch (s) {
      CallStatus.queued => (const Color(0xFFEFF1F5), exInk),
      CallStatus.ringing || CallStatus.calling => (const Color(0xFFFFEBDC), const Color(0xFFA3561F)),
      CallStatus.answered || CallStatus.completed => (const Color(0xFFE7F7EC), const Color(0xFF1A7F3C)),
      CallStatus.failed => (const Color(0xFFFDECEC), exDanger),
    };

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

String exWhen(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final time = DateFormat('h:mm a').format(t);
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

/// Blue header + rounded light body, the same frame as Follow-ups / Leaderboard.
class ExPage extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onSearch;
  final String searchHint;
  final Widget? floatingActionButton;
  final VoidCallback? onBackPressed;
  final Widget? trailing;

  const ExPage({
    super.key,
    required this.title,
    required this.body,
    this.onRefresh,
    this.onSearch,
    this.searchHint = 'Search...',
    this.floatingActionButton,
    this.onBackPressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        floatingActionButton: floatingActionButton,
        body: Column(
          children: [
            ToolbarLayout(
              title: title,
              onRefresh: onRefresh,
              onSearch: onSearch,
              searchHint: searchHint,
              onBackPressed: onBackPressed,
              trailing: trailing,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: exPageBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class ExPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const ExPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
            ),
          ],
        ),
      );
}

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
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : exCardShadow,
        ),
        child: Material(
          color: highlighted ? exTint : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: highlighted ? AppColors.primary : exBorder,
                  width: highlighted ? 1.5 : 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
}

/// Full-width 52 px primary button with a loading state.
class ExPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final double height;

  const ExPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final base = AppColors.primary;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled || loading ? 1 : 0.55,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Color.lerp(base, Colors.black, 0.12)!, Color.lerp(base, Colors.white, 0.12)!],
          ),
          boxShadow: enabled
              ? [BoxShadow(color: base.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  else if (icon != null)
                    Icon(icon, size: 20, color: Colors.white),
                  if (loading || icon != null) const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      loading ? (loadingLabel ?? label) : label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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

class ExSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;

  const ExSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? exInk,
            side: const BorderSide(color: exStrongBorder),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      );
}

/// Empty / error message with an optional action.
class ExStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  const ExStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message = '',
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  factory ExStateView.error(Object error, {VoidCallback? onRetry}) => ExStateView(
        icon: Icons.wifi_off_rounded,
        title: "Couldn't load",
        message: error.toString(),
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
        isError: true,
      );

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isError ? const Color(0xFFFDECEC) : exTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: isError ? exDanger : AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: exInk),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: exSubtle),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                ExSecondaryButton(
                  label: actionLabel!,
                  icon: isError ? Icons.refresh_rounded : Icons.add_rounded,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      );
}

/// Grey placeholder rows while a list loads.
class ExSkeletonList extends StatelessWidget {
  final int count;
  const ExSkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 112,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: exBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(0.6, 16),
              const SizedBox(height: 10),
              _bar(0.85, 11),
              const SizedBox(height: 8),
              _bar(0.45, 11),
            ],
          ),
        ),
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

/// Labelled text field used by the exhibition forms (52 px tall).
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
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (required)
                  const TextSpan(text: ' *', style: TextStyle(color: exDanger)),
              ],
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exInk),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            textCapitalization: textCapitalization,
            style: const TextStyle(fontSize: 16, color: exInk),
            decoration: exInputDecoration(
              hint: hint,
              errorText: errorText,
              prefixText: prefixText,
              prefixIcon: prefixIcon,
            ),
          ),
        ],
      );
}

InputDecoration exInputDecoration({
  String? hint,
  String? errorText,
  String? prefixText,
  IconData? prefixIcon,
}) =>
    InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20, color: exSubtle),
      errorText: errorText,
      prefixText: prefixText,
      prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: exInk),
      hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: exStrongBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: exStrongBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: exDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: exDanger, width: 1.6),
      ),
    );

void exToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? exDanger : exInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                color: error ? Colors.white : const Color(0xFFAFC0E8), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
}

/// Exhibition status badge: Active gets a live, pulsing green dot;
/// Completed gets a calm slate badge with a tick.
class ExStatusBadge extends StatelessWidget {
  final ExhibitionStatus status;
  final bool large;

  const ExStatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final active = status == ExhibitionStatus.active;
    const green = Color(0xFF16A34A);
    const greenInk = Color(0xFF15803D);
    const slate = Color(0xFF64748B);
    final fs = large ? 13.0 : 12.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: large ? 6 : 5),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(colors: [Color(0xFFE8F8EE), Color(0xFFD5F2E0)])
            : const LinearGradient(colors: [Color(0xFFF1F4F8), Color(0xFFE7EBF1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? green.withValues(alpha: 0.35) : slate.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active)
            const _PulseDot(color: green)
          else
            Icon(Icons.check_circle_rounded, size: fs + 2, color: slate),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: fs,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: active ? greenInk : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 12,
        height: 12,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 6 + 6 * _c.value,
                height: 6 + 6 * _c.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
              ),
            ],
          ),
        ),
      );
}
