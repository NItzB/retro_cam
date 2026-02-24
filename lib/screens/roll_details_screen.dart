import 'package:flutter/material.dart';
import '../models/film_roll.dart';
import '../widgets/film_frame.dart';
import '../services/storage_service.dart';
import 'gallery_screen.dart';

class RollDetailsScreen extends StatefulWidget {
  final FilmRoll roll;

  const RollDetailsScreen({super.key, required this.roll});

  @override
  State<RollDetailsScreen> createState() => _RollDetailsScreenState();
}

class _RollDetailsScreenState extends State<RollDetailsScreen> {
  late FilmRoll _currentRoll;

  @override
  void initState() {
    super.initState();
    _currentRoll = widget.roll;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_currentRoll.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'PHOTOS (${_currentRoll.photos.length})',
                style: const TextStyle(
                  color: Colors.orange,
                  fontFamily: 'Courier',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            SizedBox(
              height: 240, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currentRoll.photos.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final file = _currentRoll.photos[index];
                  final dateString = _getDateFromFilename(file.path);
                  return FilmFrame(
                    file: file,
                    dateString: dateString,
                    isPending: false,
                    onTap: () async {
                      final bool? photoDeleted = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageScreen(
                            imageFile: file,
                            dateString: dateString,
                          ),
                        ),
                      );

                      if (photoDeleted == true && context.mounted) {
                         // Refresh the roll data
                         final storage = StorageService();
                         final rolls = await storage.getFilmRolls();
                         final updatedRollIndex = rolls.indexWhere((r) => r.id == _currentRoll.id);
                         
                         if (updatedRollIndex != -1) {
                           setState(() {
                             _currentRoll = rolls[updatedRollIndex];
                           });
                         } else {
                           // The roll was empty and got auto-deleted by StorageService
                           if (context.mounted) {
                             Navigator.pop(context, true); // Pop back to Library, tell it to refresh
                           }
                         }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateFromFilename(String path) {
    try {
      final filename = path.split('/').last;
      final parts = filename.split('_');
      final timestampStr = parts.last.split('.')[0];
      final timestamp = int.parse(timestampStr);
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return "'${date.year % 100} ${date.month.toString().padLeft(2, '0')} ${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }
}
