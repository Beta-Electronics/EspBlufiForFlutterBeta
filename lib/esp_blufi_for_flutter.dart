import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

//typedef ResultCallback = void Function(String? data);
typedef ResultCallback = void Function(dynamic data);
typedef ErrorCallback = void Function(dynamic error);

class BlufiPlugin {
  final MethodChannel? _channel = const MethodChannel('esp_blufi_for_flutter');
  final EventChannel _eventChannel =
      EventChannel('esp_blufi_for_flutter/state');

  BlufiPlugin._() {
    _channel!.setMethodCallHandler(null);

    _eventChannel
        .receiveBroadcastStream()
        .listen(speechResultsHandler, onError: speechResultErrorHandler);
  }

  ResultCallback? _resultSuccessCallback;
  ResultCallback? _resultErrorCallback;

  static BlufiPlugin _instance = new BlufiPlugin._();
  static BlufiPlugin get instance => _instance;

  void onMessageReceived(
      {ResultCallback? successCallback,
      ErrorCallback?
          errorCallback // ← Usa ErrorCallback invece di ResultCallback
      }) {
    _resultSuccessCallback = successCallback;
    _resultErrorCallback = errorCallback;
  }

  Future<String?> get platformVersion async {
    final String? version = await _channel!.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<bool?> scanDeviceInfo({String? filterString}) async {
    final bool? isEnable = await _channel!.invokeMethod(
        'scanDeviceInfo', <String, dynamic>{'filter': filterString});
    return isEnable;
  }

  Future stopScan() async {
    await _channel!.invokeMethod('stopScan');
  }

  Future connectPeripheral({String? peripheralAddress}) async {
    await _channel!.invokeMethod('connectPeripheral',
        <String, dynamic>{'peripheral': peripheralAddress});
  }

  Future requestCloseConnection() async {
    await _channel!.invokeMethod('requestCloseConnection');
  }

  Future negotiateSecurity() async {
    await _channel!.invokeMethod('negotiateSecurity');
  }

  Future requestDeviceVersion() async {
    await _channel!.invokeMethod('requestDeviceVersion');
  }

  Future configProvision({String? username, String? password}) async {
    await _channel!.invokeMethod('configProvision',
        <String, dynamic>{'username': username, 'password': password});
  }

  Future requestDeviceStatus() async {
    await _channel!.invokeMethod('requestDeviceStatus');
  }

  Future requestDeviceScan() async {
    await _channel!.invokeMethod('requestDeviceScan');
  }

  Future postCustomData(String dataStr) async {
    await _channel!.invokeMethod(
        'postCustomData', <String, dynamic>{'custom_data': dataStr});
  }

  speechResultsHandler(dynamic event) {
    if (event is Map) {
      String key = event['key'];

      // Se è custom data, event['value'] sarà Uint8List
      if (key == 'receive_device_custom_data') {
        dynamic value = event['value'];
        if (value is Uint8List) {
          // Passa direttamente i byte
          if (_resultSuccessCallback != null) {
            _resultSuccessCallback!(value); // ← Passa Uint8List
          }
          return;
        }
      }
    }

    // Per altri messaggi, converti in JSON come prima
    if (_resultSuccessCallback != null) {
      _resultSuccessCallback!(jsonEncode(event));
    }
  }

  speechResultErrorHandler(dynamic error) {
    if (_resultErrorCallback != null) _resultErrorCallback!(error);
  }
}
