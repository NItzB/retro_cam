import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class WindingLever extends StatefulWidget {
  final VoidCallback onWindComplete;
  final bool isWound;

  const WindingLever({
    super.key,
    required this.onWindComplete,
    required this.isWound,
  });

  @override
  State<WindingLever> createState() => _WindingLeverState();
}

class _WindingLeverState extends State<WindingLever> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0.0;
  final double _maxDrag = 90.0; // Reduced drag distance
  final double _triggerThreshold = 60.0; // Distance to trigger wind
  double _lastHapticExtent = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
    );

    _controller.addListener(() {
      setState(() {
        _dragExtent = _animation.value; 
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.isWound || _controller.isAnimating) return;

    setState(() {
      _dragExtent += details.delta.dx;
      if (_dragExtent < 0) _dragExtent = 0;
      if (_dragExtent > _maxDrag) _dragExtent = _maxDrag;

      if ((_dragExtent - _lastHapticExtent).abs() > 10.0) {
        HapticFeedback.selectionClick();
        _lastHapticExtent = _dragExtent;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isWound || _controller.isAnimating) return;
    
    _lastHapticExtent = 0.0;

    if (_dragExtent >= _triggerThreshold) {
      _runSnapBackAnimation();
      widget.onWindComplete();
    } else {
      _runSnapBackAnimation();
    }
  }

  void _runSnapBackAnimation() {
    _animation = Tween<double>(begin: _dragExtent, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)
    );
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140, // Shorter lever to fit the row
      height: 45,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Track / Slot
          Container(
            width: 100, // Correspondingly shorter track
            height: 6, // Thinner slot
            margin: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                 BoxShadow(color: Colors.white.withOpacity(0.1), offset: const Offset(0,1), blurRadius: 0),
                 BoxShadow(color: Colors.black.withOpacity(0.8), offset: const Offset(0,-1), blurRadius: 1)
              ]
            ),
          ),
          
          // "WIND" Label
          if (!widget.isWound)
            Positioned(
              left: 30, // Inside the track area
              child: Opacity(
                opacity: 0.3,
                child: Row(
                  children: [
                    const Text("WIND", style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ),

          // The Lever Handle
          Positioned(
            left: _dragExtent, // Starts at 0
            child: GestureDetector(
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              child: Container(
                width: 50,
                height: 45,
                color: Colors.transparent, // Hit area
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lever Arm / Handle
                    Transform.rotate(
                      angle: 0.1, // Slight tilt
                      child: Container(
                        width: 45,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(4), right: Radius.circular(12)),
                          gradient: LinearGradient(
                            colors: [Colors.grey[800]!, Colors.black],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(2,4), blurRadius: 3)
                          ],
                          border: Border.all(color: Colors.grey[800]!, width: 1)
                        ),
                        child: Center(
                          // Grip ridges
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:List.generate(3, (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 2,
                              height: 20,
                              color: Colors.black54,
                            )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
