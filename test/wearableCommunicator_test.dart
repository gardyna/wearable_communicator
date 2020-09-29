import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wearable_communicator/wearable_communicator.dart';

void main() {
  const MethodChannel channel = MethodChannel('wearableCommunicator');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await WearableCommunicator.platformVersion, '42');
  });
}
