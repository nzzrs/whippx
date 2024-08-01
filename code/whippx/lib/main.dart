import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class AppStrings {
  static const String appTitle = 'whippx';
  static const String initialMessage = 'this is whippx. select an audio file or record to transcribe';
  static const String processingMessage = 'processing';
  static const String recordingMessage = 'recording...';
  static const String errorTranscribing = 'error transcribing audio';
  static const String serverSleeping = 'shhh, server sleeping...';
  static const String internalServerError = 'internal server error';
  static const String fileNotFound = 'server looking for your file';
  static const String transcribeTooltip = 'record';
  static const String selectFileTooltip = 'select file';
  static const String downloadTooltip = 'download';
  static const String recordedFile = 'recorded file';
  static const String transcriptionFileSuffix = 'transcription';
  static const String downloadSnackBarMessage = 'transcription downloaded to';
  static const String stopRecordingTooltip = 'stop recording';
  static const String grantPermissionMessage = 'grant microphone access in the button below';
  static const String grantPermissionButton = 'grant permission';
  static const String permissionDeniedMessage = 'Microphone permission denied';
  static const String failedToStartRecorderMessage = 'Failed to start recorder';
}

void main() {
  runApp(const WhippxApp());
}

class WhippxApp extends StatelessWidget {
  const WhippxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xaa0f00aa),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(title: AppStrings.appTitle),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _transcription = AppStrings.initialMessage;
  bool _isProcessing = false;
  String _fileId = '';
  bool _shouldCheckStatus = false;
  String _fileName = '';
  bool _isRecording = false;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _recordedFilePath;
  bool _showDownloadButton = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    setState(() {});
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _transcribeAudio(File audioFile) async {
    setState(() {
      _fileName = path.basenameWithoutExtension(audioFile.path);
      _transcription = '${AppStrings.processingMessage} ${path.basename(audioFile.path)}';
      _isProcessing = true;
      _shouldCheckStatus = true;
      _showDownloadButton = false;
    });

    final request = http.MultipartRequest('POST', Uri.parse('https://liberal-hopelessly-deer.ngrok-free.app/send-to-transcribe'));
    request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      _fileId = jsonResponse['file_id'];
      _checkTranscriptionStatus();
    } else {
      setState(() {
        _transcription = AppStrings.internalServerError;
        _isProcessing = false;
        _shouldCheckStatus = false;
        _showDownloadButton = false;
      });
    }
  }

  Future<void> _checkTranscriptionStatus() async {
    while (_shouldCheckStatus) {
      await Future.delayed(const Duration(seconds: 10));
      final response = await http.get(Uri.parse('https://liberal-hopelessly-deer.ngrok-free.app/get-response?file_id=$_fileId'));

      if (response.statusCode == 200) {
        setState(() {
          _transcription = response.body;
          _isProcessing = false;
          _shouldCheckStatus = false;
          _showDownloadButton = true;
        });
      } else if (response.statusCode == 502) {
        setState(() {
          _transcription = AppStrings.serverSleeping;
          _isProcessing = false;
          _shouldCheckStatus = false;
          _showDownloadButton = false;
        });
      } else if (response.statusCode == 404) {
        final responseBody = json.decode(response.body);
        if (responseBody['error'] == "file not found") {
          setState(() {
            _transcription = AppStrings.fileNotFound;
            _isProcessing = true;
            _showDownloadButton = false;
            _shouldCheckStatus = true;
          });
        } else {
          setState(() {
            _transcription = AppStrings.processingMessage;
            _isProcessing = true;
            _showDownloadButton = false;
          });
        }
      } else {
        setState(() {
          _transcription = AppStrings.internalServerError;
          _isProcessing = false;
          _shouldCheckStatus = false;
          _showDownloadButton = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      await _transcribeAudio(file);
    }
  }

  Future<void> _downloadTranscription() async {
    Directory directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get download directory')),
      );
      return;
    }
    String savePath = path.join(
      directory.path,
      '$_fileName (${AppStrings.transcriptionFileSuffix}).txt',
    );

    final file = File(savePath);
    await file.writeAsString(_transcription);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${AppStrings.downloadSnackBarMessage} $savePath')),
    );
  }

  Future<void> _requestPermissionAndStartRecording() async {
    var status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      _startRecording();
    } else if (status == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.permissionDeniedMessage)),
      );
      _showPermissionDialog(context);
    } else if (status == PermissionStatus.permanentlyDenied) {
      _showPermissionDialog(context);
    }
  }

  Future<void> _showPermissionDialog(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text('Allow access to the microphone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    Directory directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get download directory')),
      );
      return;
    }

    String timeStamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    String filePath = path.join(directory.path, '${AppStrings.recordedFile} - $timeStamp.wav');

    setState(() {
      _isRecording = true;
      _transcription = AppStrings.recordingMessage;
      _recordedFilePath = filePath;
      _showDownloadButton = false;
    });

    try {
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.pcm16WAV,
      );
    } catch (e) {
      setState(() {
        _isRecording = false;
        _transcription = AppStrings.initialMessage;
        _showDownloadButton = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.failedToStartRecorderMessage}: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    String? filePath = await _recorder.stopRecorder();

    setState(() {
      _isRecording = false;
      _transcription = AppStrings.processingMessage;
    });

    if (filePath != null) {
      File file = File(_recordedFilePath!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('recording saved into downloads folder')),
      );
      await _transcribeAudio(file);
    } else {
      setState(() {
        _transcription = AppStrings.initialMessage;
        _showDownloadButton = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recorder')),
      );
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
            Container(
              margin: const EdgeInsets.all(20.0),
              child: Text(
                _transcription,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
                textAlign: _isProcessing ? TextAlign.center : TextAlign.left,
              ),
            ),
            const SizedBox(height: 16),
            if (_isProcessing) const CircularProgressIndicator(),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (_showDownloadButton)
            FloatingActionButton(
              onPressed: _downloadTranscription,
              tooltip: AppStrings.downloadTooltip,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.download, color: Theme.of(context).colorScheme.onPrimary),
            ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _pickFile,
            tooltip: AppStrings.selectFileTooltip,
            child: const Icon(Icons.folder),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _isRecording ? _stopRecording : _requestPermissionAndStartRecording,
            tooltip: _isRecording ? AppStrings.stopRecordingTooltip : AppStrings.transcribeTooltip,
            backgroundColor: _isRecording ? null : null,
            child: Icon(_isRecording ? Icons.stop : Icons.mic, color: _isRecording ? Theme.of(context).colorScheme.error : null),
          ),
        ],
      ),
    );
  }
}
