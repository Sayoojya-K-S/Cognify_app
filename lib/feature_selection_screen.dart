import 'package:flutter/material.dart';
import 'services/accessibility_service.dart';
import 'models/accessibility_profile.dart';

class FeatureSelectionScreen extends StatefulWidget {
  const FeatureSelectionScreen({super.key});

  @override
  State<FeatureSelectionScreen> createState() => _FeatureSelectionScreenState();
}

class _FeatureSelectionScreenState extends State<FeatureSelectionScreen> {
  final AccessibilityService _service = AccessibilityService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: _service.profileNotifier,
      builder: (context, profile, child) {
        // Apply high contrast override for this screen itself if needed
        final bool isHighContrast = profile.highContrast;
        final Color backgroundColor = isHighContrast ? Colors.black : Colors.grey[100]!;
        final Color cardColor = isHighContrast ? Colors.grey[900]! : Colors.white;
        final Color textColor = isHighContrast ? Colors.white : Colors.black87;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text("Customize Features", style: TextStyle(color: textColor)),
            backgroundColor: isHighContrast ? Colors.black : Colors.deepPurple,
            iconTheme: IconThemeData(color: textColor),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader("Visual", textColor),
              _buildSwitchTile(
                "High Contrast",
                "Increase color contrast for better visibility",
                profile.highContrast,
                (val) => _updateProfile(profile.copyWith(highContrast: val)),
                cardColor,
                textColor,
              ),
              _buildSliderTile(
                "Text Scale",
                "${profile.textScale.toStringAsFixed(1)}x",
                profile.textScale,
                0.5,
                2.0,
                (val) => _updateProfile(profile.copyWith(textScale: val)),
                cardColor,
                textColor,
              ),

              const SizedBox(height: 20),
              _buildSectionHeader("Audio", textColor),
              _buildSwitchTile(
                "Voice Guidance",
                "Enable spoken feedback and commands",
                profile.voiceGuidanceEnabled,
                (val) => _updateProfile(profile.copyWith(voiceGuidanceEnabled: val)),
                cardColor,
                textColor,
              ),
              _buildSliderTile(
                "Speech Rate",
                "${profile.speechRate.toStringAsFixed(1)}x",
                profile.speechRate,
                0.1,
                1.0,
                (val) => _updateProfile(profile.copyWith(speechRate: val)),
                cardColor,
                textColor,
              ),
              _buildSliderTile(
                "Pitch",
                "${profile.pitch.toStringAsFixed(1)}x",
                profile.pitch,
                0.5,
                2.0,
                (val) => _updateProfile(profile.copyWith(pitch: val)),
                cardColor,
                textColor,
              ),

              const SizedBox(height: 20),
              _buildSectionHeader("Cognitive", textColor),
              _buildSwitchTile(
                "Simplify UI",
                "Reduce distractions and simplifiy layout",
                profile.simplifyUI,
                (val) => _updateProfile(profile.copyWith(simplifyUI: val)),
                cardColor,
                textColor,
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateProfile(AccessibilityProfile newProfile) {
    _service.updateLocalSettings(newProfile);
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Color cardColor,
    Color textColor,
  ) {
    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurpleAccent,
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String valueLabel,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    Color cardColor,
    Color textColor,
  ) {
    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                Text(valueLabel, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: 15,
              onChanged: onChanged,
              activeColor: Colors.deepPurpleAccent,
            ),
          ],
        ),
      ),
    );
  }
}
