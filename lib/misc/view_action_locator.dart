import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const double kFloatingActionButtonMargin = 16.0;

double _leftOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, {double offset = 0.0}) {
  return kFloatingActionButtonMargin + scaffoldGeometry.minInsets.left - offset;
}

double _rightOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, {double offset = 0.0}) {
  return scaffoldGeometry.scaffoldSize.width - kFloatingActionButtonMargin - scaffoldGeometry.minInsets.right - scaffoldGeometry.floatingActionButtonSize.width + offset;
}

double _endOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, {double offset = 0.0}) {
  assert(scaffoldGeometry.textDirection != null);
  switch (scaffoldGeometry.textDirection) {
    case TextDirection.rtl:
      return _leftOffset(scaffoldGeometry, offset: offset);
    case TextDirection.ltr:
      return _rightOffset(scaffoldGeometry, offset: offset);
  }
  return null;
}

class ViewActionLocator extends FloatingActionButtonLocation {
  @protected
  double getDockedY(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double bottomSheetHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double contentBottom = scaffoldGeometry.scaffoldSize.height - (fabHeight / 2) - 19;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;

    double fabY = contentBottom - fabHeight / 2.0;
    if (snackBarHeight > 0.0) {
      fabY = math.min(fabY, contentBottom - snackBarHeight - (fabHeight/2));
    }
    if (bottomSheetHeight > 0.0) fabY = math.min(fabY, contentBottom - bottomSheetHeight - fabHeight / 2.0);

    final double maxFabY = scaffoldGeometry.scaffoldSize.height - fabHeight;
    return math.min(maxFabY, fabY);
  }

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = _endOffset(scaffoldGeometry);
    return Offset(fabX, getDockedY(scaffoldGeometry));
  }
}
