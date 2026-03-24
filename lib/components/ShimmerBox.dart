import 'package:flutter/cupertino.dart';

import 'ShimmerBoxState.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  const ShimmerBox({required this.width, required this.height});

  @override
  State<ShimmerBox> createState() => ShimmerBoxState();
}