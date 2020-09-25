import 'dart:async';

import 'package:flutter/services.dart';

class WearableCommunicator {
  static const MethodChannel _channel =
      const MethodChannel('wearableCommunicator');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// send message to watch
  /// the message must conform to https://api.flutter.dev/flutter/services/StandardMessageCodec-class.html
  ///
  /// android consideration: message will be converted to a json string and send on a channel name "MessageChannel"
  static void sendMessage(Map<String, dynamic> message) async {
    await _channel.invokeMethod('sendMessage', message);
  }

  /// set constant data
  /// the data must conform to https://api.flutter.dev/flutter/services/StandardMessageCodec-class.html
  /// android: sets data on data layer by the name
  static void setData(String path, Map<String, dynamic> data) async {
    if (!path.startsWith("/")) {
      path = "/" + path;
    }
    await _channel.invokeListMethod('setData', {"path": path, "data": data});
  }
}

typedef void Listener(dynamic msg);
typedef void MultiUseCallback(String msg);
typedef void CancelListening();

class WearableListener {
  static const _channel = const MethodChannel("wearableCommunicator");
  static int _nextCallbackId = 0;
  static Map<int, MultiUseCallback> _messageCallbacksById = new Map();
  static Map<int, MultiUseCallback> _dataCallbacksById = new Map();

  WearableListener() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  static Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'messageReceived':
        _messageCallbacksById[call.arguments["id"]](call.arguments["args"]);
        break;
      case 'dataReceived':
        _dataCallbacksById[call.arguments["id"]](call.arguments["args"]);
        break;
      default:
        print(
            'TestFairy: Ignoring invoke from native. This normally shouldn\'t happen.');
    }
  }

  static Future<void> listenForMessage(MultiUseCallback callback) async {
    _channel.setMethodCallHandler(_methodCallHandler);
    int currentListenerId = _nextCallbackId++;
    _messageCallbacksById[currentListenerId] = callback;
    await _channel.invokeMethod("listenMessages", currentListenerId);
    return () {
      _channel.invokeMethod("cancelListeningMessages", currentListenerId);
      _messageCallbacksById.remove(currentListenerId);
    };
  }

  static Future<void> listenForDataLayer(MultiUseCallback callback) async {
    _channel.setMethodCallHandler(_methodCallHandler);
    int currentListenerId = _nextCallbackId++;
    _dataCallbacksById[currentListenerId] = callback;
    await _channel.invokeMethod("listenData", currentListenerId);
    return () {
      _channel.invokeMethod("cancelListeningData", currentListenerId);
      _dataCallbacksById.remove(currentListenerId);
    };
  }
}
