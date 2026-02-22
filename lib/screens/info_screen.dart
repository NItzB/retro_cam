import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('HOW TO SHOOT', style: TextStyle(color: Colors.white, fontFamily: 'Courier')),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WELCOME TO RETROCAM',
              style: TextStyle(
                color: Colors.orange,
                fontFamily: 'Courier',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This camera mimics the beautiful, tactile experience of shooting vintage film cameras. Select iconic film stocks from different historical eras and shoot. There are no instant previews. No do-overs. Just raw moments.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            
            // Step 1
            _buildStep(
              icon: Icons.sync,
              title: 'STEP 1: THE WIND',
              description: 'Just like real film, you must physically advance the roll before every shot. Swipe the winding wheel on the bottom right from left to right until you hear it click into place.',
            ),
            const SizedBox(height: 32),
            
            // Step 2
            _buildStep(
              icon: Icons.camera,
              title: 'STEP 2: THE SHOT',
              description: 'You have a limited number of exposures per roll. Frame your shot in the compact viewfinder and tap the metallic shutter button on the top right.',
            ),
            const SizedBox(height: 32),

            // Step 3
            _buildStep(
              icon: Icons.hourglass_top,
              title: 'STEP 3: THE WAIT',
              description: 'When the roll is finished, the camera locks. Your photos are sent to our "virtual lab" to develop. You must wait for the development timer to finish before your photos are revealed in the Library.',
            ),
            const SizedBox(height: 48),

            Center(
              child: Text(
                'happy shooting.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontFamily: 'Courier',
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required IconData icon, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1),
          ),
          child: Icon(icon, color: Colors.orange, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Courier',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
