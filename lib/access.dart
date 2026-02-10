import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final FlutterTts _tts = FlutterTts();

  bool _isListeningForTap = false;
  String _currentOption = "";

  String _statusText = "Initializing...";
  String _loopingText = "";

  @override
  void initState() {
    super.initState();
    _initTts().then((_) {
      if (mounted) _startVoiceFlow();
    });
  }

  // -------------------- TTS SETUP --------------------
  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  // -------------------- VOICE FLOW --------------------
  Future<void> _startVoiceFlow() async {
    if (!mounted) return;

    setState(() {
      _statusText = "Which access do you need?";
      _loopingText = "";
    });

    await _tts.speak("Which access do you need?");
    await Future.delayed(const Duration(seconds: 1));

    await _speakAndListen("If you want camera, tap now.", "camera");
    if (!mounted) return;

    await _speakAndListen("If you want audio, tap now.", "audio");
    if (!mounted) return;

    await _speakAndListen("If you want file access, tap now.", "file");
    if (!mounted) return;

    // No selection detected → repeat
    setState(() {
      _statusText = "No selection detected";
      _loopingText = "Repeating options...";
    });

    await _tts.speak("No selection detected. Repeating options.");
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) _startVoiceFlow();
  }

  // -------------------- SPEAK + LISTEN --------------------
  Future<void> _speakAndListen(String text, String option) async {
    if (!mounted) return;

    _currentOption = option;
    _isListeningForTap = true; // Enable tap immediately!

    setState(() {
      _statusText = "Asking for access";
      _loopingText = "Current option: ${option.toUpperCase()}";
    });

    // Start speaking (don't await completion to block the slot, just start it)
    _tts.speak(text);

    // Give a fixed 6-second window for this option (Speech takes ~3s, + 3s wait)
    // This ensures code and audio stay in sync.
    await Future.delayed(const Duration(seconds: 6));

    // Check mounted again before disabling
    if (mounted) _isListeningForTap = false;
  }

  // -------------------- TAP HANDLER --------------------
  void _handleTap() async {
    if (!_isListeningForTap) return;

    _isListeningForTap = false;
    await _tts.stop();

    setState(() {
      _statusText = "Selected option";
      _loopingText = _currentOption.toUpperCase();
    });

    await _tts.speak("Selected $_currentOption");
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    switch (_currentOption) {
      case "camera":
        Navigator.pushReplacementNamed(context, '/camera');
        break;
      case "audio":
        Navigator.pushReplacementNamed(context, '/audio');
        break;
      case "file":
        Navigator.pushReplacementNamed(context, '/file');
        break;
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Voice controlled access selection screen. Tap anywhere to select.",
      focusable: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _loopingText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
