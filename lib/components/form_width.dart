import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Widest a single-column form gets on tablets.
const double kFormMaxWidth = 640;

/// Side padding that centres a form in a [kFormMaxWidth] column on iPad.
///
/// On phones (narrower than [maxWidth] + 2 × [base]) this is just [base], so
/// phone layouts don't change. Used as scroll-view padding so the scrollbar
/// and scroll gestures still cover the full width.
double formSidePadding(
  BuildContext context,
  double base, {
  double maxWidth = kFormMaxWidth,
}) {
  final width = MediaQuery.sizeOf(context).width;
  return math.max(base, (width - maxWidth) / 2);
}
