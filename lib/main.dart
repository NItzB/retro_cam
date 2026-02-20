import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const RetroCamApp());
}

class RetroCamApp extends StatelessWidget {
  const RetroCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetroCam',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const CameraScreen(),
    );
  }
}
