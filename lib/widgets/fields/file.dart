import 'dart:io';
import 'package:anxeb_flutter/helpers/camera.dart';
import 'package:anxeb_flutter/helpers/document.dart';
import 'package:anxeb_flutter/middleware/field.dart';
import 'package:anxeb_flutter/middleware/scope.dart';
import 'package:anxeb_flutter/misc/icons.dart';
import 'package:anxeb_flutter/parts/panels/menu.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:path/path.dart';
import 'package:photo_view/photo_view.dart';

class FileInputValue {
  FileInputValue({this.url, this.path, this.title, this.extension, this.useFullUrl=false});

  String url;
  String path;
  String title;
  String extension;
  bool useFullUrl;

  bool get isImage => ['jpg', 'png', 'jpeg'].contains(extension);

  String get previewText => title ?? basename(path);

  Map<String, dynamic> toJSON(){
    return {
      'title': title,
      'extension': extension
    };
  }
}

class FileInputField extends FieldWidget<List<FileInputValue>> {
  final bool allowMultiples;
  final List<String> allowedExtensions;
  final String launchUrlPrefix;

  FileInputField({
    @required Scope scope,
    Key key,
    @required String name,
    String group,
    String label,
    IconData icon,
    EdgeInsets margin,
    EdgeInsets padding,
    bool readonly,
    bool visible,
    ValueChanged<List<FileInputValue>> onSubmitted,
    ValueChanged<List<FileInputValue>> onValidSubmit,
    GestureTapCallback onTab,
    GestureTapCallback onBlur,
    GestureTapCallback onFocus,
    ValueChanged<List<FileInputValue>> onChanged,
    FormFieldValidator<String> validator,
    List<FileInputValue> Function(dynamic value) parser,
    bool focusNext,
    double fontSize,
    double labelSize,
    this.allowMultiples = false,
    this.allowedExtensions,
    this.launchUrlPrefix,
  })  : assert(name != null),
        super(
          scope: scope,
          key: key,
          name: name,
          group: group,
          label: label,
          icon: icon,
          margin: margin,
          padding: padding,
          readonly: readonly,
          visible: visible,
          onSubmitted: onSubmitted,
          onValidSubmit: onValidSubmit,
          onTab: onTab,
          onBlur: onBlur,
          onFocus: onFocus,
          onChanged: onChanged,
          validator: validator,
          parser: parser,
          focusNext: focusNext,
          fontSize: fontSize,
          labelSize: labelSize,
        );

  @override
  _FileInputFieldState createState() => _FileInputFieldState();
}

class _FileInputFieldState extends Field<List<FileInputValue>, FileInputField> {
  final GlobalIcons icons = GlobalIcons();
  List<FileInputValue> _files;

  @override
  void init() {}

  @override
  void setup() {}

  void _pickFile() async {
    var option;
    await widget.scope.dialogs.panel(
      items: [
        PanelMenuItem(
          actions: [
            PanelMenuAction(
              label: () => 'Buscar\nDocumento',
              textScale: 0.9,
              icon: () => FlutterIcons.file_mco,
              fillColor: () => widget.scope.application.settings.colors.secudary,
              onPressed: () {
                option = 'document';
              },
            ),
            PanelMenuAction(
              label: () => 'Tomar\nFoto',
              textScale: 0.9,
              icon: () => FlutterIcons.md_camera_ion,
              fillColor: () => widget.scope.application.settings.colors.secudary,
              onPressed: () {
                option = 'photo';
              },
            ),
          ],
          height: () => 120,
        ),
      ],
    ).show();

    List<File> result = [];

    if (option == 'photo') {
      final picture = await widget.scope.view.push(CameraHelper(
        title: widget.label,
        fullImage: true,
        initFaceCamera: false,
        allowMainCamera: true,
        fileName: widget.label.toLowerCase().replaceAll(' ', '_'),
        flash: true,
        resolution: ResolutionPreset.high,
      ));
      result.add(picture);
    } else if (option == 'document') {
      try {
        final picker = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: widget.allowMultiples,
          allowedExtensions: widget.allowedExtensions ?? ['jpeg', 'jpg', 'png', 'pdf'],
          onFileLoading: (state) async {
            await widget.scope.busy();
          },
        );

        await Future.delayed(Duration(milliseconds: 350));
        await widget.scope.idle();

        if (picker != null && picker.files.first != null) {
          result = picker.files.map((file) => File(file.path)).toList();
        }
      } catch (err) {
        await widget.scope.idle();
        widget.scope.alerts.asterisk('Debe permitir el acceso al sistema de archivos').show();
      }
    }

    if (result != null && result.isNotEmpty) {
      super.submit(result.map((file) => FileInputValue(
        path: file.path,
        title: basename(file.path),
        extension: (extension(file.path ?? '') ?? '').replaceFirst('.', ''),
        url: null,
      )).toList());
    }
  }

  @override
  void prebuild() {}

  @override
  void onBlur() {
    super.onBlur();
  }

  @override
  void onFocus() {
    super.onFocus();
  }

  @override
  dynamic data() {
    return super.data();
  }

  @override
  void present() {
    setState(() {
      if (value != null) {
        _files = value;
      } else {
        _files = null;
      }
    });
  }

  @override
  Widget field() {
    var previewContent;

    if (value != null && value.isNotEmpty) {
      previewContent = Column(children: value.map((file) => GestureDetector(
        onTap: () async {
          _preview(file);
        },
        child: Container(
          padding: EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 2),
                child: _getMimeIcon(file),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    file.previewText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      height: 1,
                      fontSize: 16,
                      color: widget.scope.application.settings.colors.primary,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      )).toList());
    } else {
      previewContent = Container(
        padding: EdgeInsets.only(top: 2),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: widget.fontSize != null ? (widget.fontSize * 0.9) : 16,
            color: Color(0x88000000),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (widget.readonly == true) {
          return;
        }
        focus();
        if (value == null) {
          _pickFile();
        }
      },
      child:  FormField(
        builder: (FormFieldState state) {
          return InputDecorator(
            isFocused: focused,
            decoration: InputDecoration(
              filled: true,
              contentPadding: EdgeInsets.only(left: 0, top: 7, bottom: 0, right: 0),
              prefixIcon: Icon(
                widget.icon ?? FontAwesome5.dot_circle,
                size: widget.iconSize,
                color: widget.scope.application.settings.colors.primary,
              ),
              labelText: (value != null && value.isNotEmpty) ? widget.label : null,
              labelStyle: widget.labelSize != null ? TextStyle(fontSize: widget.labelSize) : null,
              fillColor: focused ? widget.scope.application.settings.colors.focus : widget.scope.application.settings.colors.input,
              errorText: warning,
              border: UnderlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8))),
              suffixIcon: GestureDetector(
                dragStartBehavior: DragStartBehavior.down,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (widget.readonly == true) {
                    return;
                  }
                  if (value != null) {
                    clear();
                  } else {
                    _pickFile();
                  }
                },
                child: _getIcon(),
              ),
            ),
            child: Padding(
              padding: value == null ? EdgeInsets.only(top: 5) : EdgeInsets.zero,
              child: previewContent,
            ),
          );
        },
      ),
    );
  }

  Future _preview(FileInputValue value) async {
    if (value != null) {
      var result = await widget.scope.view.push(DocumentView(
        launchUrl: widget.launchUrlPrefix,
        file: value,
        initialScale: PhotoViewComputedScale.contained,
        readonly: widget.readonly,
      ));
      present();
      if (result == false) {
        clear();
      }
    }
  }

  Icon _getMimeIcon(FileInputValue value) {
    var ext = value?.extension ?? (value?.path != null ? extension(value.path).replaceFirst('.', '') : null) ?? 'txt';
    var meta = icons.getFileMeta(ext);

    return Icon(
      meta?.icon ?? Icons.insert_drive_file,
      color: meta?.color ?? Color(0x88000000),
      size: 12,
    );
  }

  Icon _getIcon() {
    if (widget.readonly == true) {
      return Icon(Icons.lock_outline);
    }

    if (value != null) {
      return Icon(Icons.clear, color: widget.scope.application.settings.colors.primary);
    } else {
      return Icon(Icons.search, color: warning != null ? widget.scope.application.settings.colors.danger : widget.scope.application.settings.colors.primary);
    }
  }
}
