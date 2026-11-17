import 'package:flutter/widgets.dart';

/// Screen width (dp) the app's font sizes were designed for (a regular
/// iPhone / Android phone). Narrower phones get proportionally smaller text.
const double kDesignPhoneWidth = 392;

/// Smallest width-based factor, so text never gets unreadably small.
const double kMinDeviceTextFactor = 0.8;

/// Cap on the user's system font-size setting. Larger values break the
/// fixed-height cards and rows on small Android phones.
const double kMaxUserTextScale = 1.15;

/// Text factor for a screen: 1.0 on tablets and phones at least
/// [kDesignPhoneWidth] wide, smaller on narrower phones.
double deviceTextFactor(Size size) {
  if (size.shortestSide >= 600) return 1.0;
  return (size.width / kDesignPhoneWidth).clamp(kMinDeviceTextFactor, 1.0);
}

/// Scales all text in [child] to the device width (see [deviceTextFactor])
/// and caps the user's system font scale at [kMaxUserTextScale].
class DeviceTextScale extends StatelessWidget {
  final Widget child;

  const DeviceTextScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final user = mq.textScaler.clamp(maxScaleFactor: kMaxUserTextScale);
    final factor = deviceTextFactor(mq.size);
    return MediaQuery(
      data: mq.copyWith(textScaler: _FactorTextScaler(user, factor)),
      child: child,
    );
  }
}

class _FactorTextScaler extends TextScaler {
  final TextScaler base;
  final double factor;

  const _FactorTextScaler(this.base, this.factor);

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _FactorTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
