// importa las librerías necesarias
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';

// clase para definir todas las cadenas de texto, facilitando la traducción
class AppStrings {
  // título de la aplicación
  static const String appTitle = 'whippx';
  // mensaje inicial que se muestra en la pantalla
  static const String initialMessage = 'this is whippx. select an audio file or record to transcribe';
  // mensaje que se muestra mientras se procesa un archivo
  static const String processingMessage = 'processing';
  // mensaje que se muestra si ocurre un error durante la transcripción
  static const String errorTranscribing = 'error transcribing audio';
  // texto para la herramienta de transcripción
  static const String transcribeTooltip = 'transcribe';
  // texto para la herramienta de selección de archivos
  static const String selectFileTooltip = 'select file';
}

// función principal que inicia la aplicación
void main() {
  // ejecuta la aplicación whippx
  runApp(const WhippxApp());
}

// clase para definir la aplicación whippx
class WhippxApp extends StatelessWidget {
  // constructor de la clase WhippxApp
  const WhippxApp({super.key});

  // método para construir la interfaz de usuario de la aplicación
  @override
  Widget build(BuildContext context) {
    // retorna un widget MaterialApp que es la raíz de la aplicación
    return MaterialApp(
      // título de la aplicación
      title: AppStrings.appTitle,
      // desactiva la etiqueta de depuración en la esquina superior derecha
      debugShowCheckedModeBanner: false,
      // define el tema de la aplicación
      theme: ThemeData(
        // esquema de colores basado en un color semilla
        colorScheme: ColorScheme.fromSeed(
          // color semilla
          seedColor: const Color(0xaa0f00aa),
          // modo oscuro
          brightness: Brightness.dark,
        ),
        // usa Material Design 3
        useMaterial3: true,
      ),
      // define la página de inicio de la aplicación
      home: const HomePage(title: AppStrings.appTitle),
    );
  }
}

// clase para definir la página de inicio de la aplicación
class HomePage extends StatefulWidget {
  // constructor de la clase HomePage
  const HomePage({super.key, required this.title});

  // título de la página de inicio
  final String title;

  // método para crear el estado de la página de inicio
  @override
  State<HomePage> createState() => _HomePageState();
}

// clase para definir el estado de la página de inicio
class _HomePageState extends State<HomePage> {
  // variable para almacenar la transcripción
  String _transcription = AppStrings.initialMessage;
  // variable para indicar si el archivo se está procesando
  bool _isProcessing = false;

  // método para transcribir un archivo de audio
  Future<void> _transcribeAudio(File audioFile) async {
    // actualiza el estado para mostrar el mensaje de procesamiento
    setState(() {
      _transcription = '${AppStrings.processingMessage} ${basename(audioFile.path)}';
      _isProcessing = true;
    });

    // crea una solicitud HTTP de tipo multipart para enviar el archivo de audio
    final request = http.MultipartRequest('POST', Uri.parse('https://whippx-server.onrender.com/transcribe'));
    // agrega el archivo de audio a la solicitud
    request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    // envía la solicitud al servidor
    final response = await request.send();

    // verifica si la solicitud fue exitosa
    if (response.statusCode == 200) {
      // convierte la respuesta del servidor a una cadena de texto
      final responseBody = await response.stream.bytesToString();
      // decodifica la respuesta JSON a un mapa de Dart
      final result = json.decode(responseBody);
      // actualiza el estado con la transcripción recibida del servidor
      setState(() {
        _transcription = result.toString();
        _isProcessing = false;
      });
    } else {
      // actualiza el estado para mostrar un mensaje de error
      setState(() {
        _transcription = AppStrings.errorTranscribing;
        _isProcessing = false;
      });
    }
  }

  // método para seleccionar un archivo del sistema de archivos
  Future<void> _pickFile() async {
    // abre el selector de archivos y permite al usuario elegir un archivo
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    // verifica si se seleccionó un archivo
    if (result != null && result.files.single.path != null) {
      // crea un objeto File a partir del archivo seleccionado
      File file = File(result.files.single.path!);
      // transcribe el archivo seleccionado
      await _transcribeAudio(file);
    }
  }

  // método para construir la interfaz de usuario de la página de inicio
  @override
  Widget build(BuildContext context) {
    // retorna un widget Scaffold que proporciona la estructura básica de la pantalla
    return Scaffold(
      // barra de la aplicación con el título
      appBar: AppBar(
        // título de la barra de la aplicación
        title: Text(widget.title),
      ),
      // cuerpo de la página, centrado vertical y horizontalmente
      body: Center(
        child: Column(
          // centra los hijos verticalmente
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // widget de texto para mostrar la transcripción o el mensaje inicial
            Text(
              _transcription,
              // estilo del texto, con tamaño de letra pequeño
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
              // alineación del texto al centro
              textAlign: TextAlign.center,
            ),
            // muestra un indicador de progreso si el archivo se está procesando
            if (_isProcessing)
              const CircularProgressIndicator(),
          ],
        ),
      ),
      // botones de acción flotante en la esquina inferior derecha
      floatingActionButton: Row(
        // alinea los botones al final (derecha)
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // botón para seleccionar un archivo
          FloatingActionButton(
            // define la acción cuando se presiona el botón
            onPressed: _pickFile,
            // define el texto de la herramienta
            tooltip: AppStrings.selectFileTooltip,
            // ícono del botón (carpeta)
            child: const Icon(Icons.folder),
          ),
          // espacio entre los botones
          const SizedBox(width: 16),
          // botón para iniciar la transcripción
          FloatingActionButton(
            // define la acción cuando se presiona el botón
            onPressed: () async {
              // obtiene el directorio temporal del sistema
              Directory tempDir = await getTemporaryDirectory();
              // crea un archivo temporal vacío
              File tempFile = File(join(tempDir.path, 'example.wav'));
              await tempFile.writeAsBytes([]);
              // transcribe el archivo temporal
              await _transcribeAudio(tempFile);
            },
            // define el texto de la herramienta
            tooltip: AppStrings.transcribeTooltip,
            // ícono del botón (micrófono)
            child: const Icon(Icons.mic),
          ),
        ],
      ),
    );
  }
}
