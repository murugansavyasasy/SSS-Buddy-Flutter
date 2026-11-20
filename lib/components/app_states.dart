import 'package:flutter/material.dart';

import '../Values/Colors/app_colors.dart';
import 'app_motion.dart';

/// Loading / error / empty states shared by the list screens, so every
/// module shows the same animated skeleton, a friendly error with Retry and
/// an illustrated empty message instead of a bare spinner or "Error: …".

bool _reduce(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

// ─────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────

/// A light sweep that runs across [child] forever (skeleton shimmer).
class AppShimmer extends StatefulWidget {
  final Widget child;
  const AppShimmer({super.key, required this.child});

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduce(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final x = -1.5 + 3 * _c.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x - 0.8, -0.3),
            end: Alignment(x + 0.8, 0.3),
            colors: const [Color(0xFFE4E9F1), Color(0xFFF7F9FC), Color(0xFFE4E9F1)],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// Grey placeholder bar.
class AppBone extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const AppBone({super.key, this.width, this.height = 12, this.radius = 6});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF4),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Skeleton of a card list (avatar + two lines + a chip row) shown while a
/// list loads. Matches the white rounded cards used across the app.
class AppListSkeleton extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;
  const AppListSkeleton({super.key, this.count = 6, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDF0F5)),
            ),
            // Shimmer only the bones; the card itself stays white.
            child: AppShimmer(
              child: Row(
              children: [
                const AppBone(width: 40, height: 40, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: i.isEven ? 0.7 : 0.55,
                        child: const AppBone(height: 13),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: i.isEven ? 0.45 : 0.6,
                        child: const AppBone(height: 10),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          AppBone(width: 64, height: 22, radius: 11),
                          SizedBox(width: 8),
                          AppBone(width: 48, height: 22, radius: 11),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Error / empty
// ─────────────────────────────────────────────────────────────────────────

/// Icon in a soft circle that bobs gently (empty) or pops in (error).
class _StateIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool float;
  const _StateIcon({required this.icon, required this.color, this.float = true});

  @override
  State<_StateIcon> createState() => _StateIconState();
}

class _StateIconState extends State<_StateIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.float && !_reduce(context) && !_c.isAnimating) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final circle = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(c, Colors.white, 0.82)!, Color.lerp(c, Colors.white, 0.94)!],
        ),
      ),
      child: Icon(widget.icon, size: 44, color: Color.lerp(c, Colors.black, 0.1)),
    );
    return AnimatedBuilder(
      animation: _c,
      child: circle,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? message;
  final Widget? action;
  final bool float;

  const _StateView({
    required this.icon,
    required this.color,
    required this.title,
    this.message,
    this.action,
    this.float = true,
  });

  @override
  Widget build(BuildContext context) {
    // Scrollable so pull-to-refresh still works on an empty / error list.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight.isFinite ? box.maxHeight : 0),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: AppEntrance(
                fromScale: 0.92,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StateIcon(icon: icon, color: color, float: float),
                    const SizedBox(height: 18),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    if (message != null && message!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, height: 1.45, color: AppColors.subtle)),
                    ],
                    if (action != null) ...[const SizedBox(height: 18), action!],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Couldn't load" with the API message and a Retry button.
class AppErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String title;

  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.title = "Couldn't load this",
  });

  @override
  Widget build(BuildContext context) {
    final text = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    final offline = RegExp(r'internet|network|connection|socket|timed? ?out', caseSensitive: false)
        .hasMatch(text);
    return _StateView(
      icon: offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      color: AppColors.danger,
      title: offline ? 'You are offline' : title,
      message: text,
      float: false,
      action: onRetry == null
          ? null
          : PressableScale(
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
              ),
            ),
    );
  }
}

/// Illustrated empty list message.
class AppEmptyView extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyView({
    super.key,
    this.title = 'Nothing here yet',
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => _StateView(
        icon: icon,
        color: AppColors.primary,
        title: title,
        message: message,
        action: actionLabel == null || onAction == null
            ? null
            : PressableScale(
                child: OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ),
      );
}
