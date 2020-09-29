import 'package:flutter/material.dart';
import 'package:wearableCommunicator/wearable_communicator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController _controller;
  String value = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    WearableListener.listenForMessage((msg) {
      print(msg);
    });
    WearableListener.listenForDataLayer((msg) {
      print(msg);
    });
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                    border: InputBorder.none, labelText: 'Enter some text'),
                onChanged: (String val) async {
                  setState(() {
                    value = val;
                  });
                },
              ),
              RaisedButton(
                child: Text('Send message to wearable'),
                onPressed: () {
                  primaryFocus.unfocus(disposition: UnfocusDisposition.scope);
                  WearableCommunicator.sendMessage({
                    "text": value,
                  });
                },
              ),
              RaisedButton(
                child: Text('set data on wearable'),
                onPressed: () {
                  primaryFocus.unfocus(disposition: UnfocusDisposition.scope);
                  WearableCommunicator.setData("message", {
                    "text": value != ""
                        ? value
                        : "test", // ensure we have at least empty string
                    "integerValue": 1,
                    "intList": [1, 2, 3],
                    "stringList": ["one", "two", "three"],
                    "floatList": [1.0, 2.4, 3.6],
                    "longList": []
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
