import 'package:flutter/material.dart';
import 'services/accessibility_service.dart';
import 'models/accessibility_profile.dart';
import 'common/voice_accessible_widget.dart';

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
            leading: VoiceAccessibleWidget(
              label: "Back",
              onTap: () {
                   // No dedicated TTS on this screen to stop, but good practice
                   Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back, color: textColor),
            ),
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
              _buildSectionHeader("Reading & Cognition", textColor),
              _buildSwitchTile(
                "Dyslexia Font",
                "Use OpenDyslexic-like font",
                profile.dyslexiaFont,
                (val) => _updateProfile(profile.copyWith(dyslexiaFont: val)),
                cardColor,
                textColor,
              ),
              _buildSwitchTile(
                "Focus Mode",
                "Hide non-essential elements",
                profile.focusMode,
                (val) => _updateProfile(profile.copyWith(focusMode: val)),
                cardColor,
                textColor,
              ),
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
      child: VoiceAccessibleWidget(
        label: "$title, ${value ? "On" : "Off"}. $subtitle",
        isButton: true,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13)),
                  ],
                ),
              ),
              IgnorePointer(
                child: Switch(
                  value: value,
                  onChanged: (val) {}, // Ignored, but keeps active color
                  activeColor: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
        ),
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
      child: VoiceAccessibleWidget(
        label: "$title, currently $valueLabel. Double tap to increase.",
        onTap: () {
          // Cycle value on normal tap? No, normal users expect slider.
          // But strict VoiceAccessibleWidget logic calls this onTap for Double Tap in VoiceMode.
          // For Normal Mode, we want the slider to be usable.
          
          // Hybrid approach:
          // In Voice Mode: Double Tap -> Increment
          // In Normal Mode: Tap -> nothing (let slider handle?), or Increment?
          // Since we wrap in VoiceAccessibleWidget, we control the top gesture.
          // If we want slider to work in normal mode, we can't wrap it directly in a GestureDetector that consumes everything.
          
          // Hack: Increase value by 10% step
          double newValue = value + ((max - min) / 5);
          if (newValue > max) newValue = min;
          onChanged(newValue);
        },
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
              // In Normal Mode, we want the slider to work.
              // VoiceAccessibleWidget wraps it.
              // If we use IgnorePointer on Slider, normal users can't drag.
              // If we don't, Voice users might get stuck in slider.
              // Solution: Check if Voice Mode is enabled globally?
              // VoiceAccessibleWidget receives 'onTap' which is only called for Single Tap (Normal) or Double Tap (Voice).
              // It doesn't block vertical/horizontal drags unless we tell it to.
              
              // Let's rely on the Slider for normal interaction, but wrap it for Voice Mode announcement area.
              // However, VoiceAccessibleWidget uses HitTestBehavior.opaque which might steal touches.
              // A simple cycle on double tap is a safe fallback for Voice Mode.
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
      ),
    );
  }
}
