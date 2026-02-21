import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import '../services/storage_service.dart';
import '../widgets/film_frame.dart';

import '../models/film_roll.dart';
import 'roll_details_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final StorageService _storageService = StorageService();

  void _renameRoll(FilmRoll roll) {
    final TextEditingController controller = TextEditingController(text: roll.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Film Roll'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter roll name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
             onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                    await _storageService.renameFilmRoll(roll.id, newName);
                    setState(() {});
                }
                Navigator.pop(context);
             },
             child: const Text('Save'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Photo Library', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Developing Section
            FutureBuilder<List<File>>(
              future: _storageService.getPendingPhotos(),
              builder: (context, pendingSnapshot) {
                if (pendingSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                }
                if (!pendingSnapshot.hasData || pendingSnapshot.data!.isEmpty) {
                  return const SizedBox();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'CURRENTLY DEVELOPING',
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
                      child: ListView.builder(
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
                      ),
                    ),
                  ],
                );
              }
            ),
            
            // Developed Rolls Section
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 8.0),
              child: Text(
                'FILM ARCHIVE',
                style: TextStyle(
                  color: Colors.orange,
                  fontFamily: 'Courier',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            FutureBuilder<List<FilmRoll>>(
              future: _storageService.getFilmRolls(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No developed film rolls yet.', style: TextStyle(color: Colors.white54, fontFamily: 'Courier')),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final roll = snapshot.data![index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFF1B1B1B),
                        child: roll.previewPhoto != null
                            ? Image.file(roll.previewPhoto!, fit: BoxFit.cover, cacheWidth: 200)
                            : const Icon(Icons.broken_image, color: Colors.white54),
                      ),
                      title: Text(roll.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text('${roll.photos.length} photos • ${roll.date.month}/${roll.date.day}/${roll.date.year}', 
                        style: const TextStyle(color: Colors.white54, fontFamily: 'Courier', fontSize: 12)
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                            onPressed: () => _renameRoll(roll),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white54, size: 20),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Film Roll?'),
                                  content: Text('Are you sure you want to permanently delete "${roll.name}" and all of its photos?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _storageService.deleteFilmRoll(roll.id);
                                        if (context.mounted) {
                                          setState(() {});
                                        }
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white54),
                        ],
                      ),
                      onTap: () async {
                        final bool? changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RollDetailsScreen(roll: roll),
                          ),
                        );
                        if (changed == true && context.mounted) {
                          setState(() {});
                        }
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Photo',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Photo?'),
                  content: const Text('Are you sure you want to permanently delete this photo?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog
                        final storage = StorageService();
                        await storage.deletePhoto(imageFile);
                        if (context.mounted) {
                          Navigator.pop(context, true); // Pop screen, return true for refresh
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
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
