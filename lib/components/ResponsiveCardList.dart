import 'package:flutter/material.dart';

/// Number of card columns for the available [width].
///
/// Phones (< 600 dp) keep a single column. Tablets / iPad get as many
/// columns as fit at [minItemWidth] each, up to [maxColumns].
int responsiveColumns(
  double width, {
  double minItemWidth = 340,
  int maxColumns = 3,
}) {
  if (width < 600) return 1;
  return (width / minItemWidth).floor().clamp(2, maxColumns);
}

/// A vertical, lazily built list of cards that turns into a multi-column
/// card grid on wide screens (iPad / tablets).
///
/// On phones it behaves exactly like `ListView.separated`. On wider screens
/// items are laid out in rows of N cards; each card keeps its natural height,
/// so cards of any size work without overflow.
class ResponsiveCardList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;

  /// Gap between cards (vertical on phone; both directions on tablet).
  final double spacing;

  /// Extra gap between columns on tablet. Defaults to 16.
  final double columnSpacing;

  final double minItemWidth;
  final int maxColumns;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  /// Optional full-width widget shown after the items (e.g. "load more").
  final Widget? footer;

  const ResponsiveCardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 12,
    this.columnSpacing = 16,
    this.minItemWidth = 340,
    this.maxColumns = 3,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - padding.horizontal;
        final columns = responsiveColumns(
          width,
          minItemWidth: minItemWidth,
          maxColumns: maxColumns,
        );
        final hasFooter = footer != null;

        if (columns == 1) {
          return ListView.separated(
            controller: controller,
            physics: physics,
            shrinkWrap: shrinkWrap,
            padding: padding,
            itemCount: itemCount + (hasFooter ? 1 : 0),
            separatorBuilder: (_, __) => SizedBox(height: spacing),
            itemBuilder: (context, index) =>
                index >= itemCount ? footer! : itemBuilder(context, index),
          );
        }

        final rowCount = (itemCount / columns).ceil();
        return ListView.separated(
          controller: controller,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          itemCount: rowCount + (hasFooter ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: spacing),
          itemBuilder: (context, row) {
            if (row >= rowCount) return footer!;
            final children = <Widget>[];
            for (var c = 0; c < columns; c++) {
              if (c > 0) children.add(SizedBox(width: columnSpacing));
              final index = row * columns + c;
              children.add(
                Expanded(
                  child: index < itemCount
                      ? itemBuilder(context, index)
                      : const SizedBox.shrink(),
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          },
        );
      },
    );
  }
}

/// Lays out [children] as a card grid on wide screens and a plain column on
/// phones. For non-scrolling sections inside another scroll view.
class ResponsiveCardWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double columnSpacing;
  final double minItemWidth;
  final int maxColumns;

  const ResponsiveCardWrap({
    super.key,
    required this.children,
    this.spacing = 0,
    this.columnSpacing = 16,
    this.minItemWidth = 340,
    this.maxColumns = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final columns = responsiveColumns(
          maxW,
          minItemWidth: minItemWidth,
          maxColumns: maxColumns,
        );
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0 && spacing > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        final itemWidth = ((maxW - columnSpacing * (columns - 1)) / columns)
            .floorToDouble();
        return Wrap(
          spacing: columnSpacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
