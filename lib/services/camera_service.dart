import 'dart:io';
import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb logic if needed, but mainly for Platform check

class CameraService {
  CameraController? _controller;
  CameraMacOSController? _macosController;
  List<CameraDescription>? _cameras;

  CameraController? get controller => _controller;
  CameraMacOSController? get macosController => _macosController;

  void setMacosController(CameraMacOSController controller) {
    _macosController = controller;
  }

  Future<void> initialize() async {
    if (Platform.isMacOS) {
      // macOS camera is initialized by the view
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use the first camera (backend)
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium, // Retro quality
          enableAudio: false,
        );
        await _controller!.initialize();
      }
    } catch (e) {
      print('Error initializing camera: $e');
      // Set controller to null or handle error state if needed
      _controller = null;
    }
  }

  Future<XFile?> takePicture() async {
    if (Platform.isMacOS) {
      if (_macosController == null) return null;
      try {
        final CameraMacOSFile? result = await _macosController!.takePicture();
        if (result != null && result.bytes != null) {
          // Identify a temp path to save the bytes
          final tempDir = Directory.systemTemp;
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final File file = File('${tempDir.path}/temp_capture_$timestamp.jpg');
          await file.writeAsBytes(result.bytes!);
          return XFile(file.path);
        }
        return null;
      } catch (e) {
        print('Error taking picture on macOS: $e');
        return null;
      }
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    if (_controller!.value.isTakingPicture) {
      return null;
    }
    try {
      return await _controller!.takePicture();
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
    // macosController typically doesn't need explicit dispose if managed by view, 
    // but check package docs if needed. usually it's tied to view lifecycle.
  }
}
