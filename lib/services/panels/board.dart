import 'package:anxeb_flutter/middleware/panel.dart';
import 'package:anxeb_flutter/middleware/scope.dart';
import 'package:flutter/material.dart';

class BoardPanel extends ViewPanel {
  Widget _child;

  BoardPanel({Scope scope, Widget child, double height}) : super(scope: scope, height: height ?? 400) {
    _child = child;
  }

  @override
  Widget content([Widget child]) {
    return super.content(Container(
      height: height - 70,
      width: scope.window.available.width,
      margin: EdgeInsets.symmetric(horizontal: margins),
      padding: EdgeInsets.all(paddings),
      decoration: BoxDecoration(
        boxShadow: [shadow],
        shape: BoxShape.rectangle,
        borderRadius: radius != null ? BorderRadius.only(topLeft: Radius.circular(radius), topRight: Radius.circular(radius)) : null,
        color: fill,
      ),
      child: _child ?? child,
    ));
  }

  @protected
  BoxShadow get shadow => BoxShadow(offset: Offset(0, 6), blurRadius: 5, spreadRadius: 3, color: Color(0x3f555555));

  @protected
  double get radius => 10;

  @protected
  Color get fill => Colors.white;

  @protected
  double get paddings => 12;

  @protected
  double get margins => 12;
}
