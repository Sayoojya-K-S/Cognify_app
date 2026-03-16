import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'services/accessibility_service.dart';
import 'services/ai_service.dart';
import 'learning/ai_result_screen.dart';
import 'learning/quiz_screen.dart';
import 'learning/history_screen.dart';

class TextDisplayScreen extends StatefulWidget {
  final String text;

  const TextDisplayScreen({super.key, required this.text});

  @override
  State<TextDisplayScreen> createState() => _TextDisplayScreenState();
}

class _TextDisplayScreenState extends State<TextDisplayScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final AIService _aiService = AIService();
  bool _isSpeaking = false;
  bool _isProcessing = false;
  List<String> _words = [];
  int _currentWordIndex = -1;

  @override
  void initState() {
    super.initState();
    _words = widget.text.split(RegExp(r'\s+'));
    _initTts();
  }

  Future<void> _initTts() async {
    final profile = AccessibilityService().currentProfile;
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(profile.pitch);
    await _flutterTts.setSpeechRate(profile.speechRate);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() {
        _isSpeaking = false;
        _currentWordIndex = -1;
      });
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() {
        _isSpeaking = false;
        _currentWordIndex = -1;
      });
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

    // Speak automatically ONLY if voice guidance is enabled
    if (profile.voiceGuidanceEnabled) {
      _speak();
    }
  }

  Future<void> _speak() async {
    if (widget.text.isNotEmpty) {
       // Reset word index
       if (mounted) setState(() => _currentWordIndex = -1);
       await _flutterTts.speak(widget.text);
    } else {
       await _flutterTts.speak("No text recognized.");
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _simplifyText() async {
    if (widget.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least 10 characters"))
      );
      return;
    }
    setState(() => _isProcessing = true);
    final result = await _aiService.simplifyText(widget.text);
    if (mounted) setState(() => _isProcessing = false);
    
    if (result != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (ctx) => AIResultScreen(result: result)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to simplify text.")));
    }
  }

  Future<void> _generateQuiz() async {
    if (widget.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least 10 characters"))
      );
      return;
    }
    setState(() => _isProcessing = true);
    final result = await _aiService.generateQuiz(widget.text);
    if (mounted) setState(() => _isProcessing = false);
    
    if (result != null && mounted) {
      final questions = result.quizQuestions.map((q) => {
        "question": q.question,
        "options": q.options,
        "answer": q.correctAnswerIndex,
      }).toList();
      Navigator.push(context, MaterialPageRoute(builder: (ctx) => QuizScreen(questions: questions)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to generate quiz.")));
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recognized Text"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _stop(); // Stop speaking when going back
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const HistoryScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: RichText(
                  textAlign: TextAlign.start,
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
                          fontSize: 24, // Larger font
                          height: 1.5,
                        ),
                      );
                    }).toList(),
                    style: const TextStyle(color: Colors.black, fontSize: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSpeaking ? _stop : _speak,
                        icon: Icon(_isSpeaking ? Icons.pause : Icons.play_arrow),
                        label: Text(_isSpeaking ? "Pause" : "Read Aloud"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _simplifyText,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("Simplify"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade100,
                          foregroundColor: Colors.purple.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _generateQuiz,
                        icon: const Icon(Icons.quiz),
                        label: const Text("Make Quiz"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
