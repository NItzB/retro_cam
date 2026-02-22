import 'dart:math';
import 'package:flutter/material.dart';

class GrainOverlay extends StatefulWidget {
  final double opacity;
  
  const GrainOverlay({
    Key? key,
    this.opacity = 0.15,
  }) : super(key: key);

  @override
  State<GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<GrainOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  double _randomOffset = 0.0;

  @override
  void initState() {
    super.initState();
    // Run an extremely fast animation loop to change the grain position
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 50)
    )..addListener(() {
      setState(() {
         // Slightly shift the noise texture to create the "dancing" grain effect
        _randomOffset = _random.nextDouble() * 100;
      });
    })..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(_randomOffset % 5, _randomOffset % 5),
        child: Opacity(
          opacity: widget.opacity,
          child: CustomPaint(
            painter: _GrainPainter(),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  final Random _random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;
      
    // Because drawing thousands of points per frame is too slow in Flutter,
    // we use a noise shader or simply draw semi-transparent rectangles randomly.
    // For MVP, we draw a grid of semi-transparent dots to simulate grain.
    // To maintain 60FPS, we keep the dot count low and rely on the translation animation.
    
    for (int i = 0; i < 500; i++) {
        final x = _random.nextDouble() * size.width;
        final y = _random.nextDouble() * size.height;
        final dotSize = _random.nextDouble() * 2.0 + 0.5;
        canvas.drawRect(Rect.fromLTWH(x, y, dotSize, dotSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
