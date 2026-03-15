import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../models/accessibility_profile.dart';

class DyslexiaFriendlyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const DyslexiaFriendlyText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService().profileNotifier,
      builder: (context, profile, child) {
        final double scale = profile.textScale;
        final bool isDyslexia = profile.dyslexiaFont;
        final bool isHighContrast = profile.highContrast;

        // Base style from arguments or defaults
        final TextStyle baseStyle = style ?? DefaultTextStyle.of(context).style;

        // Apply accessibility overrides
        final double effectiveFontSize = (baseStyle.fontSize ?? 14.0) * scale;
        
        // Dyslexia tweaks: 
        // - Heavy bottom weighted font (simulated here with spacing/weight if custom font not available)
        // - Increased letter spacing
        // - Increased word spacing
        // - Increased line height
        
        return Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: baseStyle.copyWith(
            fontSize: effectiveFontSize,
            // Use a clean sans-serif. 'Verdana' is often available, or fallback to default sans-serif.
            fontFamily: isDyslexia ? 'Verdana' : baseStyle.fontFamily,
            // Significantly increased letter spacing for clarity
            letterSpacing: isDyslexia ? 2.0 : baseStyle.letterSpacing,
            // Generous word spacing
            wordSpacing: isDyslexia ? 4.0 : baseStyle.wordSpacing,
            // Increased line height to avoid crowding
            height: isDyslexia ? 1.8 : baseStyle.height,
            // Slightly heavier weight for 'bottom heavy' feel and stability
            fontWeight: isDyslexia ? FontWeight.w600 : baseStyle.fontWeight,
            color: isHighContrast 
                ? (baseStyle.color == Colors.white ? Colors.black : Colors.white) // Invert if HC
                : baseStyle.color,
          ),
        );
      },
    );
  }
}
