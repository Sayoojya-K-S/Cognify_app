import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'access.dart';
import 'audio.dart';
import 'file_screen.dart';
import 'condition_selection_screen.dart'; // Import
import 'feature_selection_screen.dart';
import 'services/accessibility_service.dart';
import 'models/accessibility_profile.dart'; // Explicit import if needed for types in main

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Accessibility Service
  final accessibilityService = AccessibilityService();
  await accessibilityService.initialize();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('CameraError: ${e.description}');
    cameras = [];
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognify: Text Recognition',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/condition_selection', // New Initial Route (Now Dashboard)
      routes: {
        '/condition_selection': (_) => const ConditionSelectionScreen(), // Renamed internally to Dashboard, but keeping route name
        '/feature_selection': (_) => const FeatureSelectionScreen(),
        // '/login': (_) => const LoginScreen(), // LoginScreen removed
        '/access': (_) => const AccessScreen(),
        '/camera': (_) => const MainScreen(),
        '/audio': (_) => const AudioScreen(),
        '/file': (_) => const FileScreen(),
      },
    );
  }
}
