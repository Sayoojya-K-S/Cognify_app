class AccessibilityProfile {
  final bool voiceGuidanceEnabled;
  final double speechRate;
  final double pitch;
  final bool highContrast; // Replaces visual impairment specific condition
  final double textScale;
  final bool simplifyUI; // Replaces cognitive load specific conditions (ADHD/Autism)

  const AccessibilityProfile({
    this.voiceGuidanceEnabled = false,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.highContrast = false,
    this.textScale = 1.0,
    this.simplifyUI = false,
  });

  /// standard defaults for a fresh install
  factory AccessibilityProfile.defaults() {
    return const AccessibilityProfile();
  }

  /// Copy with logic for partial updates
  AccessibilityProfile copyWith({
    bool? voiceGuidanceEnabled,
    double? speechRate,
    double? pitch,
    bool? highContrast,
    double? textScale,
    bool? simplifyUI,
  }) {
    return AccessibilityProfile(
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
      simplifyUI: simplifyUI ?? this.simplifyUI,
    );
  }

  /// Merges another profile into this one.
  /// Non-null values in [other] override values in [this].
  AccessibilityProfile merge(AccessibilityProfile? other) {
    if (other == null) return this;
    return copyWith(
      voiceGuidanceEnabled: other.voiceGuidanceEnabled,
      speechRate: other.speechRate,
      pitch: other.pitch,
      highContrast: other.highContrast,
      textScale: other.textScale,
      simplifyUI: other.simplifyUI,
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
    );
  }
}
