import 'package:flutter/material.dart';

class FilmCounter extends StatelessWidget {
  final int count;

  const FilmCounter({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(6),
        // Bevel effect
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            offset: const Offset(-1, -1),
            blurRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            offset: const Offset(1, 1),
            blurRadius: 2,
          )
        ],
        border: Border.all(color: Colors.black, width: 2), // Dark rim
      ),
      child: Container(
        // inner window glass effect
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
           color: const Color(0xFF151515),
           borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          count.toString().padLeft(2, '0'),
          style: TextStyle(
            color: Colors.orange[700],
            fontFamily: 'Courier', 
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            shadows: [
              Shadow(color: Colors.orange.withOpacity(0.5), blurRadius: 4), // Glow
            ]
          ),
        ),
      ),
    );
  }
}
