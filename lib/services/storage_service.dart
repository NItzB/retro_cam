import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/film_roll.dart';

class StorageService {
  Future<String> saveImage(XFile imageFile, {bool isMagicSquare = false}) async {
    final directory = await getApplicationDocumentsDirectory();
    // We might want a 'pending' folder for undeveloped photos
    final String pendingDir = '${directory.path}/pending_development';

    await Directory(pendingDir).create(recursive: true);

    // Create a masked filename with filter metadata flag
    final String filterFlag = isMagicSquare ? '_MS_' : '_NO_';
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String filename = 'temp_img${filterFlag}$timestamp.jpg'; 
    final String filePath = path.join(pendingDir, filename);

    // Move the file
    await File(imageFile.path).copy(filePath);
    return filePath;
  }

  Future<String> _getUniqueRollName(String baseName, {String? ignoreRollId}) async {
    final List<FilmRoll> existingRolls = await getFilmRolls();
    
    bool nameExists(String name) {
      return existingRolls.any((roll) => roll.name == name && roll.id != ignoreRollId);
    }

    if (!nameExists(baseName)) return baseName;

    int counter = 1;
    String newName = '$baseName ($counter)';
    while (nameExists(newName)) {
      counter++;
      newName = '$baseName ($counter)';
    }
    return newName;
  }

  Future<void> developPhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final String pendingDir = '${directory.path}/pending_development';
    
    final pendingDirObj = Directory(pendingDir);
    if (!await pendingDirObj.exists()) return;
    
    final List<FileSystemEntity> files = pendingDirObj.listSync();
    if (files.isEmpty) return; // Nothing to develop

    // Generate new roll ID
    final String rollId = const Uuid().v4();
    final String developedDir = '${directory.path}/developed_photos/$rollId';
    await Directory(developedDir).create(recursive: true);

    // Default name based on date, ensuring uniqueness
    final date = DateTime.now();
    final String baseName = "Roll ${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
    final String uniqueName = await _getUniqueRollName(baseName);

    final metaFile = File(path.join(developedDir, 'metadata.json'));
    await metaFile.writeAsString(jsonEncode({
      'name': uniqueName,
      'date': date.toIso8601String(),
    }));

    for (final file in files) {
      if (file is File) {
        final filename = path.basename(file.path);
        final newPath = path.join(developedDir, filename);
        await file.copy(newPath);
        await file.delete();
      }
    }
  }
  Future<List<File>> getPendingPhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<File> photos = [];
    final String pendingDir = '${directory.path}/pending_development';
    final pendingDirObj = Directory(pendingDir);

    if (!await pendingDirObj.exists()) {
      return [];
    }

    await for (var entity in pendingDirObj.list()) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        if (entity.path.split('/').last.startsWith('temp_img')) {
          photos.add(entity);
        }
      }
    }

    // Sort chronologically (oldest first as they were taken)
    photos.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    return photos;
  }

  Future<List<FilmRoll>> getFilmRolls() async {
    final directory = await getApplicationDocumentsDirectory();
    final String developedDir = '${directory.path}/developed_photos';
    final developedDirObj = Directory(developedDir);

    if (!await developedDirObj.exists()) {
      return [];
    }

    // 1. Auto-migrate legacy loose photos into a single "Legacy Roll" directory
    final List<File> legacyPhotos = [];
    await for (var entity in developedDirObj.list()) {
      if (entity is File) {
        if (entity.path.endsWith('.dat')) {
          final newPath = entity.path.replaceAll('.dat', '.jpg');
          final renamed = await entity.rename(newPath);
          legacyPhotos.add(renamed);
        } else if (entity.path.endsWith('.jpg')) {
          legacyPhotos.add(entity);
        }
      }
    }

    if (legacyPhotos.isNotEmpty) {
      final legacyRollId = const Uuid().v4();
      final legacyDir = Directory(path.join(developedDir, legacyRollId));
      await legacyDir.create();
      
      for (var file in legacyPhotos) {
         final newPath = path.join(legacyDir.path, path.basename(file.path));
         await file.rename(newPath);
      }
      
      final metaFile = File(path.join(legacyDir.path, 'metadata.json'));
      await metaFile.writeAsString(jsonEncode({
         'name': 'Legacy Roll',
         'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      }));
    }

    // 2. Parse all subdirectories as Film Rolls
    final List<FilmRoll> rolls = [];

    await for (var entity in developedDirObj.list()) {
      if (entity is Directory) {
        final rollId = path.basename(entity.path);
        final metaFile = File(path.join(entity.path, 'metadata.json'));
        
        String name = 'Unknown Roll';
        DateTime date = DateTime.now();
        
        if (await metaFile.exists()) {
          try {
            final jsonStr = await metaFile.readAsString();
            final Map<String, dynamic> data = jsonDecode(jsonStr);
            name = data['name'] ?? name;
            if (data['date'] != null) {
              date = DateTime.parse(data['date']);
            }
          } catch (_) {}
        }

        final List<File> photos = [];
        await for (var subEntity in entity.list()) {
           if (subEntity is File && subEntity.path.endsWith('.jpg')) {
             if (subEntity.path.split('/').last.startsWith('temp_img')) {
               photos.add(subEntity);
             }
           }
        }
        
        photos.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

        rolls.add(FilmRoll(
          id: rollId,
          name: name,
          date: date,
          photos: photos,
        ));
      }
    }

    // Sort rolls newest first
    rolls.sort((a, b) => b.date.compareTo(a.date));
    return rolls;
  }

  Future<void> renameFilmRoll(String rollId, String newName) async {
    final directory = await getApplicationDocumentsDirectory();
    final String rollDir = '${directory.path}/developed_photos/$rollId';
    final metaFile = File(path.join(rollDir, 'metadata.json'));
    
    if (await metaFile.exists()) {
      final uniqueName = await _getUniqueRollName(newName, ignoreRollId: rollId);
      final jsonStr = await metaFile.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      data['name'] = uniqueName;
      await metaFile.writeAsString(jsonEncode(data));
    }
  }

  Future<void> deleteFilmRoll(String rollId) async {
    final directory = await getApplicationDocumentsDirectory();
    final String rollDir = '${directory.path}/developed_photos/$rollId';
    final dirObj = Directory(rollDir);

    if (await dirObj.exists()) {
      await dirObj.delete(recursive: true);
    }
  }

  Future<void> deletePhoto(File photoFile) async {
    if (await photoFile.exists()) {
      await photoFile.delete();
      
      // Check if the parent roll directory is now empty
      final parentDir = photoFile.parent;
      final remainingFiles = parentDir.listSync().whereType<File>().where((f) => f.path.endsWith('.jpg')).toList();
      
      if (remainingFiles.isEmpty) {
         // Auto-delete the entire roll directory if no photos are left
         await parentDir.delete(recursive: true);
      }
    }
  }
}
