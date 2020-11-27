import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';


/// Static class to send messages and data to wearables
class WearableCommunicator {
  static const MethodChannel _channel = const MethodChannel('wearableCommunicator');

  /// send message to watch
  /// the message must conform to https://api.flutter.dev/flutter/services/StandardMessageCodec-class.html
  ///
  /// android consideration: message will be converted to a json string and send on a channel name "MessageChannel"
  static void sendMessage(Map<String, dynamic> message) async {
    await _channel.invokeMethod('sendMessage', message);
  }

  /// set constant data
  /// the data must conform to https://api.flutter.dev/flutter/services/StandardMessageCodec-class.html
  /// android: sets data on data layer by the path
  static void setData(String path, Map<String, dynamic> data) async {
    if (!path.startsWith("/")) {
      path = "/" + path;
    }
    await _channel.invokeListMethod('setData', {"path": path, "data": data});
  }
}


/// typedef for listener callbacks
typedef void MultiUseCallback(dynamic msg);

/// Holder for wearable data and messages
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
        if (call.arguments["args"] is String) {
          try {
            Map value = json.decode(call.arguments["args"]);
            _messageCallbacksById[call.arguments["id"]](value);
          } catch (Exception) {
            _messageCallbacksById[call.arguments["id"]](call.arguments["args"]);
          }
        } else {
          _messageCallbacksById[call.arguments["id"]](call.arguments["args"]);
        }
        break;
      case 'dataReceived':
        if (call.arguments["args"] is String) {
          try {
            Map value = json.decode(call.arguments["args"]);
            _dataCallbacksById[call.arguments["id"]](value);
          } catch (Exception) {
            _dataCallbacksById[call.arguments["id"]](call.arguments["args"]);
          }
        } else {
          _dataCallbacksById[call.arguments["id"]](call.arguments["args"]);
        }

        break;
      default:
        print(
            'TestFairy: Ignoring invoke from native. This normally shouldn\'t happen.');
    }
  }

  /// register a callback function for wearable messages
  /// returns a function to stop the listener
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

  /// register a function for data layer events
  /// returns a function to stop the listener
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
