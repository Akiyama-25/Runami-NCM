import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Width-adaptive row container ported 1:1 from NCM-Converter-For-Android's AdaptiveControlsRow:
/// - Measures each child's natural single-line intrinsic width.
/// - If all children fit on one row within the available width, allocates each child its
///   intrinsic width plus a proportional share of remaining space so no control ever wraps or clips.
/// - If combined intrinsic widths exceed available width, wraps controls into multiple rows
///   and expands items on each row to fill 100% of the available width.
class AdaptiveControlsRow extends MultiChildRenderObjectWidget {
  final double horizontalSpacing;
  final double verticalSpacing;
  final bool equalMinWeight;

  const AdaptiveControlsRow({
    super.key,
    this.horizontalSpacing = 8.0,
    this.verticalSpacing = 8.0,
    this.equalMinWeight = false,
    required super.children,
  });

  @override
  RenderAdaptiveControlsRow createRenderObject(BuildContext context) {
    return RenderAdaptiveControlsRow(
      horizontalSpacing: horizontalSpacing,
      verticalSpacing: verticalSpacing,
      equalMinWeight: equalMinWeight,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAdaptiveControlsRow renderObject,
  ) {
    renderObject
      ..horizontalSpacing = horizontalSpacing
      ..verticalSpacing = verticalSpacing
      ..equalMinWeight = equalMinWeight;
  }
}

class _AdaptiveControlsParentData extends ContainerBoxParentData<RenderBox> {}

class RenderAdaptiveControlsRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AdaptiveControlsParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AdaptiveControlsParentData> {
  double _horizontalSpacing;
  double _verticalSpacing;
  bool _equalMinWeight;

  RenderAdaptiveControlsRow({
    required double horizontalSpacing,
    required double verticalSpacing,
    required bool equalMinWeight,
  })  : _horizontalSpacing = horizontalSpacing,
        _verticalSpacing = verticalSpacing,
        _equalMinWeight = equalMinWeight;

  double get horizontalSpacing => _horizontalSpacing;
  set horizontalSpacing(double value) {
    if (_horizontalSpacing != value) {
      _horizontalSpacing = value;
      markNeedsLayout();
    }
  }

  double get verticalSpacing => _verticalSpacing;
  set verticalSpacing(double value) {
    if (_verticalSpacing != value) {
      _verticalSpacing = value;
      markNeedsLayout();
    }
  }

  bool get equalMinWeight => _equalMinWeight;
  set equalMinWeight(bool value) {
    if (_equalMinWeight != value) {
      _equalMinWeight = value;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _AdaptiveControlsParentData) {
      child.parentData = _AdaptiveControlsParentData();
    }
  }

  List<RenderBox> _collectChildren() {
    final result = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      result.add(child);
      child = childAfter(child);
    }
    return result;
  }

  @override
  void performLayout() {
    final children = _collectChildren();
    if (children.isEmpty) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final maxWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : children.fold<double>(
              0.0,
              (sum, c) => sum + c.getMaxIntrinsicWidth(double.infinity),
            ) +
            _horizontalSpacing * (children.length - 1);

    final intrinsicWidths = children
        .map((c) => math.max(1.0, c.getMaxIntrinsicWidth(double.infinity)))
        .toList();

    final totalGap = _horizontalSpacing * (children.length - 1);
    final totalIntrinsic = intrinsicWidths.fold<double>(0.0, (a, b) => a + b) + totalGap;

    if (totalIntrinsic <= maxWidth + 0.5) {
      // Single row: allocate intrinsic width + proportional extra width
      final extraWidth = math.max(0.0, maxWidth - totalIntrinsic);
      final sumIntrinsic = math.max(1.0, intrinsicWidths.fold<double>(0.0, (a, b) => a + b));
      double allocatedSum = 0.0;
      final widths = List<double>.filled(children.length, 0.0);

      for (int i = 0; i < children.length; i++) {
        if (i == children.length - 1) {
          widths[i] = math.max(1.0, maxWidth - totalGap - allocatedSum);
        } else {
          final share = _equalMinWeight
              ? extraWidth / children.length
              : extraWidth * (intrinsicWidths[i] / sumIntrinsic);
          final w = intrinsicWidths[i] + share;
          widths[i] = w;
          allocatedSum += w;
        }
      }

      // First pass: measure natural height at allocated width
      double targetHeight = 0.0;
      for (int i = 0; i < children.length; i++) {
        final h = children[i].getMaxIntrinsicHeight(widths[i]);
        if (h > targetHeight) targetHeight = h;
      }

      double finalHeight = targetHeight;
      for (int i = 0; i < children.length; i++) {
        children[i].layout(
          BoxConstraints(
            minWidth: widths[i],
            maxWidth: widths[i],
            minHeight: targetHeight,
            maxHeight: constraints.maxHeight,
          ),
          parentUsesSize: true,
        );
        if (children[i].size.height > finalHeight) {
          finalHeight = children[i].size.height;
        }
      }

      // If any child ended up taller than prelim targetHeight, re-layout shorter ones to match
      for (int i = 0; i < children.length; i++) {
        if ((children[i].size.height - finalHeight).abs() > 0.5) {
          children[i].layout(
            BoxConstraints(
              minWidth: widths[i],
              maxWidth: widths[i],
              minHeight: finalHeight,
              maxHeight: finalHeight,
            ),
            parentUsesSize: true,
          );
        }
      }

      double x = 0.0;
      for (int i = 0; i < children.length; i++) {
        final pd = children[i].parentData! as _AdaptiveControlsParentData;
        pd.offset = Offset(x, (finalHeight - children[i].size.height) / 2.0);
        x += children[i].size.width + _horizontalSpacing;
      }

      size = constraints.constrain(Size(maxWidth, finalHeight));
    } else {
      // Multi-row wrap: pack greedily, then expand each row to fill 100% width
      final rows = <List<int>>[];
      var currentRow = <int>[];
      double currentRowWidth = 0.0;

      for (int i = 0; i < children.length; i++) {
        final w = intrinsicWidths[i];
        final needed = currentRow.isEmpty ? w : currentRowWidth + _horizontalSpacing + w;
        if (currentRow.isNotEmpty && needed > maxWidth) {
          rows.add(currentRow);
          currentRow = [i];
          currentRowWidth = w;
        } else {
          currentRow.add(i);
          currentRowWidth = needed;
        }
      }
      if (currentRow.isNotEmpty) {
        rows.add(currentRow);
      }

      final rowHeights = <double>[];
      for (final rowIndices in rows) {
        final rowGap = _horizontalSpacing * (rowIndices.length - 1);
        final rowIntrinsicSum = rowIndices.fold<double>(0.0, (s, idx) => s + intrinsicWidths[idx]);
        final extra = math.max(0.0, maxWidth - rowGap - rowIntrinsicSum);
        final sumF = math.max(1.0, rowIntrinsicSum);
        double used = 0.0;
        final widths = List<double>.filled(rowIndices.length, 0.0);

        for (int pos = 0; pos < rowIndices.length; pos++) {
          final idx = rowIndices[pos];
          if (pos == rowIndices.length - 1) {
            widths[pos] = math.max(1.0, maxWidth - rowGap - used);
          } else {
            final remaining = math.max(1.0, maxWidth - rowGap - used);
            final w = math.min(
              remaining,
              intrinsicWidths[idx] + extra * (intrinsicWidths[idx] / sumF),
            );
            widths[pos] = math.max(1.0, w);
            used += widths[pos];
          }
        }

        double rowTargetH = 0.0;
        for (int pos = 0; pos < rowIndices.length; pos++) {
          final h = children[rowIndices[pos]].getMaxIntrinsicHeight(widths[pos]);
          if (h > rowTargetH) rowTargetH = h;
        }

        double actualRowH = rowTargetH;
        for (int pos = 0; pos < rowIndices.length; pos++) {
          final child = children[rowIndices[pos]];
          child.layout(
            BoxConstraints(
              minWidth: widths[pos],
              maxWidth: widths[pos],
              minHeight: rowTargetH,
              maxHeight: double.infinity,
            ),
            parentUsesSize: true,
          );
          if (child.size.height > actualRowH) actualRowH = child.size.height;
        }

        for (int pos = 0; pos < rowIndices.length; pos++) {
          final child = children[rowIndices[pos]];
          if ((child.size.height - actualRowH).abs() > 0.5) {
            child.layout(
              BoxConstraints(
                minWidth: widths[pos],
                maxWidth: widths[pos],
                minHeight: actualRowH,
                maxHeight: actualRowH,
              ),
              parentUsesSize: true,
            );
          }
        }

        rowHeights.add(actualRowH);
      }

      double y = 0.0;
      for (int r = 0; r < rows.length; r++) {
        final rowIndices = rows[r];
        final rH = rowHeights[r];
        double x = 0.0;
        for (final idx in rowIndices) {
          final child = children[idx];
          final pd = child.parentData! as _AdaptiveControlsParentData;
          pd.offset = Offset(x, y + (rH - child.size.height) / 2.0);
          x += child.size.width + _horizontalSpacing;
        }
        y += rH + (r < rows.length - 1 ? _verticalSpacing : 0.0);
      }

      size = constraints.constrain(Size(maxWidth, y));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
