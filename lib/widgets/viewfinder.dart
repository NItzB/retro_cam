import 'dart:io';
import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/camera_service.dart'; // To access the service instance if passed or needed, but likely controller is passed.

class Viewfinder extends StatelessWidget {
  final CameraController? controller;
  final Function(CameraMacOSController)? onMacosCameraCreated;
  const Viewfinder({
    super.key, 
    this.controller, 
    this.onMacosCameraCreated,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return Container(
        width: 200, // Wider for 4:3
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          // Complex Bezel Gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[800]!,
              Colors.black,
              Colors.black,
              Colors.grey[900]!,
            ],
            stops: const [0.0, 0.4, 0.6, 1.0],
          ),
          boxShadow: [
            // Deep shadow for projection off the camera body
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(6, 6),
            ),
            // Light reflection on top edge
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12), // Inner padding for "step down" effect
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2), // Inner Matte
            boxShadow: [
               const BoxShadow(color: Colors.black, blurRadius: 4) // Simulated inner shadow not supported by default BoxShadow
            ]
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
            children: [
              Positioned.fill(
                child: CameraMacOSView(
                  fit: BoxFit.cover,
                  cameraMode: CameraMacOSMode.photo,
                  onCameraInizialized: (CameraMacOSController macosController) {
                    if (onMacosCameraCreated != null) {
                      onMacosCameraCreated!(macosController);
                    }
                  },
                ),
              ),
              // Reflection Overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    'assets/textures/lens_reflection.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    }

    return Container(
      width: 200,
      height: 150, // 4:3 Aspect Ratio approx
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        // Complex Bezel Gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.black,
            Colors.black,
            Colors.grey[900]!,
          ],
          stops: const [0.0, 0.4, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 12,
            offset: const Offset(6, 6),
          ),
           BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
          children: [
            Positioned.fill(
              child: controller != null && controller!.value.isInitialized
                  ? CameraPreview(controller!)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            // Reflection Overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/textures/lens_reflection.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
