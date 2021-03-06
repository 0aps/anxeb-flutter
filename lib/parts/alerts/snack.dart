import 'package:anxeb_flutter/middleware/alert.dart';
import 'package:anxeb_flutter/middleware/scope.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart' hide Dialog;

class SnackAlert extends ScopeAlert {
  Flushbar _bar;
  final String title;
  final String message;
  final TextStyle titleStyle;
  final TextStyle messageStyle;
  final IconData icon;
  final Color textColor;
  final Color iconColor;
  final Color fillColor;
  final int delay;

  SnackAlert(
    Scope scope, {
    this.title,
    this.message,
    this.titleStyle,
    this.messageStyle,
    this.icon,
    this.textColor,
    this.iconColor,
    this.fillColor,
    this.delay,
  }) : super(scope);

  @override
  Future dispose({bool quick}) async {
    if (_bar != null) {
      if (quick == true) {
        if (_bar.isShowing()) {
          _bar.dismiss();
        }
      } else {
        if (_bar.isShowing()) {
          await _bar.dismiss();
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    }
    await super.dispose(quick: quick);
    _bar = null;
  }

  @override
  Future build() async {
    var $message = message != null ? Text(message, style: messageStyle ?? TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: textColor ?? Colors.white)) : null;
    var $title = title != null ? Text(title, style: titleStyle ?? TextStyle(fontSize: $message == null ? 17 : 19, fontWeight: FontWeight.w400, color: textColor ?? Colors.white)) : null;
    var $fill = fillColor ?? scope.application.settings.colors.navigation;

    _bar = Flushbar(
      titleText: $message != null ? $title : null,
      messageText: $message ?? $title,
      backgroundGradient: LinearGradient(
        begin: FractionalOffset.topCenter,
        end: FractionalOffset.bottomCenter,
        colors: [
          $fill,
          Color.alphaBlend(Colors.black.withOpacity(0.15), $fill),
        ],
        stops: [0.0, 1.0],
      ),
      isDismissible: true,
      margin: scope.window.overlay.extendBodyFullScreen ? EdgeInsets.only(left: 22, right: 22, bottom: 56) : EdgeInsets.all(8),
      borderRadius: 8,
      boxShadows: [BoxShadow(offset: Offset(0, 2), blurRadius: 6, spreadRadius: 2, color: Color(0x55222222))],
      flushbarPosition: scope.window.overlay.extendBodyFullScreen ? FlushbarPosition.BOTTOM : FlushbarPosition.TOP,
      icon: Icon(
        icon,
        size: $message == null ? 26 : 30.0,
        color: iconColor ?? Colors.white,
      ),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 500),
      duration: Duration(milliseconds: delay ?? 3000),
    );

    await _bar.show(scope.context);
    _bar = null;
    await Future.delayed(Duration(milliseconds: 500));
  }
}
