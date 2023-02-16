import 'package:flutter/material.dart';
import 'package:anxeb_flutter/middleware/field.dart';
import 'package:anxeb_flutter/middleware/scope.dart';

class CheckBoxField extends FieldWidget<bool> {
  final String label;
  final ListTileControlAffinity controlAffinity;

  CheckBoxField({
    @required Scope scope,
    @required String name,
    Key key,
    String group,
    EdgeInsets margin,
    EdgeInsets padding,
    ValueChanged<bool> onChanged,
    GestureTapCallback onTab,
    GestureTapCallback onFocus,
    FormFieldValidator<String> validator,
    bool focusNext,
    bool readonly,
    BorderRadius borderRadius,
    bool Function() fetcher,
    Function(bool value) applier,
    this.label,
    this.controlAffinity,
  })  : assert(name != null),
        super(
          scope: scope,
          key: key,
          name: name,
          group: group,
          margin: margin,
          padding: padding,
          readonly: readonly,
          onChanged: onChanged,
          onFocus: onFocus,
          validator: validator,
          focusNext: focusNext,
          borderRadius: borderRadius,
          fetcher: fetcher,
          applier: applier,
        );

  @override
  _CheckBoxFieldState createState() => _CheckBoxFieldState();
}

class _CheckBoxFieldState extends Field<bool, CheckBoxField> {
  @override
  Widget field() {
    var result = FormField(
      builder: (FormFieldState state) {
        return CheckboxListTile(
          contentPadding: EdgeInsets.only(left: 4, right: 0),
          visualDensity: VisualDensity.standard,
          dense: false,
          activeColor: widget.scope.application.settings.colors.primary,
          tileColor: widget.scope.application.settings.colors.primary,
          title: Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: warning != null ? widget.scope.application.settings.colors.danger : widget.scope.application.settings.colors.primary,
              letterSpacing: 0.2,
              fontSize: 15,
            ),
          ),
          subtitle: warning != null
              ? Text(
                  warning,
                  style: TextStyle(
                    color: widget.scope.application.settings.colors.danger,
                  ),
                )
              : null,
          value: value ?? false,
          onChanged: widget.readonly == true
              ? null
              : (newValue) {
                  value = newValue;
                  validate();
                  if (widget.onChanged != null) widget.onChanged(newValue);
                },
          controlAffinity: widget.controlAffinity ?? ListTileControlAffinity.leading,
        );
      },
    );

    return result;
  }
}
