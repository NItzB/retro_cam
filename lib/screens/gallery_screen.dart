import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class GalleryScreen extends StatelessWidget {
  final StorageService _storageService = StorageService();

  GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Developed Photos', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<File>>(
        future: _storageService.getDevelopedPhotos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No photos yet.', style: TextStyle(color: Colors.white)));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final file = snapshot.data![index];
              final dateString = _getDateFromFilename(file.path);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    file,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Text(
                      dateString,
                      style: TextStyle(
                        color: Colors.orange,
                        fontFamily: 'Courier',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _getDateFromFilename(String path) {
    try {
      // filename format: temp_img_123456789.dat
      final filename = path.split('/').last;
      final timestampStr = filename.split('_')[2].split('.')[0];
      final timestamp = int.parse(timestampStr);
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      // Format: '98 10 24' (Year Month Day retro style)
      return "'${date.year % 100} ${date.month.toString().padLeft(2, '0')} ${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }
}
