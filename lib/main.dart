import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'access.dart';
import 'audio.dart';
import 'file_screen.dart';
import 'condition_selection_screen.dart'; // Import

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: '/condition_selection', // New Initial Route
      routes: {
        '/condition_selection': (_) => const ConditionSelectionScreen(), // New Route
        '/login': (_) => const LoginScreen(),
        '/access': (_) => const AccessScreen(),
        '/camera': (_) => const MainScreen(),
        '/audio': (_) => const AudioScreen(),
        '/file': (_) => const FileScreen(),
      },
    );
  }
}
