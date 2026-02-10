import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/accessibility_profile.dart';
import 'backend_service.dart';

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();

  factory AccessibilityService() {
    return _instance;
  }

  AccessibilityService._internal();

  final ValueNotifier<AccessibilityProfile> profileNotifier =
      ValueNotifier(const AccessibilityProfile());

  AccessibilityProfile get currentProfile => profileNotifier.value;

  final BackendService _backendService = BackendService();

  // Local storage cache
  AccessibilityProfile? _localProfile;
  // Backend storage cache
  AccessibilityProfile? _backendProfile;

  Future<void> initialize() async {
    await _loadLocalProfile();
    await _syncBackendProfile();
    _updateMergedProfile();

    // Listen to platform-level accessibility changes
    WidgetsBinding.instance.platformDispatcher.onAccessibilityFeaturesChanged = () {
      _updateMergedProfile();
    };
  }

  /// Loads locally saved preferences
  Future<void> _loadLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('accessibility_profile');
      if (jsonString != null) {
        _localProfile = AccessibilityProfile.fromJson(jsonDecode(jsonString));
      }
    } catch (e) {
      debugPrint("Error loading local accessibility profile: $e");
    }
  }

  /// Saves new settings locally and updates the effective profile
  Future<void> updateLocalSettings(AccessibilityProfile newSettings) async {
    _localProfile = newSettings;
    _updateMergedProfile(); // Update UI immediately

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessibility_profile', jsonEncode(newSettings.toJson()));
      
      // Optionally sync to backend
      _backendService.saveUserProfile(newSettings);
    } catch (e) {
      debugPrint("Error saving local accessibility profile: $e");
    }
  }

  /// Fetches from backend
  Future<void> _syncBackendProfile() async {
    try {
      // In a real app, you'd get the User ID from Auth Service
      _backendProfile = await _backendService.fetchUserProfile();
    } catch (e) {
      debugPrint("Error fetching backend profile: $e");
    }
  }

  /// Reads OS-level accessibility features
  AccessibilityProfile _getOSSettings() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final accessibility = dispatcher.accessibilityFeatures;

    return AccessibilityProfile(
      // Map OS features to our profile
      // Note: Flutter doesn't expose all OS toggles easily via Dispatcher,
      // but we can infer some.
      highContrast: accessibility.highContrast,
      textScale: dispatcher.textScaleFactor, // This is a bit different in newer Flutter, but good for now.
      voiceGuidanceEnabled: accessibility.accessibleNavigation, // TalkBack/VoiceOver often sets this
      // Other fields (speechRate, pitch, simplifyUI) usually don't have direct OS equivalents we can read passively
    );
  }

  /// The Core Logic: Merges Default < Backend < Local < OS
  void _updateMergedProfile() {
    AccessibilityProfile merged = AccessibilityProfile.defaults();

    // 1. Apply Backend (if exists)
    if (_backendProfile != null) {
      merged = merged.merge(_backendProfile);
    }

    // 2. Apply Local (User's manual overrides on this device)
    if (_localProfile != null) {
      merged = merged.merge(_localProfile);
    }

    // 3. Apply OS (System-wide settings should generally win for vital flags like High Contrast)
    // However, for things like 'textScale', we might want to respect the user's explicit in-app choice
    // if they made one. But adhering to "System Default" is usually expected.
    // For this implementation, we will let OS overrides rule for critical accessibility features.
    
    final osProfile = _getOSSettings();
    // We only want to merge *active* OS settings, not overwrite with defaults.
    // Since our 'merge' logic takes non-nulls, but our primitives are non-null with defaults,
    // we need to be careful.
    // A better approach for OS settings might be to only apply them if they are explicitly "ON".
    
    merged = merged.copyWith(
       highContrast: osProfile.highContrast ? true : merged.highContrast,
       // If OS defines a text scale != 1.0, use it, UNLESS local user set something specific?
       // Usually app scale * system scale = final scale.
       // Here we'll simplify and say if system has > 1.0, user probably needs it.
       textScale: osProfile.textScale > 1.0 ? osProfile.textScale : merged.textScale,
       
       // Voice guidance from OS (TalkBack) implies we should probably enable our voice features too
       voiceGuidanceEnabled: osProfile.voiceGuidanceEnabled ? true : merged.voiceGuidanceEnabled,
    );

    profileNotifier.value = merged;
    debugPrint("Accessibility Profile Updated: ${jsonEncode(merged.toJson())}");
  }
}
