import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.speak("Tap once to start recording.");
  }

  Future<void> _initSpeech() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
       await _tts.speak("Microphone permission denied.");
       return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (errorNotification) => print('onError: $errorNotification'),
    );
     if (!available) {
      await _tts.speak("Microphone not available.");
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
      // User wants to pause/continue?
      // Logic: If already recording, single tap might mean pause?
      // User said: "when sepeak it need to convert to text... if u need continue tap one"
      // So single tap from idle -> start.
      // Single tap from recording -> stop & prompt? Or generic pause?
      // Let's assume Single Tap toggles Pause/Resume if active?
      // Actually prompt says: "if u need continue tap one u need to tell these suitable time when you stoped"
      // So recording -> stop/pause.
       _pauseRecording();
    } else if (_currentState == AudioState.paused) {
      _resumeRecording();
    }
  }

  void _handleDoubleTap() {
    if (_currentState == AudioState.recording || _currentState == AudioState.paused) {
      _stopAndSaveFlow();
    }
  }

  Future<void> _startRecording() async {
     setState(() => _currentState = AudioState.recording);
     await _tts.speak("Listening.");
     await _tts.awaitSpeakCompletion(true);
     
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
     
     await _tts.speak("Paused. Tap once to continue. Double tap to save.");
  }
  
  Future<void> _resumeRecording() async {
      setState(() => _currentState = AudioState.recording);
      await _tts.speak("Resuming.");
      await _tts.awaitSpeakCompletion(true);
      
      _speech.listen(onResult: (val) {
         setState(() {
           _recognizedText = val.recognizedWords;
         });
       });
  }

  Future<void> _stopAndSaveFlow() async {
     setState(() => _currentState = AudioState.naming);
     _speech.stop();
      if (_recognizedText.isNotEmpty) {
       _fullText += "$_recognizedText ";
       _recognizedText = "";
     }
     
     await _tts.speak("Saving. Please say the filename now.");
     await _tts.awaitSpeakCompletion(true);
     
     // Listen for filename
     _speech.listen(onResult: (val) async {
        if (val.finalResult) {
           _speech.stop();
           String filename = val.recognizedWords.trim().replaceAll(' ', '_');
           if (filename.isEmpty) filename = "untitled_${DateTime.now().millisecondsSinceEpoch}";
           await _saveFile(filename);
        }
     });
     
     // Timeout if no name?
     Future.delayed(const Duration(seconds: 5), () {
        if (_speech.isListening) _speech.stop();
     });
  }
  
  Future<void> _saveFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$filename.txt';
    final file = File(path);
    
    if (await file.exists()) {
       await _tts.speak("File $filename already exists. Please say a different name.");
       await Future.delayed(const Duration(seconds: 1));
       _stopAndSaveFlow(); // Retry naming
    } else {
       await file.writeAsString(_fullText);
       await _tts.speak("File $filename saved. Tap once to start new recording.");
       setState(() {
         _currentState = AudioState.idle;
         _fullText = "";
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
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
