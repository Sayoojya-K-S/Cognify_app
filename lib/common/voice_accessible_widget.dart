import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../models/accessibility_profile.dart';

class VoiceAccessibleWidget extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;
  final bool isButton;

  const VoiceAccessibleWidget({
    super.key,
    required this.child,
    required this.label,
    required this.onTap,
    this.isButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService().profileNotifier,
      builder: (context, profile, child) {
        final bool isVoiceMode = profile.voiceGuidanceEnabled;

        return Semantics(
          label: label,
          button: isButton,
          excludeSemantics: isVoiceMode, // We handle announcements manually in Voice Mode
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isVoiceMode) {
                AccessibilityService().announce(label);
              } else {
                onTap();
              }
            },
            onDoubleTap: isVoiceMode 
                ? () {
                    // Provide feedback (haptic or sound could be added here)
                    onTap(); 
                  } 
                : null,
            child: this.child,
          ),
        );
      },
      child: child,
    );
  }
}
