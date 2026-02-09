import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to your existing MainScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          },
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isPermissionGranted = false;
  late final Future<void> _future;
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final FlutterTts _flutterTts = FlutterTts();

  // Variables for displaying and highlighting recognized text
  String _recognizedText = '';
  List<String> _words = [];
  int _currentWordIndex = -1;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _future = _initializeCameraAndPermissions();
    _initializeTTS();
  }

  Future<void> _initializeCameraAndPermissions() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      isPermissionGranted = status == PermissionStatus.granted;
    });
    if (isPermissionGranted) {
      _cameras = await availableCameras();
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
      try {
        await _controller!.initialize();
      } catch (e) {
        if (mounted) {
          setState(() {});
          print('Camera initialization error: $e');
        }
      }
      if (mounted) setState(() {}); // Refresh UI after initialization
    }
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<String> _recognizeText() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return 'Camera not ready';
    }
    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
      await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      return recognizedText.text;
    } catch (e) {
      print('OCR error: $e');
      return 'Error processing image';
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) {
      await _flutterTts.speak("No text recognized");
      return;
    }

    _words = text.split(' ');
    _currentWordIndex = -1;
    _isSpeaking = true;
    setState(() {});

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      setState(() {
        _currentWordIndex = _words.indexOf(word);
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _currentWordIndex = -1;
      });
    });

    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Text Recognition + TTS'),
            ),
            body: isPermissionGranted &&
                _controller != null &&
                _controller!.value.isInitialized
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity, // makes it stretch horizontally
                  child: CameraPreview(_controller!),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: _words.asMap().entries.map((entry) {
                          int idx = entry.key;
                          String word = entry.value;
                          bool isHighlighted = idx == _currentWordIndex;

                          return TextSpan(
                            text: '$word ',
                            style: TextStyle(
                              color: isHighlighted ? Colors.white : Colors.black,
                              backgroundColor: isHighlighted ? Colors.deepPurple : Colors.transparent,
                              fontSize: 18,
                              height: 1.5,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final text = await _recognizeText();
                    setState(() {
                      _recognizedText = text;
                      _words = text.split(' ');
                      _currentWordIndex = -1;
                    });
                    await _speak(text);
                  },
                  child: Text(_isSpeaking ? 'Speaking...' : 'Scan & Read Aloud'),
                ),
              ],
            )
                : Center(
              child: Text(
                isPermissionGranted
                    ? 'Camera initializing...'
                    : 'Camera Permission Denied',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}