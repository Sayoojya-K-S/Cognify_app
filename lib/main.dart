import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_ocr_screen.dart'; 
import 'audio.dart';
import 'file_screen.dart';
import 'condition_selection_screen.dart'; 
import 'feature_selection_screen.dart';
import 'services/accessibility_service.dart';
import 'globals.dart';

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
      initialRoute: '/condition_selection',
      routes: {
        '/condition_selection': (_) => const ConditionSelectionScreen(),
        '/feature_selection': (_) => const FeatureSelectionScreen(),
        '/camera': (_) => const MainScreen(),
        '/audio': (_) => const AudioScreen(),
        '/file': (_) => const FileScreen(),
      },
    );
  }
}
