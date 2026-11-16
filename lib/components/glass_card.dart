import 'package:flutter/material.dart';

/// Home screen palette (light page, pastel stat cards, white cards).
class HomeGlass {
  /// Page background: plain off-white, no gradient.
  static const Color bg = Color(0xFFF5F6FA);
  static const Color ink = Color(0xFF111827);
  static const Color blue = Color(0xFF2563EB);
  static const Color green = Color(0xFF16A34A);
  static const Color orange = Color(0xFFEA580C);
  static const Color navy = Color(0xFF1A2C4E);
  /// Text / borders on the light page (cards keep white text).
  static const Color muted = Color(0xFF6B7280);
  static const Color line = Color(0xFFE3E7EF);
}

/// Light pastel of [c] for card backgrounds (e.g. mint for green).
Color homePastel(Color c) => Color.lerp(c, Colors.white, 0.88)!;

/// Light diagonal gradient of [c]: soft pastel top-left fading to near-white.
LinearGradient homePastelGradient(Color c) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(c, Colors.white, 0.78)!,
        Color.lerp(c, Colors.white, 0.95)!,
      ],
    );

/// Deep shade of [c] for numbers / icons on a pastel card.
Color homeDeep(Color c) => Color.lerp(c, Colors.black, 0.25)!;

/// Rounded card with soft shadow for the home screen. White by default;
/// pass [color] for a pastel card.
class SoftCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// Optional background gradient; overrides [color] when set.
  final Gradient? gradient;

  const SoftCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.gradient,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: gradient,
        boxShadow: const [
          BoxShadow(color: Color(0x0D111827), blurRadius: 18, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x08111827), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Material(
        color: gradient == null ? color : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: BorderSide(color: borderColor ?? HomeGlass.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Dark glass card: vivid [tint] at the edges fading to a near-black centre,
/// a faint top highlight and a hairline border (as on modern wallet UIs).
class GlassCard extends StatelessWidget {
  final Color tint;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool glow;

  const GlassCard({
    super.key,
    required this.tint,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.onTap,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: tint.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            // Tint base.
            Positioned.fill(
              child: ColoredBox(color: Color.lerp(tint, Colors.black, 0.15)!),
            ),
            // Dark vignette in the middle, colour stays at the edges.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 0.95,
                    colors: [Color(0xF2000000), Color(0x99000000), Color(0x00000000)],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // Soft top highlight.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Colors.white.withValues(alpha: 0.10), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Hairline border.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: r,
                splashColor: Colors.white.withValues(alpha: 0.08),
                highlightColor: Colors.white.withValues(alpha: 0.04),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small frosted pill / round button used on dark glass surfaces.
class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  /// White pill with a hairline border, for use on the light page.
  final bool light;

  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.onTap,
    this.radius = 30,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: light ? Colors.white : Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
              color: light ? HomeGlass.line : Colors.white.withValues(alpha: 0.18)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          child: Padding(padding: padding, child: child),
        ),
      );
}
