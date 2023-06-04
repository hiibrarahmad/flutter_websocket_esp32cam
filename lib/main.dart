import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const title = 'esp32 cam';
    return MaterialApp(
      title: title,
      home: MyHomePage(
        title: title,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  late WebSocketChannel _channel;
  Uint8List? _imageBytes;
  bool _showCaptureButton = true;
  bool _showVideoButton = true;
  bool _showStopCaptureButton = false;
  bool _showStopVideoButton = false;

  @override
  void initState() {
    super.initState();
    _channel = IOWebSocketChannel.connect('ws://192.168.137.26:8888');
    _channel.stream.listen((data) {
      if (data is Uint8List) {
        setState(() {
          _imageBytes = data;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 15, 10, 30),
                child: Column(
                  children: [
                    const Text(
                      "Actions",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _sendCaptureCommand,
                          child: const Text('Capture Image'),
                        ),
                        ElevatedButton(
                          onPressed: _sendVideoCommand,
                          child: const Text('Start Video'),
                        ),
                        ElevatedButton(
                          onPressed: _reconnectWebSocket,
                          child: const Text('Reconnect'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 15, 10, 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: const Text(
                                  "Receiver",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _imageBytes != null
                                ? Image.memory(
                              _imageBytes!,
                              key: UniqueKey(), // Unique key to avoid flickering
                            )
                                : const Text('Waiting for connection'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_imageBytes != null && _showStopCaptureButton)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ElevatedButton(
                        onPressed: _sendStopCaptureCommand,
                        child: const Text('Stop Capture'),
                      ),
                    ),
                  if (_imageBytes != null && _showStopVideoButton)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ElevatedButton(
                        onPressed: _sendStopVideoCommand,
                        child: const Text('Stop Video'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement the image download logic
              },
              child: const Text('Download Image'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showCaptureButton = true;
            _showVideoButton = true;
          });
        },
        tooltip: 'Send message',
        child: const Icon(Icons.send),
      ),
    );
  }

  void _sendCaptureCommand() {
    _channel.sink.add('capture');
    setState(() {
      _showCaptureButton = false;
      _showStopCaptureButton = true;
      _showVideoButton = false;
      _showStopVideoButton = false;
    });
  }

  void _sendVideoCommand() {
    _channel.sink.add('start video');
    setState(() {
      _showVideoButton = false;
      _showStopVideoButton = true;
      _showCaptureButton = false;
      _showStopCaptureButton = false;
    });
  }

  void _sendStopCaptureCommand() {
    _channel.sink.add('stop capture');
    setState(() {
      _showCaptureButton = true;
      _showStopCaptureButton = false;
    });
  }

  void _sendStopVideoCommand() {
    _channel.sink.add('stop video');
    setState(() {
      _showVideoButton = true;
      _showStopVideoButton = false;
    });
  }

  void _reconnectWebSocket() {
    _channel.sink.close();
    _channel = IOWebSocketChannel.connect('ws://192.168.137.26:8888');
    _channel.stream.listen((data) {
      if (data is Uint8List) {
        setState(() {
          _imageBytes = data;
        });
      }
    });
    setState(() {
      _showCaptureButton = true;
      _showVideoButton = true;
      _showStopCaptureButton = false;
      _showStopVideoButton = false;
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }
}
