class AccessibilityProfile {
  final bool voiceGuidanceEnabled;
  final double speechRate;
  final double pitch;
  final bool highContrast;
  final double textScale;
  final bool simplifyUI;
  final bool dyslexiaFont; // New
  final bool focusMode; // New

  const AccessibilityProfile({
    this.voiceGuidanceEnabled = false,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.highContrast = false,
    this.textScale = 1.0,
    this.simplifyUI = false,
    this.dyslexiaFont = false,
    this.focusMode = false,
  });

  factory AccessibilityProfile.defaults() {
    return const AccessibilityProfile();
  }

  AccessibilityProfile copyWith({
    bool? voiceGuidanceEnabled,
    double? speechRate,
    double? pitch,
    bool? highContrast,
    double? textScale,
    bool? simplifyUI,
    bool? dyslexiaFont,
    bool? focusMode,
  }) {
    return AccessibilityProfile(
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
      simplifyUI: simplifyUI ?? this.simplifyUI,
      dyslexiaFont: dyslexiaFont ?? this.dyslexiaFont,
      focusMode: focusMode ?? this.focusMode,
    );
  }

  AccessibilityProfile merge(AccessibilityProfile? other) {
    if (other == null) return this;
    return copyWith(
      voiceGuidanceEnabled: other.voiceGuidanceEnabled,
      speechRate: other.speechRate,
      pitch: other.pitch,
      highContrast: other.highContrast,
      textScale: other.textScale,
      simplifyUI: other.simplifyUI,
      dyslexiaFont: other.dyslexiaFont,
      focusMode: other.focusMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voiceGuidanceEnabled': voiceGuidanceEnabled,
      'speechRate': speechRate,
      'pitch': pitch,
      'highContrast': highContrast,
      'textScale': textScale,
      'simplifyUI': simplifyUI,
      'dyslexiaFont': dyslexiaFont,
      'focusMode': focusMode,
    };
  }

  factory AccessibilityProfile.fromJson(Map<String, dynamic> json) {
    return AccessibilityProfile(
      voiceGuidanceEnabled: json['voiceGuidanceEnabled'] ?? false,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      highContrast: json['highContrast'] ?? false,
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      simplifyUI: json['simplifyUI'] ?? false,
      dyslexiaFont: json['dyslexiaFont'] ?? false,
      focusMode: json['focusMode'] ?? false,
    );
  }
}
