import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'text_display_screen.dart'; // Import for TextDisplayScreen
import 'services/accessibility_service.dart'; // Import AccessibilityService
import 'common/voice_accessible_widget.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

enum AudioState { idle, recording, paused, naming }

class _AudioScreenState extends State<AudioScreen> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  AudioState _currentState = AudioState.idle;
  String _recognizedText = "";
  String _fullText = ""; // Accumulates text across pauses
  
  // Double tap detection
  DateTime? _lastTapTime;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTts();
      _initSpeech();
    });
  }

  Future<void> _speak(String message) async {
    if (AccessibilityService().currentProfile.voiceGuidanceEnabled) {
      await _tts.speak(message);
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _speak("Tap once to start recording.");
  }

  Future<void> _initSpeech() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
       await _speak("Microphone permission denied.");
       return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (errorNotification) => print('onError: $errorNotification'),
    );
     if (!available) {
      await _speak("Microphone not available.");
    }
  }

  void _handleTap() async {
    final now = DateTime.now();
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      _lastTapTime = null; // Reset
      _handleDoubleTap();
    } else {
      _lastTapTime = now;
      // Wait to see if it's a double tap
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_lastTapTime == now) {
          _handleSingleTap();
        }
      });
    }
  }

  void _handleSingleTap() async {
    if (_currentState == AudioState.idle) {
      _startRecording();
    } else if (_currentState == AudioState.recording) {
       _pauseRecording();
    } else if (_currentState == AudioState.paused) {
      _resumeRecording();
    }
  }

  void _handleDoubleTap() {
    if (_currentState == AudioState.recording || _currentState == AudioState.paused) {
      _stopAndDisplay();
    }
  }

  Future<void> _startRecording() async {
     setState(() => _currentState = AudioState.recording);
     await _speak("Listening.");
     // awaited speak completion might persist if needed, but for now just speak
     // _tts.awaitSpeakCompletion(true) is valid but if disabled we just skip
     
     if (!_speech.isListening) {
       _speech.listen(onResult: (val) {
         setState(() {
           _recognizedText = val.recognizedWords;
         });
       });
     }
  }
  
  Future<void> _pauseRecording() async {
     setState(() => _currentState = AudioState.paused);
     _speech.stop();
     
     // Append recognized text
     if (_recognizedText.isNotEmpty) {
       _fullText += "$_recognizedText ";
       _recognizedText = "";
     }
     
     await _speak("Paused. Tap once to continue. Double tap to finish.");
  }
  
  Future<void> _resumeRecording() async {
      setState(() => _currentState = AudioState.recording);
      await _speak("Resuming.");
      
      _speech.listen(onResult: (val) {
         setState(() {
           _recognizedText = val.recognizedWords;
         });
       });
  }

  Future<void> _stopAndDisplay() async {
     setState(() => _currentState = AudioState.naming);
     await _speech.stop();
     
      if (_recognizedText.isNotEmpty) {
       _fullText += "$_recognizedText ";
       _recognizedText = "";
     }
     
     if (_fullText.trim().isEmpty) {
        await _speak("No audio recorded.");
        setState(() => _currentState = AudioState.idle);
        return;
     }

     await _speak("Processing complete. Displaying text.");

     if (mounted) {
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (context) => TextDisplayScreen(text: _fullText),
         ),
       ).then((_) {
          // Reset state when returning
          if (mounted) {
            setState(() {
              _currentState = AudioState.idle;
              _fullText = "";
              _recognizedText = "";
            });
          }
       });
     }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleSingleTap,
      onDoubleTap: _handleDoubleTap,
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade900, // Distinct color
        appBar: AppBar(
          title: const Text("AUDIO SCREEN"),
          backgroundColor: Colors.blueGrey,
          leading: VoiceAccessibleWidget(
            label: "Back",
            onTap: () {
              AccessibilityService().stopSpeaking();
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Text(
                 "AUDIO SCREEN",
                 style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 30),
               Icon(
                 _currentState == AudioState.recording ? Icons.mic : Icons.mic_none,
                 color: Colors.white,
                 size: 100,
               ),
               const SizedBox(height: 20),
               Text(
                 _currentState.toString().split('.').last.toUpperCase(),
                 style: const TextStyle(color: Colors.white, fontSize: 24),
               ),
               Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Text(
                   _recognizedText.isEmpty ? _fullText : "$_fullText $_recognizedText",
                   style: const TextStyle(color: Colors.white70),
                   textAlign: TextAlign.center,
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    AccessibilityService().stopSpeaking();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
