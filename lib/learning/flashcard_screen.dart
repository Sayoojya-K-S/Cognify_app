import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../models/accessibility_profile.dart';
import '../common/voice_accessible_widget.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final AccessibilityService _service = AccessibilityService();
  int _currentIndex = 0;
  bool _isFlipped = false;

  final List<Map<String, String>> _flashcards = [
    {"front": "A in Apple", "back": "Apple is a red fruit."},
    {"front": "B in Ball", "back": "A ball is round and bounces."},
    {"front": "C in Cat", "back": "A cat is a small furry pet."},
  ];

  void _nextCard() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _flashcards.length;
      _isFlipped = false;
    });
    _announceCard();
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
    if (_service.currentProfile.voiceGuidanceEnabled) {
      _service.announce(_isFlipped ? _flashcards[_currentIndex]['back']! : _flashcards[_currentIndex]['front']!);
    }
  }

  void _announceCard() {
    if (_service.currentProfile.voiceGuidanceEnabled) {
      _service.announce("Card ${_currentIndex+1}. ${_flashcards[_currentIndex]['front']}. Double tap to flip.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: _service.profileNotifier,
      builder: (context, profile, child) {
        final bool isHighContrast = profile.highContrast;
        final bool isFocusMode = profile.focusMode;
        
        final Color backgroundColor = isHighContrast ? Colors.black : (isFocusMode ? Colors.grey[100]! : Colors.purple.shade50);
        final Color cardColor = isHighContrast ? Colors.grey[900]! : Colors.white;
        final Color textColor = isHighContrast ? Colors.white : Colors.black;

        return Scaffold(
          backgroundColor: backgroundColor,
          // In Focus Mode, hide the AppBar or make it very minimal
          appBar: isFocusMode 
              ? null 
              : AppBar(
                  title: Text("Flashcards", style: TextStyle(color: textColor)),
                  backgroundColor: isHighContrast ? Colors.black : Colors.purpleAccent,
                  iconTheme: IconThemeData(color: textColor),
                ),
          body: SafeArea(
            child: Column(
              children: [
                if (isFocusMode)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Minimal exit button for Focus Mode
                        IconButton(
                          icon: Icon(Icons.close, color: textColor.withOpacity(0.5)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text("${_currentIndex + 1}/${_flashcards.length}", style: TextStyle(color: textColor.withOpacity(0.5))),
                      ],
                    ),
                  ),

                Expanded(
                  child: Center(
                    child: VoiceAccessibleWidget(
                      label: "Flashcard. ${_isFlipped ? _flashcards[_currentIndex]['back'] : _flashcards[_currentIndex]['front']}. Double tap to flip. Swipe left for next.",
                      isButton: true,
                      onTap: _flipCard, 
                      child: GestureDetector(
                        onTap: _flipCard,
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! < 0) {
                            _nextCard(); // Swipe Left -> Next
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(32),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                            border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isFlipped ? _flashcards[_currentIndex]['back']! : _flashcards[_currentIndex]['front']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: profile.dyslexiaFont ? 'OpenDyslexic' : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _isFlipped ? "(Tap to flip back)" : "(Tap to see answer)",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Keep Next button visible even in Focus Mode for ease of use, but make it minimal
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: VoiceAccessibleWidget(
                    label: "Next Card",
                    isButton: true,
                    onTap: _nextCard,
                    child: ElevatedButton.icon(
                      onPressed: _nextCard,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Next Card"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHighContrast ? Colors.grey[800] : Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
