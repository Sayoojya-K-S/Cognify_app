import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

enum FileState { idle, listening, searching, reading, notFound }

class _FileScreenState extends State<FileScreen> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  FileState _currentState = FileState.idle;
  String _statusText = "Initializing...";
  String _content = "";

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
    await _tts.speak("File Access. Tap once to search for a file.");
    if (mounted) setState(() => _statusText = "Tap to Search");
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    await _speech.initialize();
  }

  void _handleTap() {
    if (_currentState == FileState.idle || _currentState == FileState.notFound) {
      _startListening();
    } else if (_currentState == FileState.reading) {
      _tts.stop();
      setState(() {
        _currentState = FileState.idle;
        _statusText = "Tap to Search";
      });
      _tts.speak("Stopped. Tap to search again.");
    }
  }
  
  void _handleDoubleTap() {
     if (_currentState == FileState.reading) {
        _tts.stop();
        setState(() {
          _currentState = FileState.idle;
          _statusText = "Tap to Search";
        });
        _tts.speak("Stopped. Tap to search again.");
     }
  }

  Future<void> _startListening() async {
    setState(() {
      _currentState = FileState.listening;
      _statusText = "Listening...";
    });
    
    await _tts.speak("Say filename to find.");
    await _tts.awaitSpeakCompletion(true);

    _speech.listen(onResult: (val) async {
      if (val.finalResult) {
        String query = val.recognizedWords.trim().replaceAll(' ', '_');
        _searchFile(query);
      }
    });
  }

  Future<void> _searchFile(String filename) async {
    setState(() {
      _currentState = FileState.searching;
      _statusText = "Searching for $filename...";
    });

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$filename.txt';
    final file = File(path);

    if (await file.exists()) {
      String content = await file.readAsString();
      setState(() {
        _currentState = FileState.reading;
        _statusText = "Reading $filename";
        _content = content;
      });
      await _tts.speak("File $filename found. Reading content.");
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(content);
    } else {
      setState(() {
        _currentState = FileState.notFound;
        _statusText = "File Not Found";
      });
      await _tts.speak("File $filename not found. Tap to try again.");
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      child: Scaffold(
        backgroundColor: Colors.brown.shade900, // Distinct color for File Screen
        appBar: AppBar(
          title: const Text("FILE ACCESS"),
          backgroundColor: Colors.brown,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 const Text(
                   "FILE ACCESS",
                   style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                 ),
                 const SizedBox(height: 30),
                 Icon(
                   _currentState == FileState.listening ? Icons.mic : Icons.folder,
                   color: Colors.white,
                   size: 80,
                 ),
                 const SizedBox(height: 20),
                 Text(
                   _statusText,
                   textAlign: TextAlign.center,
                   style: const TextStyle(color: Colors.white, fontSize: 24),
                 ),
                 const SizedBox(height: 20),
                 if (_currentState == FileState.reading)
                   Expanded(
                     child: SingleChildScrollView(
                       child: Text(
                         _content,
                         style: const TextStyle(color: Colors.white70, fontSize: 18),
                       ),
                     ),
                   ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
