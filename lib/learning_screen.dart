import 'package:flutter/material.dart';
import 'services/accessibility_service.dart';
import 'models/accessibility_profile.dart';
import 'common/voice_accessible_widget.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final AccessibilityService _service = AccessibilityService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: _service.profileNotifier,
      builder: (context, profile, child) {
        final bool isHighContrast = profile.highContrast;
        final Color backgroundColor = isHighContrast ? Colors.black : Colors.white;
        final Color textColor = isHighContrast ? Colors.white : Colors.black87;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text("Learning Center", style: TextStyle(color: textColor)),
            backgroundColor: isHighContrast ? Colors.black : Colors.teal,
            iconTheme: IconThemeData(color: textColor),
            elevation: 0,
            leading: VoiceAccessibleWidget(
              label: "Back to Dashboard",
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, color: textColor),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildLearningOption(
                context,
                title: "Audio Lessons",
                subtitle: "Listen and learn. Optimized for screen readers.",
                icon: Icons.headset,
                color: Colors.orange,
                route: '/learning/audio_lessons', // Placeholder for now
                profile: profile,
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Audio Lessons - Coming Soon")),
                   );
                }
              ),
              const SizedBox(height: 16),
              _buildLearningOption(
                context,
                title: "Visual Quizzes",
                subtitle: "High contrast quizzes with dyslexia support.",
                icon: Icons.quiz,
                color: Colors.blueAccent,
                route: '/learning/quiz', 
                profile: profile,
              ),
              const SizedBox(height: 16),
              _buildLearningOption(
                context,
                title: "Focus Session",
                subtitle: "Distraction-free flashcards.",
                icon: Icons.filter_center_focus,
                color: Colors.purpleAccent,
                route: '/learning/flashcards',
                profile: profile,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLearningOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
    required AccessibilityProfile profile,
    VoidCallback? onTap,
  }) {
    final bool isHighContrast = profile.highContrast;
    final Color cardColor = isHighContrast ? Colors.grey[900]! : color.withOpacity(0.1);
    final Color iconColor = isHighContrast ? Colors.white : color;
    final Color textColor = isHighContrast ? Colors.white : Colors.black87;

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isHighContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
      ),
      child: VoiceAccessibleWidget(
        label: "$title. $subtitle",
        isButton: true,
        onTap: onTap ?? () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: profile.dyslexiaFont ? 'OpenDyslexic' : null, // Assuming you might have this font asset, or it just falls back
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
