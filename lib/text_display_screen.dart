import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'services/accessibility_service.dart';
import 'services/ai_service.dart';
import 'learning/ai_result_screen.dart';
import 'learning/quiz_screen.dart';
import 'learning/history_screen.dart';
import 'models/accessibility_profile.dart';

class TextDisplayScreen extends StatefulWidget {
  final String text;
  final bool autoRead; // New parameter to control auto-reading

  const TextDisplayScreen({super.key, required this.text, this.autoRead = false});

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
    await _flutterTts.awaitSpeakCompletion(true); // Crucial for chunking long texts

    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (mounted) {
        setState(() {
          // Identify the word being spoken to highlight it
          int index = _words.indexOf(word, _currentWordIndex > 0 ? _currentWordIndex - 1 : 0);
          if (index != -1) {
            _currentWordIndex = index;
          }
        });
      }
    });

    // Speak automatically if either autoRead is explicit OR voice guidance is enabled
    if (widget.autoRead || profile.voiceGuidanceEnabled) {
      _speak();
    }
  }

  Future<void> _speak({bool resume = false}) async {
    if (widget.text.isEmpty) {
       await _flutterTts.speak("No text recognized.");
       return;
    }

    if (!resume) {
       if (mounted) setState(() => _currentWordIndex = -1);
    }

    if (mounted) setState(() {
       _isSpeaking = true;
    });

    int startIndex = _currentWordIndex > 0 ? _currentWordIndex : 0;
    String remainingText = _words.sublist(startIndex).join(' ');

    if (remainingText.trim().isEmpty) {
       if (mounted) setState(() {
         _isSpeaking = false;
         _currentWordIndex = -1;
       });
       return;
    }

    // Android TTS strictly limits maximum text length (around ~4000 chars).
    // The regular expression chunks the text effectively into ~3500 char blocks.
    final RegExp pattern = RegExp(r'.{1,3500}(?:\s|$)', dotAll: true);
    final Iterable<RegExpMatch> matches = pattern.allMatches(remainingText);

    bool wasInterrupted = false;

    for (final RegExpMatch match in matches) {
      if (!mounted || !_isSpeaking) {
         wasInterrupted = true;
         break;
      }
      final chunk = match.group(0);
      if (chunk != null && chunk.trim().isNotEmpty) {
         await _flutterTts.speak(chunk);
      }
    }

    if (mounted && _isSpeaking && !wasInterrupted) {
       setState(() {
         _isSpeaking = false;
         _currentWordIndex = -1;
       });
    }
  }

  Future<void> _pause() async {
    if (mounted) setState(() {
      _isSpeaking = false;
    });
    await _flutterTts.stop();
  }

  Future<void> _stop() async {
    if (mounted) setState(() {
      _isSpeaking = false;
      _currentWordIndex = -1;
    });
    await _flutterTts.stop();
  }

  Future<void> _simplifyText() async {
    if (widget.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least 10 characters"))
      );
      return;
    }
    setState(() => _isProcessing = true);
    
    try {
      final result = await _aiService.simplifyText(widget.text);
      if (mounted) setState(() => _isProcessing = false);
      
      if (result != null && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => AIResultScreen(result: result)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))
        );
      }
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text("Document Text", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: true,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ValueListenableBuilder<AccessibilityProfile>(
                        valueListenable: AccessibilityService().profileNotifier,
                        builder: (context, profile, child) {
                          return RichText(
                            textAlign: TextAlign.start,
                            text: TextSpan(
                              children: _words.asMap().entries.map((entry) {
                                int idx = entry.key;
                                String word = entry.value;
                                bool isHighlighted = idx == _currentWordIndex;

                                return TextSpan(
                                  text: '$word ',
                                  style: TextStyle(
                                    fontFamily: profile.dyslexiaFont ? 'OpenDyslexic' : null,
                                    color: isHighlighted ? Colors.white : Colors.black87,
                                    backgroundColor: isHighlighted ? Colors.blue.shade700 : Colors.transparent,
                                    fontSize: 22,
                                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                                    height: 1.6,
                                    letterSpacing: 0.3,
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSpeaking ? _pause : () => _speak(resume: _currentWordIndex > 0),
                            icon: Icon(_isSpeaking ? Icons.pause : Icons.play_arrow),
                            label: Text(_isSpeaking ? "Pause Reading" : (_currentWordIndex > 0 ? "Resume" : "Read Aloud")),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                        if (_currentWordIndex > 0 || _isSpeaking) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _stop,
                            icon: const Icon(Icons.stop),
                            label: const Text("Reset"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _simplifyText,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text("Simplify"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade50,
                              foregroundColor: Colors.purple.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _generateQuiz,
                            icon: const Icon(Icons.quiz),
                            label: const Text("Make Quiz"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade50,
                              foregroundColor: Colors.orange.shade800,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
               const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
