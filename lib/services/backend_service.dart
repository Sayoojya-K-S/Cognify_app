import '../models/accessibility_profile.dart';

class BackendService {
  // Simulating a delay for network request
  Future<AccessibilityProfile?> fetchUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Return null to simulate no remote profile found initially.
    // In a real app, this would look up the user in Firestore/Database.
    return null;
  }

  Future<void> saveUserProfile(AccessibilityProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock save
    // print("Saved profile to backend: ${profile.toJson()}");
  }
}
