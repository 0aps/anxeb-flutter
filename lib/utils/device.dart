import 'dart:io';
import 'package:anxeb_flutter/middleware/scope.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter_translate/flutter_translate.dart';

class Device {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getModelName() async {
    if (Platform.isAndroid) {
      var androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.model;
    } else {
      var iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.utsname.machine;
    }
  }

  Future<String> beginBarcodeScan({Scope scope, bool autoflash, String title}) async {
    String value;
    try {
      var scanResult = await BarcodeScanner.scan(
        options: ScanOptions(
          strings: {
            'cancel': 'X',
            'flash_on': translate('anxeb.utils.device.flash_on_label'), //TR Encender Luz
            'flash_off': translate('anxeb.utils.device.flash_off_label'), //TR Apagar Luz
          },
          autoEnableFlash: autoflash != null ? autoflash : true,
          android: AndroidOptions(
            useAutoFocus: true,
          ),
        ),
      );
      value = scanResult.rawContent;
    } catch (e) {
      value = null;
    }
    return value?.isNotEmpty == true ? value : null;
  }
}
