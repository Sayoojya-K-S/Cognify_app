import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../models/accessibility_profile.dart';

class FocusWrapper extends StatelessWidget {
  final Widget child;
  final bool isEssential; // If true, this widget is ALWAYS shown even in Focus Mode

  const FocusWrapper({
    super.key,
    required this.child,
    this.isEssential = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService().profileNotifier,
      builder: (context, profile, _) {
        // If Focus Mode is OFF, show everything.
        if (!profile.focusMode) {
          return child;
        }

        // If Focus Mode is ON, only show essential widgets.
        if (isEssential) {
          return child;
        }

        // Otherwise (Focus ON + Non-Essential), hide it completely.
        return const SizedBox.shrink(); 
      },
    );
  }
}
