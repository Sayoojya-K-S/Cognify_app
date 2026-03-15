import 'package:flutter/material.dart';
import '../models/ai_models.dart';
import '../services/accessibility_service.dart';
import '../models/accessibility_profile.dart';
import '../common/voice_accessible_widget.dart';

class AIResultScreen extends StatelessWidget {
  final SimplifyResponse result;
  
  const AIResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final AccessibilityService service = AccessibilityService();

    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: service.profileNotifier,
      builder: (context, profile, child) {
        final bool isHighContrast = profile.highContrast;
        final Color backgroundColor = isHighContrast ? Colors.black : Colors.white;
        final Color textColor = isHighContrast ? Colors.white : Colors.black87;
        
        final TextStyle fontStyle = TextStyle(
          fontFamily: profile.dyslexiaFont ? 'OpenDyslexic' : null,
          color: textColor,
          fontSize: 18 * profile.textScale,
        );

        final TextStyle titleStyle = fontStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 24 * profile.textScale,
        );

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text("Simplified Text", style: TextStyle(color: textColor)),
            backgroundColor: isHighContrast ? Colors.black : Colors.blueAccent,
            iconTheme: IconThemeData(color: textColor),
            leading: VoiceAccessibleWidget(
              label: "Back",
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, color: textColor),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VoiceAccessibleWidget(
                  label: "Summary: ${result.summary}",
                  onTap: () => service.announce("Summary: ${result.summary}"),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isHighContrast ? Colors.grey[900] : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isHighContrast ? Colors.white : Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Summary", style: titleStyle.copyWith(fontSize: 20 * profile.textScale)),
                        const SizedBox(height: 8),
                        Text(result.summary, style: fontStyle),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                VoiceAccessibleWidget(
                  label: "Simplified Reading: ${result.simplifiedText}",
                  onTap: () => service.announce(result.simplifiedText),
                  child: Text("Simplified Reading", style: titleStyle),
                ),
                const SizedBox(height: 8),
                SelectableText(result.simplifiedText, style: fontStyle.copyWith(height: 1.5)),
                const SizedBox(height: 24),
                VoiceAccessibleWidget(
                  label: "Key Notes",
                  onTap: () => service.announce("Key Notes"),
                  child: Text("Key Notes", style: titleStyle),
                ),
                const SizedBox(height: 8),
                ...result.bulletNotes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                  child: VoiceAccessibleWidget(
                    label: note,
                    onTap: () => service.announce(note),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("• ", style: titleStyle),
                        Expanded(child: SelectableText(note, style: fontStyle)),
                      ],
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
