import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../models/accessibility_profile.dart';
import '../common/voice_accessible_widget.dart';

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? questions;

  const QuizScreen({super.key, this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final AccessibilityService _service = AccessibilityService();
  int _currentQuestionIndex = 0;
  int _score = 0;

  // Dummy Data - In real app, fetch from service
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.questions ?? [
      {
        "question": "What allows screen readers to describe images?",
        "options": ["Alt Text", "Blue Light", "High Contrast"],
        "answer": 0
      },
      {
        "question": "Which font is designed for dyslexia?",
        "options": ["Times New Roman", "OpenDyslexic", "Arial"],
        "answer": 1
      },
      {
        "question": "What is the capital of France?",
        "options": ["London", "Berlin", "Paris"],
        "answer": 2
      },
    ];

    // Announce the first question on load if voice is on
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceQuestion();
    });
  }

  void _announceQuestion() {
    if (_service.currentProfile.voiceGuidanceEnabled) {
      final q = _questions[_currentQuestionIndex];
      String text = "Question ${_currentQuestionIndex + 1}. ${q['question']}. Options are: ";
      for (int i = 0; i < q['options'].length; i++) {
        text += "${q['options'][i]}. ";
      }
      _service.announce(text);
    }
  }

  void _answerQuestion(int selectedIndex) {
    if (selectedIndex == _questions[_currentQuestionIndex]['answer']) {
      _score++;
      if (_service.currentProfile.voiceGuidanceEnabled) {
        _service.announce("Correct!");
      }
    } else {
      if (_service.currentProfile.voiceGuidanceEnabled) {
        _service.announce("Incorrect.");
      }
    }

    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _announceQuestion(); // Announce next
      } else {
        // End of quiz
        _showScore();
      }
    });
  }

  void _showScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Quiz Complete"),
        content: Text("You scored $_score out of ${_questions.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _currentQuestionIndex = 0;
                _score = 0;
              });
              _announceQuestion();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
    if (_service.currentProfile.voiceGuidanceEnabled) {
      _service.announce("Quiz Complete. You scored $_score out of ${_questions.length}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: _service.profileNotifier,
      builder: (context, profile, child) {
        final bool isHighContrast = profile.highContrast;
        final Color backgroundColor = isHighContrast ? Colors.black : Colors.white;
        final Color textColor = isHighContrast ? Colors.white : Colors.black87;
        final Color optionColor = isHighContrast ? Colors.grey[900]! : Colors.blue.shade50;
        final Color correctColor = isHighContrast ? Colors.green : Colors.green.shade200; // Not used in this simple version yet

        final questionData = _questions[_currentQuestionIndex];
        final TextStyle fontStyle = TextStyle(
          fontFamily: profile.dyslexiaFont ? 'OpenDyslexic' : null,
          color: textColor,
          fontSize: 20 * profile.textScale,
        );

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text("Visual Quiz", style: TextStyle(color: textColor)),
            backgroundColor: isHighContrast ? Colors.black : Colors.blueAccent,
            iconTheme: IconThemeData(color: textColor),
            leading: VoiceAccessibleWidget(
              label: "Back",
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, color: textColor),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Question ${_currentQuestionIndex + 1}/${_questions.length}",
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                const SizedBox(height: 20),
                VoiceAccessibleWidget(
                  label: questionData['question'],
                  onTap: () => _service.announce(questionData['question']),
                  child: Text(
                    questionData['question'],
                    style: fontStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 24 * profile.textScale),
                  ),
                ),
                const SizedBox(height: 40),
                ...List.generate(questionData['options'].length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: VoiceAccessibleWidget(
                      label: questionData['options'][index],
                      isButton: true,
                      onTap: () => _answerQuestion(index),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: optionColor,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isHighContrast ? const BorderSide(color: Colors.white) : BorderSide.none,
                          ),
                        ),
                        onPressed: () => _answerQuestion(index),
                        child: Text(
                          questionData['options'][index],
                          style: fontStyle.copyWith(color: textColor),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
