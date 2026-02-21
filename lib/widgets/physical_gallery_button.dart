import 'package:flutter/material.dart';

class PhysicalGalleryButton extends StatefulWidget {
  final VoidCallback onPressed;

  const PhysicalGalleryButton({super.key, required this.onPressed});

  @override
  State<PhysicalGalleryButton> createState() => _PhysicalGalleryButtonState();
}

class _PhysicalGalleryButtonState extends State<PhysicalGalleryButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 48,
        height: 36,
        margin: EdgeInsets.only(top: _isPressed ? 4.0 : 0.0), // Moves down when pressed
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A), // Dark plastic button color
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: Colors.black87,
            width: 1.5,
          ),
          boxShadow: _isPressed
              ? []
              : [
                  const BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 4), // Drop shadow simulates physical height
                    blurRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    offset: const Offset(0, -1), // Top highlight
                    blurRadius: 1,
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            Icons.photo_library,
            color: _isPressed ? Colors.white70 : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
