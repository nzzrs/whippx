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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppStrings {
  static const String appTitle = 'whippx';
  static String currentLanguage = '#####';
  static String initialMessage = 'this is whippx. select an audio file or record to transcribe';
  static String processingMessage = 'processing';
  static String recordingMessage = 'recording...';
  static String errorTranscribing = 'error transcribing audio';
  static String serverSleeping = 'shhh, server sleeping...';
  static String internalServerError = 'internal server error';
  static String fileNotFound = 'server looking for your file';
  static String unknownError = 'unknown error';
  static String unknownResponse = 'what happened??';
  static String transcribeTooltip = 'record';
  static String selectFileTooltip = 'select file';
  static String downloadTooltip = 'download';
  static String recordedFile = 'recorded file';
  static String transcriptionFileSuffix = 'transcription';
  static String downloadSnackBarMessage = 'transcription downloaded to';
  static String stopRecordingTooltip = 'stop recording';
  static String grantPermissionMessage = 'grant microphone access in the button below';
  static String grantPermissionButton = 'grant permission';
  static String permissionDeniedMessage = 'microphone permission denied';
  static String failedToStartRecorderMessage = 'failed to start recorder';
  static String denyPermissionButton = 'deny';
  static String failedToGetDownloadDirectoryMessage = 'failed to get download directory';
  static String recordingSavedMessage = 'recording saved into downloads folder';
  static String failedToStopRecorderMessage = 'failed to stop recorder';
  static String language = 'language';
  static String english = 'english';
  static String spanish = 'spanish';
  static String cancelTooltip = 'cancel';
  static String transcriptionCanceledMessage = 'transcription cancelled';

  static void setSpanish() {
    currentLanguage = 'español';
    initialMessage = 'seleccionar un archivo de audio o grabar para transcribir';
    processingMessage = 'procesando';
    recordingMessage = 'grabando...';
    errorTranscribing = 'error al transcribir el audio';
    serverSleeping = 'shhh, servidor mimiendo...';
    internalServerError = 'error interno del servidor';
    fileNotFound = 'servidor buscando su archivo';
    unknownError = 'error desconocido';
    unknownResponse = 'qué pasó ayer?';
    transcribeTooltip = 'grabar';
    selectFileTooltip = 'seleccionar archivo';
    downloadTooltip = 'descargar';
    recordedFile = 'archivo grabado';
    transcriptionFileSuffix = 'transcripción';
    downloadSnackBarMessage = 'transcripción descargada a';
    stopRecordingTooltip = 'detener grabación';
    grantPermissionMessage = 'otorgar acceso al micrófono en el botón de abajo';
    grantPermissionButton = 'otorgar permiso';
    permissionDeniedMessage = 'permiso de micrófono denegado';
    failedToStartRecorderMessage = 'no se pudo iniciar la grabadora de voz';
    denyPermissionButton = 'denegar';
    failedToGetDownloadDirectoryMessage = 'no se pudo obtener el directorio de descargas';
    recordingSavedMessage = 'grabación guardada en la carpeta de descargas';
    failedToStopRecorderMessage = 'no se pudo detener la grabadora';
    language = 'idioma';
    english = 'inglés';
    spanish = 'español';
    cancelTooltip = 'cancelar';
    transcriptionCanceledMessage = 'transcripción cancelada';
  }

  static void setEnglish() {
    currentLanguage = 'english';
    initialMessage = 'this is whippx. select an audio file or record to transcribe';
    processingMessage = 'processing';
    recordingMessage = 'recording...';
    errorTranscribing = 'error transcribing audio';
    serverSleeping = 'shhh, server sleeping...';
    internalServerError = 'internal server error';
    fileNotFound = 'server looking for your file';
    unknownError = 'unknown error';
    unknownResponse = 'what happened??';
    transcribeTooltip = 'record';
    selectFileTooltip = 'select file';
    downloadTooltip = 'download';
    recordedFile = 'recorded file';
    transcriptionFileSuffix = 'transcription';
    downloadSnackBarMessage = 'transcription downloaded to';
    stopRecordingTooltip = 'stop recording';
    grantPermissionMessage = 'grant microphone access in the button below';
    grantPermissionButton = 'grant permission';
    permissionDeniedMessage = 'microphone permission denied';
    failedToStartRecorderMessage = 'failed to start recorder';
    denyPermissionButton = 'deny';
    failedToGetDownloadDirectoryMessage = 'failed to get download directory';
    recordingSavedMessage = 'recording saved into downloads folder';
    failedToStopRecorderMessage = 'failed to stop recorder';
    language = 'language';
    english = 'english';
    spanish = 'spanish';
    cancelTooltip = 'cancel';
    transcriptionCanceledMessage = 'transcription cancelled';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String selectedLanguage = prefs.getString('language') ?? 'en';

  switch (selectedLanguage) {
    case 'es':
    AppStrings.setSpanish();
    break;
    case 'en':
    AppStrings.setEnglish();
    break;
    default:
    AppStrings.setEnglish();
    break;
  }

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
  String _transcription = '';
  bool _waitingResponse = false;
  String _fileId = '';
  String _fileName = '';
  bool _isRecording = false;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _recordedFilePath;
  bool _showDownloadButton = false;
  String _selectedLanguage = '';
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    _initializeRecorder();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedLanguage = _prefs?.getString('language') ?? 'en';

    switch (_selectedLanguage) {
      case 'es':
      AppStrings.setSpanish();
      break;
      case 'en':
      AppStrings.setEnglish();
      break;
      default:
      AppStrings.setEnglish();
      break;
    }

    _transcription = AppStrings.initialMessage;

    String? lastFileId = _prefs?.getString('last_file_id');
    if (lastFileId != null) {
      _fileId = lastFileId;
      _waitingResponse = true;
      _checkTranscriptionStatus();
    }
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
      _waitingResponse = true;
      _showDownloadButton = false;
    });

    final request = http.MultipartRequest('POST', Uri.parse('${dotenv.env['API_URL']}/send-to-transcribe'));
    request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      _fileId = jsonResponse['file_id'];
      await _prefs?.setString('last_file_id', _fileId);
      _checkTranscriptionStatus();
    } else {
      setState(() {
        _transcription = AppStrings.internalServerError;
        _waitingResponse = false;
        _showDownloadButton = false;
      });
    }
  }

  Future<void> _checkTranscriptionStatus() async {
    while (_waitingResponse && _prefs?.getString('last_file_id') != null) {
      final response = await http.get(Uri.parse('${dotenv.env['API_URL']}/get-response?file_id=$_fileId'));

      if (response.statusCode == 200) {
        setState(() {
          _transcription = response.body;
          _waitingResponse = false;
          _showDownloadButton = true;
          _prefs?.remove('last_file_id');
        });
      } else if (response.statusCode == 502) {
        setState(() {
          _transcription = AppStrings.serverSleeping;
          _waitingResponse = false;
          _showDownloadButton = false;
          _prefs?.remove('last_file_id');
        });
      } else if (response.statusCode == 404) {
        final responseBody = json.decode(response.body);
        switch (responseBody['error'] ?? responseBody['status']) {
          case "file not found":
            setState(() {
              _transcription = AppStrings.fileNotFound;
              _waitingResponse = true;
              _showDownloadButton = false;
            });
            break;
          case "processing":
            setState(() {
              _transcription = AppStrings.processingMessage;
              _waitingResponse = true;
              _showDownloadButton = false;
            });
            break;
          case "unknown error":
            setState(() {
              _transcription = AppStrings.unknownError;
              _waitingResponse = false;
              _showDownloadButton = false;
              _prefs?.remove('last_file_id');
            });
            break;
          default:
            setState(() {
              _transcription = AppStrings.unknownResponse;
              _waitingResponse = false;
              _showDownloadButton = false;
              _prefs?.remove('last_file_id');
            });
            break;
        }
        
      await Future.delayed(const Duration(seconds: 10));
      } else {
        setState(() {
          _transcription = AppStrings.internalServerError;
          _waitingResponse = false;
          _showDownloadButton = false;
          _prefs?.remove('last_file_id');
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
        SnackBar(content: Text(AppStrings.failedToGetDownloadDirectoryMessage)),
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
        title: Text(AppStrings.permissionDeniedMessage, textAlign: TextAlign.center),
        content: Text(AppStrings.grantPermissionMessage, textAlign: TextAlign.center),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.denyPermissionButton),
          ),
          const SizedBox(width: 12.0),
          TextButton(
            onPressed: () => openAppSettings(),
            child: Text(AppStrings.grantPermissionButton),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    Directory directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.failedToGetDownloadDirectoryMessage)),
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
        SnackBar(content: Text(AppStrings.recordingSavedMessage)),
      );
      await _transcribeAudio(file);
    } else {
      setState(() {
        _transcription = AppStrings.initialMessage;
        _showDownloadButton = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.failedToStopRecorderMessage)),
      );
    }
  }

  Future<void> _showLanguageDialog() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppStrings.language, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<String>(
                title: Text(AppStrings.english),
                value: AppStrings.english,
                groupValue: _selectedLanguage,
                onChanged: (String? value) {
                  setState(() {
                    AppStrings.setEnglish();
                    _selectedLanguage = 'en';
                    _prefs?.setString('language', _selectedLanguage);
                    _resetHomePage();
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: Text(AppStrings.spanish),
                value: AppStrings.spanish,
                groupValue: _selectedLanguage,
                onChanged: (String? value) {
                  setState(() {
                    AppStrings.setSpanish();
                    _selectedLanguage = 'es';
                    _prefs?.setString('language', _selectedLanguage);
                    _resetHomePage();
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetHomePage() {
    setState(() {
      _transcription = AppStrings.initialMessage;
      _waitingResponse = false;
      _fileId = '';
      _fileName = '';
      _isRecording = false;
      _recordedFilePath = null;
      _showDownloadButton = false;
    });
  }

  void _cancelTranscription() {
    setState(() {
      _fileId = '';
      _prefs?.remove('last_file_id');
      _waitingResponse = false;
      _transcription = AppStrings.transcriptionCanceledMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _resetHomePage,
          child: Text(widget.title),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String result) {
              if (result == 'language') {
                _showLanguageDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'language',
                child: Text('${AppStrings.language}: ${AppStrings.currentLanguage}'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.all(20.0),
                  child: Text(
                    _transcription,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
                    textAlign: _waitingResponse ? TextAlign.center : TextAlign.left,
                  ),
                ),
                const SizedBox(height: 16),
                if (_waitingResponse) const CircularProgressIndicator(),
              ],
            ),
          ),
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
          if (_waitingResponse)
            FloatingActionButton(
              onPressed: _cancelTranscription,
              tooltip: AppStrings.cancelTooltip,
              backgroundColor: Theme.of(context).colorScheme.error,
              child: Icon(Icons.close, color: Theme.of(context).colorScheme.onError),
            ),
          if (!_waitingResponse)
            FloatingActionButton(
              onPressed: _pickFile,
              tooltip: AppStrings.selectFileTooltip,
              child: const Icon(Icons.folder),
            ),
          const SizedBox(width: 16),
          if (!_waitingResponse)
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
