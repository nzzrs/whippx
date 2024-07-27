import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

void main() {
  runApp(const WhippxApp());
}

class WhippxApp extends StatelessWidget {
  const WhippxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'whippx',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xaa0f00aa),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'whippx'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _transcription = '';

  Future<void> _transcribeAudio(File audioFile) async {
    final request = http.MultipartRequest('POST', Uri.parse('https://whippx-server.onrender.com/transcribe'));
    request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final result = json.decode(responseBody);
      setState(() {
        _transcription = result.toString();
      });
    } else {
      setState(() {
        _transcription = 'Error transcribing audio';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Transcription:',
            ),
            Text(
              _transcription,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Simulate picking an audio file
          Directory tempDir = await getTemporaryDirectory();
          File tempFile = File(join(tempDir.path, 'example.wav'));
          await tempFile.writeAsBytes([]); // Simulate an empty audio file
          await _transcribeAudio(tempFile);
        },
        tooltip: 'Transcribe',
        child: const Icon(Icons.mic),
      ),
    );
  }
}
