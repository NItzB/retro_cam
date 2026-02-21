import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import '../services/storage_service.dart';
import '../widgets/film_frame.dart';

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

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'DEVELOPED',
                    style: TextStyle(
                      color: Colors.orange,
                      fontFamily: 'Courier',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                SizedBox(
                  height: 240, // Ideal height for 260w 4:3 frame + sprockets
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final file = snapshot.data![index];
                      final dateString = _getDateFromFilename(file.path);
                      return FilmFrame(
                        file: file,
                        dateString: dateString,
                        isPending: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageScreen(
                                imageFile: file,
                                dateString: dateString,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
                  child: Text(
                    'DEVELOPING...',
                    style: TextStyle(
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
                  child: FutureBuilder<List<File>>(
                    future: _storageService.getPendingPhotos(),
                    builder: (context, pendingSnapshot) {
                      if (pendingSnapshot.connectionState == ConnectionState.waiting) {
                         return const Center(child: CircularProgressIndicator(color: Colors.orange));
                      }
                      if (!pendingSnapshot.hasData || pendingSnapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No film developing.',
                            style: TextStyle(color: Colors.white54, fontFamily: 'Courier'),
                          )
                        );
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pendingSnapshot.data!.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          return FilmFrame(
                            file: pendingSnapshot.data![index],
                            dateString: '---- -- --',
                            isPending: true,
                          );
                        },
                      );
                    }
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getDateFromFilename(String path) {
    try {
      // filename format: temp_img_123456789.jpg
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

class FullScreenImageScreen extends StatelessWidget {
  final File imageFile;
  final String dateString;

  const FullScreenImageScreen({
    super.key,
    required this.imageFile,
    required this.dateString,
  });

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      // Check and request permission using gal
      final requestGranted = await Gal.requestAccess(toAlbum: true);
      if (requestGranted) {
        
        await Gal.putImage(imageFile.path);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to Camera Roll!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery permission denied.')),
          );
        }
      }
    } on GalException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.type.message}')),
        );
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Save to Camera Roll',
            onPressed: () => _saveToGallery(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.file(
                imageFile,
                filterQuality: FilterQuality.low,
                // Downsample image slightly to prevent memory crashes on older iPhones
                cacheWidth: 2000, 
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Text(
                  dateString,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontFamily: 'Courier',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
