import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShutterButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;

  const ShutterButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton> {
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
        if (widget.isEnabled && widget.onPressed != null) {
          widget.onPressed!();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Metallic looking gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isEnabled 
                ? [Colors.grey[200]!, Colors.grey[400]!, Colors.grey[600]!, Colors.grey[800]!] 
                : [Colors.grey[800]!, Colors.grey[900]!],
            stops: widget.isEnabled 
                ? const [0.0, 0.4, 0.6, 1.0]
                : const [0.0, 1.0],
          ),
          boxShadow: [
            // Drop shadow for 3D effect
            if (widget.isEnabled && !_isPressed)
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(4, 4),
                blurRadius: 5,
              ),
            // Inner highlight
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              offset: const Offset(-2, -2),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        // Inner indented circle
        child: Padding(
          padding: EdgeInsets.all(_isPressed ? 12.0 : 10.0), // Animate padding for press depth
          child: Container(
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               color: widget.isEnabled ? Colors.grey[300] : Colors.grey[800],
               boxShadow: [
                 if (!_isPressed)
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-1, -1),
                      blurRadius: 1,
                    ),
                 BoxShadow(
                   color: Colors.black.withOpacity(0.4),
                   offset: const Offset(1, 1),
                   blurRadius: 2,
                 )
               ]
             ),
          ),
        ),
      ),
    );
  }
}
