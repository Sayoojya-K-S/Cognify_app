import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConditionSelectionScreen extends StatefulWidget {
  const ConditionSelectionScreen({super.key});

  @override
  State<ConditionSelectionScreen> createState() => _ConditionSelectionScreenState();
}

class _ConditionSelectionScreenState extends State<ConditionSelectionScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    // Announce the screen purpose
    await _tts.speak("Welcome. Please select your condition. Blindness, Dyslexia, ADHD, or Autism.");
  }

  Future<void> _selectCondition(String condition) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_condition', condition);

    if (condition == 'Blindness') {
      await _tts.speak("Blindness selected. Enabling voice guidance.");
      await _tts.awaitSpeakCompletion(true);
    } else {
      await _tts.speak("$condition selected.");
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Widget _buildOption(String title, Color color, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectCondition(title),
        child: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Condition")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildOption("Blindness", Colors.black, Icons.visibility_off),
                  _buildOption("Dyslexia", Colors.blue, Icons.menu_book),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildOption("ADHD", Colors.orange, Icons.flash_on),
                  _buildOption("Autism", Colors.purple, Icons.psychology),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
