import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/model/PaymentSubmissionModel.dart';
import '../../../values/colors/app_colors.dart';

/// Shared styling for Payment Submissions (School Chimes palette from the
/// design: indigo brand, slate text, status chip colours).

const psFont = 'DMSans';

// Brand: the app's primary colour (AppColors), so the module matches the
// rest of SSS Buddy.
const psBrand = AppColors.primary;
const psBrandDark = AppColors.primaryDark;
const psBrandSoft = Color(0xFFC9D3E6);
const psTint = AppColors.tint;
const psInk = Color(0xFF10141F);
const psBody = Color(0xFF2E3648);
const psSubtle = Color(0xFF4A5468);
const psMuted = Color(0xFF6B7689);
const psBorder = Color(0xFFDDE2EA);
const psStrongBorder = Color(0xFFBFC6D2);
const psPageBg = Color(0xFFF8FAFC);
const psSuccess = Color(0xFF0B7150);
const psSuccessBg = Color(0xFFE3F5EE);
const psWarn = Color(0xFF9A5B00);
const psWarnBg = Color(0xFFFFF3DC);
const psDanger = Color(0xFFB33228);
const psDangerBg = Color(0xFFFFE7E5);
const psNeutralBg = Color(0xFFEFF2F6);

const psRadius = 14.0;
const psRadiusControl = 10.0;

const psShadow = [
  BoxShadow(color: Color(0x140E1440), blurRadius: 2, offset: Offset(0, 1)),
];

/// Reference / invoice numbers: DM Sans with even-width digits (iOS has no
/// "monospace" family, so a real monospace font would fall back anyway).
const psMono = TextStyle(
  fontFamily: psFont,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.2,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// Background and text colour of a status chip.
(Color, Color) psStageColors(SubmissionStage s) => switch (s) {
      SubmissionStage.awaitingBank => (const Color(0xFFE3E9F5), psBrandDark),
      SubmissionStage.foundInBank => (psWarnBg, psWarn),
      SubmissionStage.receipted => (psSuccessBg, psSuccess),
      SubmissionStage.rejected => (psDangerBg, psDanger),
      SubmissionStage.withdrawn => (psNeutralBg, psSubtle),
    };

/// True when the user asked the OS for less motion.
bool psReduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// DM Sans and the feature's colours for everything below it.
class PsTheme extends StatelessWidget {
  final Widget child;
  const PsTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(primary: psBrand, secondary: psBrand),
        textTheme: base.textTheme.apply(fontFamily: psFont, bodyColor: psInk, displayColor: psInk),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: psBrand),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: psBrand,
          selectionHandleColor: psBrand,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? psBrand : Colors.white),
          side: const BorderSide(color: psStrongBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: psFont, color: psInk),
        child: child,
      ),
    );
  }
}

/// Indigo header with a back button, a title and an optional subtitle.
class PsHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// 0–1: a thin progress line under the header (the submit steps).
  final double? progress;

  const PsHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(6, top + 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: psFont,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        if (subtitle != null)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(subtitle!,
                                key: ValueKey(subtitle),
                                style: const TextStyle(
                                    fontFamily: psFont,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: psBrandSoft)),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            if (progress != null)
              TweenAnimationBuilder<double>(
                tween: Tween(end: progress!.clamp(0, 1)),
                duration: psReduceMotion(context) ? Duration.zero : const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  backgroundColor: psBrandDark,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// White rounded card with a hairline border; tappable when [onTap] is set.
class PsCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final Color? color;

  const PsCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
    this.selected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: psReduceMotion(context) ? Duration.zero : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(psRadius),
          border: Border.all(color: selected ? psBrand : psBorder, width: selected ? 2 : 1),
          boxShadow: psShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(psRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

/// Small upper-case status chip.
class PsChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const PsChip({super.key, required this.label, required this.background, required this.foreground});

  factory PsChip.stage(SubmissionStage s) {
    final (bg, fg) = psStageColors(s);
    return PsChip(label: s.label, background: bg, foreground: fg);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(4)),
        child: Text(label.toUpperCase(),
            maxLines: 1,
            style: TextStyle(
                fontFamily: psFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: foreground)),
      );
}

/// Full-width indigo button with a spinner while [loading].
class PsPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;

  const PsPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.color = psBrand,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        width: double.infinity,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: loading ? color : psStrongBorder,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(psRadiusControl)),
            textStyle: const TextStyle(fontFamily: psFont, fontSize: 15.5, fontWeight: FontWeight.w700),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
      );
}

/// White bar pinned at the bottom (above the keyboard) holding the main action.
class PsBottomBar extends StatelessWidget {
  final Widget child;
  const PsBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: psBorder)),
        ),
        child: child,
      );
}

/// Empty / error state with an optional action.
class PsStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  const PsStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message = '',
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  factory PsStateView.error(Object error, {VoidCallback? onRetry, String title = "Couldn't load"}) =>
      PsStateView(
        icon: Icons.wifi_off_rounded,
        title: title,
        message: error.toString(),
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
        isError: true,
      );

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isError ? psDangerBg : psTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: isError ? psDanger : psBrand),
              ),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: psFont, fontSize: 17, fontWeight: FontWeight.w700, color: psInk)),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: psFont, fontSize: 14, height: 1.4, color: psSubtle)),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: psBrand,
                    side: const BorderSide(color: psBrand, width: 1.5),
                    minimumSize: const Size(120, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(psRadiusControl)),
                    textStyle: const TextStyle(fontFamily: psFont, fontWeight: FontWeight.w700),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Amber (or red) note box: warnings from the AI read, server errors.
class PsNote extends StatelessWidget {
  final String message;
  final bool error;
  final IconData? icon;

  const PsNote({super.key, required this.message, this.error = false, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: error ? psDangerBg : psWarnBg,
          borderRadius: BorderRadius.circular(psRadiusControl),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? (error ? Icons.error_outline_rounded : Icons.warning_amber_rounded),
                size: 18, color: error ? psDanger : psWarn),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontFamily: psFont,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: error ? psDanger : psWarn)),
            ),
          ],
        ),
      );
}

/// "Label ........ value" row used in the read card and the detail screen.
class PsKeyValue extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const PsKeyValue({super.key, required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(label,
                  style: const TextStyle(fontFamily: psFont, fontSize: 13, color: psMuted)),
            ),
            Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  style: (mono ? psMono : const TextStyle(fontFamily: psFont)).copyWith(
                      fontSize: 13.5, fontWeight: FontWeight.w600, color: psInk)),
            ),
          ],
        ),
      );
}

/// Fades and slides a list item in once, staggered by [index].
class PsAppear extends StatelessWidget {
  final int index;
  final Widget child;
  const PsAppear({super.key, this.index = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    if (psReduceMotion(context)) return child;
    final delay = (index.clamp(0, 8)) * 0.06;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (delay * 1000).round()),
      curve: Interval(delay / (0.32 + delay), 1, curve: Curves.easeOutCubic),
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: c),
      ),
      child: child,
    );
  }
}

/// Field label with an optional required star and "From proof" tag. Always
/// one line high, so fields side by side start at the same height.
class PsFieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  final bool fromProof;

  /// Half-width fields: the tag shrinks to its sparkle icon.
  final bool compact;

  const PsFieldLabel(this.text, {super.key, this.required = false, this.fromProof = false, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
        height: 22,
        margin: const EdgeInsets.only(bottom: 6, left: 2),
        child: Row(
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: text),
                  if (required) const TextSpan(text: ' *', style: TextStyle(color: psDanger)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: psFont, fontSize: 13, fontWeight: FontWeight.w600, color: psSubtle),
              ),
            ),
            if (fromProof && compact) ...[
              const SizedBox(width: 6),
              const Tooltip(
                message: 'From proof',
                child: Icon(Icons.auto_awesome_rounded, size: 14, color: psBrand),
              ),
            ] else if (fromProof) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: psTint, borderRadius: BorderRadius.circular(4)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 11, color: psBrand),
                    SizedBox(width: 3),
                    Text('From proof',
                        style: TextStyle(
                            fontFamily: psFont, fontSize: 10.5, fontWeight: FontWeight.w700, color: psBrand)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

/// Small upper-case heading above a card ("PROGRESS", "PAYMENT DETAILS").
class PsSectionLabel extends StatelessWidget {
  final String text;
  const PsSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontFamily: psFont,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: psMuted)),
      );
}

/// Grey hint under a field, lined up with the field's label.
class PsHelperText extends StatelessWidget {
  final String text;
  const PsHelperText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
        child: Text(text, style: const TextStyle(fontFamily: psFont, fontSize: 12, color: psMuted)),
      );
}

/// Input decoration for the details form.
InputDecoration psInput({String? hint, String? error, String? helper, Widget? prefix, Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      errorText: error,
      helperText: helper,
      helperMaxLines: 2,
      errorMaxLines: 3,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      hintStyle: const TextStyle(fontFamily: psFont, color: psMuted, fontWeight: FontWeight.w400),
      helperStyle: const TextStyle(fontFamily: psFont, fontSize: 12, color: psMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(psRadiusControl),
        borderSide: const BorderSide(color: psBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(psRadiusControl),
        borderSide: const BorderSide(color: psBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(psRadiusControl),
        borderSide: const BorderSide(color: psBrand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(psRadiusControl),
        borderSide: const BorderSide(color: psDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(psRadiusControl),
        borderSide: const BorderSide(color: psDanger, width: 1.5),
      ),
    );

/// Rounded search field: icon, text, a clear button and a "Search" pill.
/// Nothing is searched until the pill or the keyboard's Search is tapped.
class PsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final String hint;

  const PsSearchBar({
    super.key,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final motion = psReduceMotion(context) ? Duration.zero : const Duration(milliseconds: 180);
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: motion,
          height: 52,
          padding: const EdgeInsets.only(left: 14, right: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: focused ? psBrand : psBorder, width: focused ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: focused ? psBrand.withValues(alpha: 0.18) : const Color(0x0F0E1440),
                blurRadius: focused ? 14 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 22, color: focused ? psBrand : psMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (_) => onChanged(),
                  onSubmitted: (_) => onSearch(),
                  textInputAction: TextInputAction.search,
                  cursorColor: psBrand,
                  style: const TextStyle(fontFamily: psFont, fontSize: 15, fontWeight: FontWeight.w500, color: psInk),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(fontFamily: psFont, fontSize: 14.5, color: psMuted, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: motion,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: a, alignment: Alignment.centerRight, child: c),
                ),
                child: !hasText
                    ? const SizedBox.shrink()
                    : Row(
                        key: const ValueKey('actions'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Clear search',
                            child: InkResponse(
                              onTap: onClear,
                              radius: 22,
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(color: psNeutralBg, shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, size: 15, color: psSubtle),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            height: 38,
                            child: FilledButton(
                              onPressed: onSearch,
                              style: FilledButton.styleFrom(
                                backgroundColor: psBrand,
                                foregroundColor: Colors.white,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                                textStyle: const TextStyle(
                                    fontFamily: psFont, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Search'),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
