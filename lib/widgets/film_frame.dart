import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

class FilmFrame extends StatelessWidget {
  final File file;
  final String dateString;
  final bool isPending;
  final VoidCallback? onTap;

  const FilmFrame({
    super.key,
    required this.file,
    required this.dateString,
    this.isPending = false,
    this.onTap,
  });

  Widget _buildSprocketHoles() {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          8,
          (index) => Container(
            width: 14,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.white10, width: 0.5),
            ),
          )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2A25), // Film base sepia dark gray
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        children: [
          _buildSprocketHoles(),
          Expanded(
            child: GestureDetector(
               onTap: isPending ? null : onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isPending)
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: ColorFiltered(
                          // Orange mask characteristic of color negative film
                          colorFilter: const ColorFilter.mode(
                            Color(0x88FF9933),
                            BlendMode.colorBurn,
                          ),
                          child: ColorFiltered(
                            // Invert colors
                            colorFilter: const ColorFilter.matrix(<double>[
                              -1,  0,  0, 0, 255,
                               0, -1,  0, 0, 255,
                               0,  0, -1, 0, 255,
                               0,  0,  0, 1,   0,
                            ]),
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                              cacheWidth: 100,
                            ),
                          ),
                        ),
                      )
                    else
                      Image.file(
                        file,
                        fit: BoxFit.cover,
                        cacheWidth: 600, 
                      ),
                    
                    if (!isPending)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Text(
                          dateString,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontFamily: 'Courier',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                          ),
                        ),
                      ),
                  ]
                ),
              ),
            ),
          ),
          _buildSprocketHoles(),
        ],
      ),
    );
  }
}
