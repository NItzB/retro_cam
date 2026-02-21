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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Silver metallic outer ring
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[300]!, Colors.grey[400]!, Colors.grey[500]!],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(2, 2),
                blurRadius: 3,
              ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(-1, -1),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        // Inner indented circle
        child: Padding(
          padding: EdgeInsets.all(_isPressed ? 5.0 : 3.0), // Animate padding for press depth
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[400], // Silver inner button
              border: Border.all(color: Colors.grey[600]!, width: 1.0),
              boxShadow: [
                if (!_isPressed)
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-1, -1),
                    blurRadius: 1,
                  ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.photo_library,
                color: _isPressed ? Colors.black38 : Colors.black54,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
