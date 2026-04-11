import 'package:flutter/material.dart';
import 'services/accessibility_service.dart';
import 'models/accessibility_profile.dart';
import 'common/voice_accessible_widget.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AccessibilityService service = AccessibilityService();

    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: service.profileNotifier,
      builder: (context, profile, child) {
        final bool isHighContrast = profile.highContrast;
        final Color backgroundColor = isHighContrast ? Colors.black : Colors.grey[100]!;
        final Color cardColor = isHighContrast ? Colors.grey[900]! : Colors.white;
        final Color textColor = isHighContrast ? Colors.white : Colors.black87;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text("Help Center & Manual", style: TextStyle(color: textColor)),
            backgroundColor: isHighContrast ? Colors.black : Colors.green,
            iconTheme: IconThemeData(color: textColor),
            elevation: 0,
            leading: VoiceAccessibleWidget(
              label: "Back",
              onTap: () {
                service.stopSpeaking();
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back, color: textColor),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader("Welcome to Cognify", textColor),
              _buildInfoCard(
                "Cognify is a cognitive learning assistant designed to adapt texts and provide tools such as simplification, text-to-speech, and quizzes to support learning capabilities. Explore the features below:",
                cardColor,
                textColor,
                service,
              ),
              const SizedBox(height: 20),
              
              _buildSectionHeader("How to Use Features", textColor),
              _buildGuideCard(
                "Camera OCR",
                "Use the Camera tool to take pictures of physical documents, worksheets, or books. Ensure good lighting. Once captured, the text will be digitized so it can be read aloud, simplified, or converted to a quiz.",
                Icons.camera_alt,
                Colors.blue,
                cardColor,
                textColor,
                service,
              ),
              _buildGuideCard(
                "Audio Recording",
                "Navigate to Audio to dictate or record speech. Tap once to start listening, and tap again to finish. The spoken audio is converted to text which you can process exactly like a scanned document.",
                Icons.audiotrack,
                Colors.orange,
                cardColor,
                textColor,
                service,
              ),
              _buildGuideCard(
                "File Upload",
                "In the File section, you can select PDFs or Text files stored on your device. Cognify will extract the raw text, making it accessible for text-to-speech reading or AI simplification.",
                Icons.folder,
                Colors.brown,
                cardColor,
                textColor,
                service,
              ),
              _buildGuideCard(
                "Text Simplification & Quizzes",
                "After scanning a document, uploading a file, or capturing audio, you can tap the 'Simplify' button to receive an easy-to-read summary and bullet points. Alternatively, tap 'Make Quiz' to generate testing materials.",
                Icons.auto_awesome,
                Colors.purple,
                cardColor,
                textColor,
                service,
              ),
              
              const SizedBox(height: 20),
              
              _buildSectionHeader("Customizing your Experience", textColor),
              _buildGuideCard(
                "Accessibility Profile",
                "In the 'Customize Features' menu, you can toggle High Contrast, change to an OpenDyslexic font, adjust the Voice Guidance speed/pitch, and turn on Focus Mode to prevent other apps from distracting you while working.",
                Icons.accessibility_new,
                Colors.deepPurple,
                cardColor,
                textColor,
                service,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text, Color cardColor, Color textColor, AccessibilityService service) {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: VoiceAccessibleWidget(
        label: text,
        onTap: () => service.announce(text),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            text,
            style: TextStyle(fontSize: 16, color: textColor, height: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard(String title, String description, IconData icon, Color iconColor, Color cardColor, Color textColor, AccessibilityService service) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: VoiceAccessibleWidget(
        label: "$title. $description",
        onTap: () => service.announce("$title. $description"),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(fontSize: 15, color: textColor.withOpacity(0.9), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
