import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:whippx/main.dart';
import 'dart:async';
import 'dart:convert';

class MockWebSocketChannel extends Mock implements WebSocketChannelWrapper {
  final _streamController = StreamController<dynamic>.broadcast();
  final List<dynamic> sentMessages = [];

  @override
  Stream<dynamic> get stream => _streamController.stream;

  @override
  void sink(dynamic message) {
    sentMessages.add(message);
  }

  @override
  void close(int closeCode) {
    _streamController.close();
  }

  void receiveMessage(String message) {
    _streamController.add(message);
  }
}

void main() {
  testWidgets('WebSocket connection and transcription', (WidgetTester tester) async {
    final mockChannel = MockWebSocketChannel();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: HomePage(
        title: 'whippx',
        channel: mockChannel,
      ),
    ));

    // At the beginning, the app should show the initial message.
    expect(find.text('this is whippx. select an audio file or record to transcribe'), findsOneWidget);

    // Simulate receiving a transcription from the WebSocket.
    mockChannel.receiveMessage(jsonEncode({'transcription': 'hello world'}));
    await tester.pump();

    // The UI should now display the transcription.
    expect(find.text('hello world'), findsOneWidget);
  });
}
