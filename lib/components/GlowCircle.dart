import 'package:flutter/cupertino.dart';

class GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}