import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WindingWheel extends StatefulWidget {
  final VoidCallback onWindComplete;
  final bool isWound;

  const WindingWheel({
    super.key,
    required this.onWindComplete,
    required this.isWound,
  });

  @override
  State<WindingWheel> createState() => _WindingWheelState();
}

class _WindingWheelState extends State<WindingWheel> {
  double _scrollPosition = 0.0;
  final double _targetScroll = 100.0; // Distance to scroll to complete wind

  void _handleScroll(DragUpdateDetails details) {
    if (widget.isWound) return;

    setState(() {
      _scrollPosition -= details.delta.dx; // Horizontal scroll
      if (_scrollPosition < 0) _scrollPosition = 0;
      if (_scrollPosition >= _targetScroll) {
        _scrollPosition = 0; // Reset for next time
        widget.onWindComplete();
        // HapticFeedback.heavyImpact(); // Removed per user request
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleScroll,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Base dial color
          color: const Color(0xFF111111),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Transform.rotate(
            angle: _scrollPosition * 0.1, // Rotate based on drag
            child: Stack(
              children: [
                // Texture
                Positioned.fill(
                  child: Image.asset(
                    'assets/textures/plastic_texture.png',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.8),
                    colorBlendMode: BlendMode.hardLight,
                  ),
                ),
                // Ridges / Serrations simulation (radial lines)
                 CustomPaint(
                   painter: WheelRidgePainter(),
                   child: Container(),
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WheelRidgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 36; i++) {
        final angle = (i * 10) * 3.14159 / 180;
        canvas.drawLine(
          Offset(center.dx + (radius - 10) * cos(angle), center.dy + (radius - 10) * sin(angle)),
          Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
          paint
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WheelPainter extends CustomPainter {
  final double offset;
  final bool isLocked;

  WheelPainter({required this.offset, required this.isLocked});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isLocked ? Colors.grey[600]! : Colors.grey[400]!
      ..strokeWidth = 2;

    // Draw ridges
    for (double i = 0; i < size.width; i += 10) {
      double x = (i - offset) % size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) => 
      offset != oldDelegate.offset || isLocked != oldDelegate.isLocked;
}
