import 'dart:async';
import 'dart:io';
import 'package:anxeb_flutter/middleware/application.dart';
import 'package:anxeb_flutter/middleware/view.dart';
import 'package:anxeb_flutter/misc/action_menu.dart';
import 'package:anxeb_flutter/parts/headers/actions.dart';
import 'package:anxeb_flutter/widgets/blocks/empty.dart';
import 'package:anxeb_flutter/widgets/components/dialog_progress.dart';
import 'package:anxeb_flutter/widgets/fields/file.dart';
import 'package:anxeb_flutter/widgets/fields/text.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as Path;
import 'package:photo_view/photo_view.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart' as Launcher;

class DocumentView extends ViewWidget {
  final FileInputValue file;
  final String launchUrl;
  final bool readonly;
  final String tag;

  DocumentView({
    @required this.file,
    this.launchUrl,
    this.readonly = true,
    this.tag,
  })  : assert(file != null),
        super('anxeb_document_helper', title: file?.title ?? 'Vista Archivo');

  @override
  _DocumentState createState() => new _DocumentState();
}

class _DocumentState extends View<DocumentView, Application> {
  PhotoViewControllerBase _controller;
  File _data;
  bool _refreshing;
  PDFView _pdfFileAlt;
  Completer<PDFViewController> _controllerAlt;
  int _pages = 1;
  int _currentPage = 1;

  @override
  Future init() async {
    _controller = PhotoViewController();
    _controllerAlt = Completer<PDFViewController>();
    _refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void setup() {}

  @override
  void prebuild() {}

  @override
  ActionsHeader header() {
    return ActionsHeader(
      scope: scope,
      actions: <ActionMenu>[
        ActionMenu(
          actions: [
            ActionMenuItem(
              caption: () => 'Recargar Archivo',
              icon: () => Icons.refresh,
              onPressed: () => _refresh(),
            ),
            ActionMenuItem(
              caption: () => 'Cambiar Título',
              icon: () => Icons.text_fields,
              onPressed: () => _changeTitle(),
              isVisible: () => widget.readonly != true,
            ),
            ActionMenuItem(
              caption: () => 'Abrir en Navegador',
              icon: () => Icons.launch,
              isVisible: () => widget.launchUrl != null && widget.file?.url != null,
              onPressed: () => _launch(),
            ),
            ActionMenuItem(
              caption: () => 'Compartir o Enviar',
              icon: () => Icons.share,
              isVisible: () => widget.file?.url != null,
              onPressed: () => _share(),
            ),
            ActionMenuItem(
              caption: () => 'Descargar en Navegador',
              icon: () => Icons.file_download,
              isVisible: () => widget.launchUrl != null && widget.file?.url != null,
              onPressed: () => _download(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget content() {
    if (_refreshing == true && _data == null) {
      return _getLoading();
    } else if (_refreshing != true && _data == null) {
      return EmptyBlock(
        scope: scope,
        message: 'Error cargando archivo',
        icon: Icons.cloud_off,
        actionText: 'Refrescar',
        actionCallback: () async => _refresh(),
      );
    }

    if (_isImage) {
      return Stack(
        children: [
          PhotoView(
            imageProvider: FileImage(_data),
            gaplessPlayback: true,
            backgroundDecoration: BoxDecoration(
                gradient: LinearGradient(
              begin: FractionalOffset.topCenter,
              end: FractionalOffset.bottomCenter,
              colors: [
                Color(0xfff0f0f0),
                Color(0xffc3c3c3),
              ],
              stops: [0.0, 1.0],
            )),
            controller: _controller,
            initialScale: PhotoViewComputedScale.covered,
            loadFailedChild: Center(
              child: Icon(
                Icons.broken_image,
                size: 140,
                color: application.settings.colors.primary.withOpacity(0.2),
              ),
            ),
            loadingBuilder: (context, event) {
              return _getLoading();
            },
          ),
          _getTag(),
        ],
      );
    } else if (_pdfFileAlt != null) {
      return Stack(
        children: [
          Container(
            child: _pdfFileAlt,
          ),
          Container(
            alignment: Alignment.topRight,
            padding: EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                '$_currentPage / $_pages',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),
              ),
            ),
          ),
          _getTag(),
        ],
      );
    } else {
      return EmptyBlock(
        scope: scope,
        message: 'Archivo no puede ser visualizado',
        icon: Icons.insert_drive_file_sharp,
        actionText: 'Refrescar',
        actionCallback: () async => _refresh(),
      );
    }
  }

  Widget _getTag() {
    if (widget.tag == null) {
      return Container();
    }
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(scope.application.settings.dialogs.dialogRadius ?? 20),
        ),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        margin: EdgeInsets.only(bottom: 10),
        child: Text(
          widget.tag,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 22),
        ),
      ),
    );
  }

  Widget _getLoading() {
    var length = window.horizontal(0.16);
    return Center(
      child: SizedBox(
        child: CircularProgressIndicator(
          strokeWidth: 5,
          valueColor: AlwaysStoppedAnimation<Color>(scope.application.settings.colors.primary),
        ),
        height: length,
        width: length,
      ),
    );
  }

  void _share() {
    var $title = widget.file.title;
    var $msg = '${$title}\n\nCompartido desde la plataforma GestorHub - www.gestorhub.es';
    var $mime = _isPdf ? 'application/pdf' : 'image/${widget.file.extension}';
    var $extension = _isPdf ? '.pdf' : '.${widget.file.extension}';
    var haveExt = Path.extension(_data.path)?.isNotEmpty == true;
    String newFileName = Path.join(Path.dirname(_data.path), $title + (haveExt ? '' : $extension));
    _data.copy(newFileName);

    final RenderBox box = scope.context.findRenderObject();
    if (_data != null) {
      Share.shareFiles([newFileName], mimeTypes: [$mime], text: $msg, subject: $title, sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    } else {
      _fetchFileData((data) {
        Share.shareFiles([newFileName], mimeTypes: [$mime], text: $msg, subject: $title, sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
      });
    }
  }

  void _launch({bool download}) async {
    var option = download == true ? 'download' : 'open';
    var url = '${widget.launchUrl}${widget.file.url}/$option';

    if (await Launcher.canLaunch(url)) {
      await Launcher.launch(
        url,
        enableDomStorage: false,
        forceSafariVC: false,
        forceWebView: false,
      );
    } else {
      scope.alerts.error('Error abriendo archivo').show();
    }
  }

  void _download() {
    _launch(download: true);
  }

  Future<File> _fetchFileData([Function(File data) callback]) async {
    try {
      var data = await _fetch(silent: true);
      if (data != null && callback != null) {
        callback(data);
      }
      return data;
    } catch (err) {
      scope.alerts.error(err).show();
    }
    return null;
  }

  Future<File> _fetch({bool silent}) async {
    var controller = DialogProcessController();
    scope.dialogs
        .progress(
          'Descargando Archivo',
          icon: Icons.file_download,
          controller: controller,
          isDownload: true,
        )
        .show();
    var cacheDirectory = await getTemporaryDirectory();

    var cancelToken = CancelToken();
    controller.onCanceled(() {
      cancelToken.cancel();
    });

    var $name = widget.title;
    var $filePath = '${cacheDirectory.path}/${$name}';
    var $url = '${widget.file.url}/open';

    try {
      await scope.api.download(
        $url,
        location: $filePath,
        progress: (count, total) {
          controller.update(total: total.toDouble(), value: count.toDouble());
        },
        cancelToken: cancelToken,
      );
      if (silent == true) {
        controller.success(silent: true);
      } else {
        await controller.success();
      }
      return File($filePath);
    } catch (err) {
      controller.failed(message: err.toString());
      scope.alerts.error(err).show();
    }
    return null;
  }

  Future _changeTitle() async {
    var title = await scope.dialogs
        .prompt(
          'Título Nuevo',
          hint: 'Título',
          type: TextInputFieldType.text,
          value: widget.file.title,
          icon: Icons.text_fields,
        )
        .show();

    if (title != null && title != widget.file.title) {
      rasterize(() {
        widget.file.title = title;
      });
    }
  }

  Future _refresh() async {
    rasterize(() {
      _data = null;
      _pdfFileAlt = null;
      _controllerAlt = Completer<PDFViewController>();
      _refreshing = true;
    });
    await Future.delayed(Duration(milliseconds: 500));

    try {
      if (widget.file.path != null) {
        rasterize(() {
          _data = File(widget.file.path);
        });
      } else {
        _data = await _fetch(
          silent: true,
        );
      }

      if (_data == null) {
        return;
      }

      if (_isPdf) {
        rasterize(() async {
          _pdfFileAlt = PDFView(
            filePath: _data.path,
            fitEachPage: true,
            fitPolicy: FitPolicy.WIDTH,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: false,
            preventLinkNavigation: true,
            pageSnap: false,
            onRender: (_pages) {
              setState(() {
                _pages = _pages;
              });
            },
            onError: (error) {
              scope.alerts.error(error).show();
            },
            onPageError: (page, error) {
              scope.alerts.error(error).show();
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controllerAlt.complete(pdfViewController);
            },
            onPageChanged: (int page, int total) {
              setState(() {
                _currentPage = (page + 1);
                _pages = total;
              });
            },
          );
        });
      }
    } catch (err) {
      scope.alerts.error(err).show();
    }

    rasterize(() {
      _refreshing = false;
    });
  }

  bool get _isImage => widget.file.isImage;

  bool get _isPdf => widget.file.extension == 'pdf';
}
