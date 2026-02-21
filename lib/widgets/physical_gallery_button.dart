import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhysicalGalleryButton extends StatefulWidget {
  final VoidCallback onPressed;

  const PhysicalGalleryButton({super.key, required this.onPressed});

  @override
  State<PhysicalGalleryButton> createState() => _PhysicalGalleryButtonState();
}

class _PhysicalGalleryButtonState extends State<PhysicalGalleryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Dark metallic outer ring
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[600]!, Colors.grey[800]!, Colors.black],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                offset: const Offset(3, 3),
                blurRadius: 4,
              ),
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              offset: const Offset(-1, -1),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        // Inner indented circle
        child: Padding(
          padding: EdgeInsets.all(_isPressed ? 6.0 : 4.0), // Animate padding for press depth
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[900], // Dark inner button
              border: Border.all(color: Colors.black, width: 1.5),
              boxShadow: [
                if (!_isPressed)
                  const BoxShadow(
                    color: Colors.white24,
                    offset: Offset(-1, -1),
                    blurRadius: 1,
                  ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.photo_library,
                color: _isPressed ? Colors.orange[800] : Colors.orange,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
