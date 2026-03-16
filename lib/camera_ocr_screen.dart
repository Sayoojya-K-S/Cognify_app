import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'globals.dart'; // Import to access global 'cameras'
import 'text_display_screen.dart'; // Import for TextDisplayScreen
import 'services/accessibility_service.dart';
import 'models/accessibility_profile.dart';
import 'common/voice_accessible_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isPermissionGranted = false;
  late final Future<void> _future;
  CameraController? _controller;
  late final TextRecognizer _textRecognizer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer();
    _future = _initializeCameraAndPermissions();
  }

  Future<void> _initializeCameraAndPermissions() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      isPermissionGranted = status == PermissionStatus.granted;
    });

    if (isPermissionGranted && cameras.isNotEmpty) {
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      try {
        await _controller!.initialize();
        // Simple announcements can be done here if needed, or rely on screen reader
      } catch (e) {
        if (mounted) {
          debugPrint('Camera initialization error: $e');
        }
      }
      if (mounted) setState(() {});
    }
  }

  Future<String> _recognizeText() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return 'Camera not ready';
    }
    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('OCR error: $e');
      return 'Error processing image';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ValueListenableBuilder<AccessibilityProfile>(
            valueListenable: AccessibilityService().profileNotifier,
            builder: (context, profile, child) {
              final bool isVoiceMode = profile.voiceGuidanceEnabled;
              
              Future<void> triggerCapture() async {
                  if (_isProcessing) return;
                  _isProcessing = true;

                  try {
                    // Feedback for capture
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Processing..."), duration: Duration(milliseconds: 500)),
                    );
                    
                    final text = await _recognizeText();
                    
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TextDisplayScreen(text: text),
                        ),
                      );
                    }
                  } finally {
                    _isProcessing = false;
                  }
              }

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Camera OCR'),
                  leading: VoiceAccessibleWidget(
                    label: "Back",
                    onTap: () {
                      AccessibilityService().stopSpeaking();
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
// ...
                body: isPermissionGranted &&
                    _controller != null &&
                    _controller!.value.isInitialized
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          if (isVoiceMode) {
                              await AccessibilityService().announce("Double tap to capture text");
                          } else {
                              await triggerCapture();
                          }
                        },
                        onDoubleTap: isVoiceMode ? () async {
                           await triggerCapture();
                        } : null,
                        child: Stack(
                          children: [
                            SizedBox(
                              height: double.infinity,
                              width: double.infinity,
                              child: CameraPreview(_controller!),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  isVoiceMode ? 'Double tap screen to scan' : 'Tap screen to scan text',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
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
    AccessibilityService().stopSpeaking();
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}
