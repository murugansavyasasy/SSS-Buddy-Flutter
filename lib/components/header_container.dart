import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../values/colors/app_colors.dart';
class HeaderContainer extends StatelessWidget {
  final Widget child;

  const HeaderContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).viewPadding.top + 60,
        24,
        40,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: child,
    );
  }
}