import 'package:flutter/material.dart';

/// Labelled "Full view" / "Split view" pill for blue page headers on iPad.
class SplitViewToggle extends StatelessWidget {
  /// True while the split (two-pane) layout is showing.
  final bool split;
  final VoidCallback onTap;

  const SplitViewToggle({super.key, required this.split, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = split ? 'Full view' : 'Split view';
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  split
                      ? Icons.fullscreen_rounded
                      : Icons.vertical_split_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
