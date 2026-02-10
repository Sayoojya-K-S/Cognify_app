import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/accessibility_service.dart';
import 'main.dart'; // Import to access global 'cameras'



class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isPermissionGranted = false;
  late final Future<void> _future;
  CameraController? _controller;
  final FlutterTts _flutterTts = FlutterTts();
  late final TextRecognizer _textRecognizer;

  // Variables for displaying and highlighting recognized text
  String _recognizedText = '';
  List<String> _words = [];
  int _currentWordIndex = -1;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer();
    _future = _initializeCameraAndPermissions();
    _initializeTTS();
  }

  Future<void> _initializeCameraAndPermissions() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      isPermissionGranted = status == PermissionStatus.granted;
    });

    if (isPermissionGranted && cameras.isNotEmpty) {
      // Use the first camera from the global list
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high, // Improved resolution for OCR
        enableAudio: false,
      );
      try {
        await _controller!.initialize();
        await _flutterTts.speak("Camera Active. Tap screen to scan.");
      } catch (e) {
        if (mounted) {
          debugPrint('Camera initialization error: $e');
        }
      }
      if (mounted) setState(() {}); // Refresh UI after initialization
    }
  }

  Future<void> _initializeTTS() async {
    final profile = AccessibilityService().currentProfile;
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(profile.pitch);
    await _flutterTts.setSpeechRate(profile.speechRate);

    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }
    });

    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (mounted) {
        setState(() {
          // Identify the word being spoken to highlight it
          // Simple matching, might need more robust logic for duplicate words
          // but sufficient for basic demo
          int index = _words.indexOf(word, _currentWordIndex + 1);
           if (index != -1) {
            _currentWordIndex = index;
          }
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentWordIndex = -1;
        });
      }
    });
    
    _flutterTts.setCancelHandler(() {
        if (mounted) {
            setState(() {
                _isSpeaking = false;
                _currentWordIndex = -1;
            });
        }
    });
  }

  Future<String> _recognizeText() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return 'Camera not ready';
    }
    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      // Use the persistent recognizer instance
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('OCR error: $e');
      return 'Error processing image';
    }
  }

  Future<void> _speak(String text) async {
    // If already speaking, stop it first
    await _flutterTts.stop();
    
    if (text.isEmpty) {
      if (mounted) { // check mounted before using context or setstate if needed later
         await _flutterTts.speak("No text recognized");
      }
      return;
    }

    // Reset state for new speech
    if (mounted) {
        setState(() {
            _words = text.split(RegExp(r'\s+')); // Better splitting
            _currentWordIndex = -1;
            _isSpeaking = true;
        });
    }

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
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                       if (_isSpeaking) {
                          await _flutterTts.stop();
                          setState(() => _isSpeaking = false);
                       } else {
                          await _flutterTts.speak("Processing");
                          final text = await _recognizeText();
                          setState(() {
                            _recognizedText = text;
                            _words = text.split(RegExp(r'\s+'));
                            _currentWordIndex = -1;
                          });
                          await _speak(text);
                       }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                       Expanded(
                         flex: 4,
                          child: Container(
                            width: double.infinity,
                            color: Colors.black,
                            child: Center(
                              child: CameraPreview(_controller!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                  style: const TextStyle(color: Colors.black, fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            _isSpeaking ? 'Tap to Stop' : 'Tap Screen to Scan',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
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
    _textRecognizer.close(); // Properly close the recognizer
    _flutterTts.stop();
    super.dispose();
  }
}
